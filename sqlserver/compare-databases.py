#!/usr/bin/env python3
"""
Azure SQL Database Comparison Tool

Compares two databases and shows exactly what objects are different,
including missing tables, procedures, functions, indexes, etc.

Requirements:
    pip install pyodbc azure-identity

Usage:
    python compare-databases.py \
        --server "myserver.database.windows.net" \
        --source-db "source-database" \
        --target-db "target-database"
"""

import argparse
import sys
import struct
import pyodbc
from azure.identity import AzureCliCredential
from collections import defaultdict

# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    GRAY = '\033[0;37m'
    BOLD = '\033[1m'
    NC = '\033[0m'

def print_header(message):
    print(f"{Colors.CYAN}{Colors.BOLD}{message}{Colors.NC}")

def print_success(message):
    print(f"{Colors.GREEN}{message}{Colors.NC}")

def print_error(message):
    print(f"{Colors.RED}{message}{Colors.NC}")

def print_warning(message):
    print(f"{Colors.YELLOW}{message}{Colors.NC}")

def print_info(message):
    print(f"{Colors.GRAY}{message}{Colors.NC}")

def get_azure_sql_token():
    """Get Azure AD access token for SQL Database."""
    try:
        credential = AzureCliCredential()
        token = credential.get_token("https://database.windows.net/.default")
        return token.token
    except Exception as e:
        print_error(f"Failed to get Azure AD token: {e}")
        return None

def create_connection(server, database):
    """Create a connection to Azure SQL Database using Azure AD token."""
    try:
        token = get_azure_sql_token()
        if not token:
            return None
        
        token_bytes = token.encode('utf-16-le')
        token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
        
        connection_string = (
            f"DRIVER={{ODBC Driver 18 for SQL Server}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"Encrypt=yes;"
            f"TrustServerCertificate=no;"
        )
        
        conn = pyodbc.connect(connection_string, attrs_before={1256: token_struct})
        return conn
    except Exception as e:
        print_error(f"Failed to connect to {database}: {e}")
        return None

def get_tables(cursor):
    """Get list of all tables."""
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall()]

def get_views(cursor):
    """Get list of all views."""
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.VIEWS
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall()]

def get_procedures(cursor):
    """Get list of all stored procedures."""
    cursor.execute("""
        SELECT ROUTINE_SCHEMA, ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'PROCEDURE'
        ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall()]

def get_functions(cursor):
    """Get list of all functions."""
    cursor.execute("""
        SELECT ROUTINE_SCHEMA, ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'FUNCTION'
        ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall()]

def get_indexes(cursor):
    """Get list of all indexes with their tables."""
    cursor.execute("""
        SELECT 
            s.name AS SchemaName,
            t.name AS TableName,
            i.name AS IndexName,
            i.type_desc AS IndexType,
            i.is_unique,
            i.is_primary_key
        FROM sys.indexes i
        INNER JOIN sys.tables t ON i.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE i.type > 0  -- Exclude heaps
        ORDER BY s.name, t.name, i.name
    """)
    return [(row[0], row[1], row[2], row[3], row[4], row[5]) for row in cursor.fetchall()]

def get_constraints(cursor):
    """Get list of all constraints."""
    cursor.execute("""
        SELECT 
            tc.TABLE_SCHEMA,
            tc.TABLE_NAME,
            tc.CONSTRAINT_NAME,
            tc.CONSTRAINT_TYPE
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
        ORDER BY tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME
    """)
    return [(row[0], row[1], row[2], row[3]) for row in cursor.fetchall()]

def get_table_columns(cursor, schema, table):
    """Get columns for a specific table."""
    cursor.execute("""
        SELECT 
            COLUMN_NAME,
            DATA_TYPE,
            CHARACTER_MAXIMUM_LENGTH,
            IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    """, schema, table)
    return [(row[0], row[1], row[2], row[3]) for row in cursor.fetchall()]

def compare_lists(source_list, target_list, item_name):
    """Compare two lists and return differences."""
    source_set = set(source_list)
    target_set = set(target_list)
    
    missing_in_target = source_set - target_set
    extra_in_target = target_set - source_set
    
    return missing_in_target, extra_in_target

