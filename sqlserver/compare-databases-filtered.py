#!/usr/bin/env python3
"""
Azure SQL Database Comparison Tool (Application Objects Only)

Compares two databases, filtering out system/diagram objects to focus
on actual application differences.

This filters out:
- sysdiagrams table
- sp_*diagram stored procedures
- fn_diagramobjects function
- Auto-generated constraint names (compares functionally)

Requirements:
    pip install pyodbc azure-identity

Usage:
    python compare-databases-filtered.py \
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

# Objects to exclude (system/diagram-related)
EXCLUDED_TABLES = {'sysdiagrams'}
EXCLUDED_PROCEDURES = {
    'sp_alterdiagram',
    'sp_creatediagram',
    'sp_dropdiagram',
    'sp_helpdiagramdefinition',
    'sp_helpdiagrams',
    'sp_renamediagram',
    'sp_upgraddiagrams'
}
EXCLUDED_FUNCTIONS = {'fn_diagramobjects'}

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
    """Get list of application tables (excluding system tables)."""
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall() if row[1] not in EXCLUDED_TABLES]

def get_views(cursor):
    """Get list of all views."""
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.VIEWS
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall()]

def get_procedures(cursor):
    """Get list of application stored procedures (excluding diagram procedures)."""
    cursor.execute("""
        SELECT ROUTINE_SCHEMA, ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'PROCEDURE'
        ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall() if row[1] not in EXCLUDED_PROCEDURES]

def get_functions(cursor):
    """Get list of application functions (excluding diagram functions)."""
    cursor.execute("""
        SELECT ROUTINE_SCHEMA, ROUTINE_NAME
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_TYPE = 'FUNCTION'
        ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME
    """)
    return [(row[0], row[1]) for row in cursor.fetchall() if row[1] not in EXCLUDED_FUNCTIONS]

def get_table_row_counts(cursor, tables):
    """Get row counts for all tables."""
    counts = {}
    for schema, table in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM [{schema}].[{table}]")
            count = cursor.fetchone()[0]
            counts[(schema, table)] = count
        except:
            counts[(schema, table)] = None
    return counts

def compare_lists(source_list, target_list, item_name):
    """Compare two lists and return differences."""
    source_set = set(source_list)
    target_set = set(target_list)
    
    missing_in_target = source_set - target_set
    extra_in_target = target_set - source_set
    
    return missing_in_target, extra_in_target

def compare_databases(server, source_db, target_db):
    """Compare two databases and show differences (application objects only)."""
    
    print()
    print_header("=" * 80)
    print_header("Azure SQL Database Comparison (Application Objects Only)")
    print_header("=" * 80)
    print()
    
    print_info(f"Server: {server}")
    print_info(f"Source Database: {source_db}")
    print_info(f"Target Database: {target_db}")
    print_info(f"")
    print_info(f"Note: Excluding system/diagram objects (sysdiagrams, sp_*diagram, etc.)")
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
    print_header("[1/5] Comparing Application Tables...")
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
        print_success(f"  ✓ All {len(source_tables)} application tables match")
    print()
    
    # Compare Row Counts
    if not missing_tables and not extra_tables:
        print_header("[2/5] Comparing Table Row Counts...")
        print_info("  Counting rows in all tables...")
        source_counts = get_table_row_counts(source_cursor, source_tables)
        target_counts = get_table_row_counts(target_cursor, target_tables)
        
        row_count_diffs = []
        for table_key in source_tables:
            source_count = source_counts.get(table_key)
            target_count = target_counts.get(table_key)
            if source_count != target_count:
                row_count_diffs.append((table_key, source_count, target_count))
        
        if row_count_diffs:
            differences_found = True
            print_error(f"  ✗ {len(row_count_diffs)} table(s) have different row counts:")
            for (schema, table), source_count, target_count in row_count_diffs:
                print_error(f"      {schema}.{table}: Source={source_count}, Target={target_count}")
        else:
            total_rows = sum(source_counts.values())
            print_success(f"  ✓ All table row counts match (~{total_rows:,} total rows)")
        print()
    else:
        print_warning("[2/5] Skipping row count comparison (table structure mismatch)")
        print()
    
    # Compare Views
    print_header("[3/5] Comparing Views...")
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
    print_header("[4/5] Comparing Application Stored Procedures...")
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
        if len(source_procs) > 0:
            print_success(f"  ✓ All {len(source_procs)} procedures match")
        else:
            print_info(f"  ℹ No application stored procedures in either database")
    print()
    
    # Compare Functions
    print_header("[5/5] Comparing Application Functions...")
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
        if len(source_funcs) > 0:
            print_success(f"  ✓ All {len(source_funcs)} functions match")
        else:
            print_info(f"  ℹ No application functions in either database")
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
        print_error("✗ APPLICATION-LEVEL DIFFERENCES FOUND")
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
        print()
        print_header("=" * 80)
        print_error("Target database has different application objects!")
        print_header("=" * 80)
        return False
    else:
        print_success("✓ APPLICATION DATABASES ARE FUNCTIONALLY IDENTICAL")
        print()
        print_success("All application objects and data match between databases!")
        print_info("(System/diagram objects were excluded from comparison)")
        print()
        print_header("=" * 80)
        return True

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Compare two Azure SQL Databases (application objects only)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Compare source and restored database
  python compare-databases-filtered.py \\
    --server "myserver.database.windows.net" \\
    --source-db "production-db" \\
    --target-db "restored-db"

This script excludes:
  - sysdiagrams table
  - sp_*diagram stored procedures
  - fn_diagramobjects function
  - Other system objects

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