def compare_databases(server, source_db, target_db):
    """Compare two databases and show differences."""
    
    print()
    print_header("=" * 80)
    print_header("Azure SQL Database Comparison")
    print_header("=" * 80)
    print()
    
    print_info(f"Server: {server}")
    print_info(f"Source Database: {source_db}")
    print_info(f"Target Database: {target_db}")
    print()
    
    # Connect to source database
    print_info("Connecting to source database...")
    source_conn = create_connection(server, source_db)
    if not source_conn:
        print_error("Failed to connect to source database")
        return False
    print_success("✓ Connected to source database")
    
    # Connect to target database
    print_info("Connecting to target database...")
    target_conn = create_connection(server, target_db)
    if not target_conn:
        print_error("Failed to connect to target database")
        source_conn.close()
        return False
    print_success("✓ Connected to target database")
    print()
    
    source_cursor = source_conn.cursor()
    target_cursor = target_conn.cursor()
    
    differences_found = False
    
    # Compare Tables
    print_header("[1/6] Comparing Tables...")
    source_tables = get_tables(source_cursor)
    target_tables = get_tables(target_cursor)
    missing_tables, extra_tables = compare_lists(source_tables, target_tables, "table")
    
    if missing_tables or extra_tables:
        differences_found = True
        if missing_tables:
            print_error(f"  ✗ {len(missing_tables)} table(s) missing in target:")
            for schema, table in sorted(missing_tables):
                print_error(f"      - {schema}.{table}")
        if extra_tables:
            print_warning(f"  ⚠ {len(extra_tables)} extra table(s) in target:")
            for schema, table in sorted(extra_tables):
                print_warning(f"      + {schema}.{table}")
    else:
        print_success(f"  ✓ All {len(source_tables)} tables match")
    print()
    
    # Compare Views
    print_header("[2/6] Comparing Views...")
    source_views = get_views(source_cursor)
    target_views = get_views(target_cursor)
    missing_views, extra_views = compare_lists(source_views, target_views, "view")
    
    if missing_views or extra_views:
        differences_found = True
        if missing_views:
            print_error(f"  ✗ {len(missing_views)} view(s) missing in target:")
            for schema, view in sorted(missing_views):
                print_error(f"      - {schema}.{view}")
        if extra_views:
            print_warning(f"  ⚠ {len(extra_views)} extra view(s) in target:")
            for schema, view in sorted(extra_views):
                print_warning(f"      + {schema}.{view}")
    else:
        print_success(f"  ✓ All {len(source_views)} views match")
    print()
    
    # Compare Stored Procedures
    print_header("[3/6] Comparing Stored Procedures...")
    source_procs = get_procedures(source_cursor)
    target_procs = get_procedures(target_cursor)
    missing_procs, extra_procs = compare_lists(source_procs, target_procs, "procedure")
    
    if missing_procs or extra_procs:
        differences_found = True
        if missing_procs:
            print_error(f"  ✗ {len(missing_procs)} procedure(s) missing in target:")
            for schema, proc in sorted(missing_procs):
                print_error(f"      - {schema}.{proc}")
        if extra_procs:
            print_warning(f"  ⚠ {len(extra_procs)} extra procedure(s) in target:")
            for schema, proc in sorted(extra_procs):
                print_warning(f"      + {schema}.{proc}")
    else:
        print_success(f"  ✓ All {len(source_procs)} procedures match")
    print()
    
    # Compare Functions
    print_header("[4/6] Comparing Functions...")
    source_funcs = get_functions(source_cursor)
    target_funcs = get_functions(target_cursor)
    missing_funcs, extra_funcs = compare_lists(source_funcs, target_funcs, "function")
    
    if missing_funcs or extra_funcs:
        differences_found = True
        if missing_funcs:
            print_error(f"  ✗ {len(missing_funcs)} function(s) missing in target:")
            for schema, func in sorted(missing_funcs):
                print_error(f"      - {schema}.{func}")
        if extra_funcs:
            print_warning(f"  ⚠ {len(extra_funcs)} extra function(s) in target:")
            for schema, func in sorted(extra_funcs):
                print_warning(f"      + {schema}.{func}")
    else:
        print_success(f"  ✓ All {len(source_funcs)} functions match")
    print()
    
    # Compare Indexes
    print_header("[5/6] Comparing Indexes...")
    source_indexes = get_indexes(source_cursor)
    target_indexes = get_indexes(target_cursor)
    
    # Create comparable tuples (schema, table, index_name)
    source_idx_set = set([(idx[0], idx[1], idx[2]) for idx in source_indexes])
    target_idx_set = set([(idx[0], idx[1], idx[2]) for idx in target_indexes])
    
    missing_indexes = source_idx_set - target_idx_set
    extra_indexes = target_idx_set - source_idx_set
    
    if missing_indexes or extra_indexes:
        differences_found = True
        if missing_indexes:
            print_error(f"  ✗ {len(missing_indexes)} index(es) missing in target:")
            for schema, table, idx_name in sorted(missing_indexes):
                # Find details from source
                details = [idx for idx in source_indexes if idx[0] == schema and idx[1] == table and idx[2] == idx_name]
                if details:
                    idx_type = details[0][3]
                    is_unique = details[0][4]
                    is_pk = details[0][5]
                    flags = []
                    if is_pk:
                        flags.append("PRIMARY KEY")
                    if is_unique:
                        flags.append("UNIQUE")
                    flag_str = f" ({', '.join(flags)})" if flags else ""
                    print_error(f"      - {schema}.{table}.{idx_name} [{idx_type}]{flag_str}")
        if extra_indexes:
            print_warning(f"  ⚠ {len(extra_indexes)} extra index(es) in target:")
            for schema, table, idx_name in sorted(extra_indexes):
                print_warning(f"      + {schema}.{table}.{idx_name}")
    else:
        print_success(f"  ✓ All {len(source_indexes)} indexes match")
    print()
    
    # Compare Constraints
    print_header("[6/6] Comparing Constraints...")
    source_constraints = get_constraints(source_cursor)
    target_constraints = get_constraints(target_cursor)
    
    # Create comparable tuples
    source_const_set = set([(c[0], c[1], c[2], c[3]) for c in source_constraints])
    target_const_set = set([(c[0], c[1], c[2], c[3]) for c in target_constraints])
    
    missing_constraints = source_const_set - target_const_set
    extra_constraints = target_const_set - source_const_set
    
    if missing_constraints or extra_constraints:
        differences_found = True
        if missing_constraints:
            print_error(f"  ✗ {len(missing_constraints)} constraint(s) missing in target:")
            # Group by type
            by_type = defaultdict(list)
            for schema, table, const_name, const_type in sorted(missing_constraints):
                by_type[const_type].append((schema, table, const_name))
            
            for const_type, items in sorted(by_type.items()):
                print_error(f"      {const_type}:")
                for schema, table, const_name in items:
                    print_error(f"        - {schema}.{table}.{const_name}")
        
        if extra_constraints:
            print_warning(f"  ⚠ {len(extra_constraints)} extra constraint(s) in target:")
            for schema, table, const_name, const_type in sorted(extra_constraints):
                print_warning(f"      + {schema}.{table}.{const_name} [{const_type}]")
    else:
        print_success(f"  ✓ All {len(source_constraints)} constraints match")
    print()
    
    # Close connections
    source_cursor.close()
    target_cursor.close()
    source_conn.close()
    target_conn.close()
    
    # Summary
    print_header("=" * 80)
    print_header("COMPARISON SUMMARY")
    print_header("=" * 80)
    print()
    
    if differences_found:
        print_error("✗ DIFFERENCES FOUND")
        print()
        print_info("Summary of missing objects in target:")
        if missing_tables:
            print_error(f"  - Tables: {len(missing_tables)}")
        if missing_views:
            print_error(f"  - Views: {len(missing_views)}")
        if missing_procs:
            print_error(f"  - Stored Procedures: {len(missing_procs)}")
        if missing_funcs:
            print_error(f"  - Functions: {len(missing_funcs)}")
        if missing_indexes:
            print_error(f"  - Indexes: {len(missing_indexes)}")
        if missing_constraints:
            print_error(f"  - Constraints: {len(missing_constraints)}")
        print()
        print_header("=" * 80)
        print_error("Target database is NOT identical to source!")
        print_header("=" * 80)
        return False
    else:
        print_success("✓ DATABASES ARE IDENTICAL")
        print()
        print_success("All objects match between source and target databases!")
        print()
        print_header("=" * 80)
        return True

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Compare two Azure SQL Databases",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Compare source and restored database
  python compare-databases.py \\
    --server "myserver.database.windows.net" \\
    --source-db "production-db" \\
    --target-db "restored-db"

Prerequisites:
  - Azure CLI (logged in via 'az login')
  - pip install pyodbc azure-identity
  - ODBC Driver 18 for SQL Server
"""
    )
    
    parser.add_argument("--server", required=True, help="SQL Server FQDN")
    parser.add_argument("--source-db", required=True, help="Source database name")
    parser.add_argument("--target-db", required=True, help="Target database name")
    
    args = parser.parse_args()
    
    # Run comparison
    success = compare_databases(args.server, args.source_db, args.target_db)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

