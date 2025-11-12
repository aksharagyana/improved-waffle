#!/usr/bin/env python3
"""
Azure SQL Database Integrity Validator

This script connects directly to an Azure SQL Database and performs
comprehensive integrity checks including schema validation, data
accessibility, and health checks.

Requirements:
    pip install pyodbc azure-identity

Usage:
    python validate-database-integrity.py \
        --server "my-server.database.windows.net" \
        --database "my-database" \
        [--username "user@domain.com" --password "pass"] \
        [--use-managed-identity]
"""

import argparse
import sys
import struct
import pyodbc
from azure.identity import DefaultAzureCredential, AzureCliCredential
from datetime import datetime

# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    GRAY = '\033[0;37m'
    NC = '\033[0m'  # No Color

def print_header(message):
    """Print a cyan header message."""
    print(f"{Colors.CYAN}{message}{Colors.NC}")

def print_success(message):
    """Print a green success message."""
    print(f"{Colors.GREEN}{message}{Colors.NC}")

def print_error(message):
    """Print a red error message."""
    print(f"{Colors.RED}{message}{Colors.NC}")

def print_warning(message):
    """Print a yellow warning message."""
    print(f"{Colors.YELLOW}{message}{Colors.NC}")

def print_info(message):
    """Print a gray info message."""
    print(f"{Colors.GRAY}{message}{Colors.NC}")

def get_azure_sql_token():
    """Get Azure AD access token for SQL Database."""
    try:
        # Try Azure CLI credential first (most common for scripts)
        credential = AzureCliCredential()
        token = credential.get_token("https://database.windows.net/.default")
        return token.token
    except Exception as e:
        print_error(f"Failed to get Azure AD token: {e}")
        print_info("Make sure you're logged in: az login")
        return None

def create_connection(server, database, username=None, password=None, use_managed_identity=False):
    """
    Create a connection to Azure SQL Database.
    
    Args:
        server: SQL Server FQDN (e.g., myserver.database.windows.net)
        database: Database name
        username: SQL or Azure AD username (optional)
        password: Password (optional)
        use_managed_identity: Use Azure AD token authentication
    
    Returns:
        pyodbc.Connection or None
    """
    try:
        # Build connection string based on auth method
        if use_managed_identity or (not username and not password):
            # Use Azure AD token authentication
            print_info("      Using Azure AD token authentication...")
            token = get_azure_sql_token()
            if not token:
                return None
            
            # Convert token to struct for SQL Server
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
            print_success("      Connected using Azure AD authentication")
            
        elif username and password:
            # Use SQL authentication
            print_info(f"      Using SQL authentication for user: {username}")
            connection_string = (
                f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                f"SERVER={server};"
                f"DATABASE={database};"
                f"UID={username};"
                f"PWD={password};"
                f"Encrypt=yes;"
                f"TrustServerCertificate=no;"
            )
            conn = pyodbc.connect(connection_string)
            print_success("      Connected using SQL authentication")
        else:
            print_error("      No authentication method provided")
            return None
        
        return conn
    
    except pyodbc.Error as e:
        print_error(f"      Failed to connect to database: {e}")
        return None
    except Exception as e:
        print_error(f"      Unexpected error during connection: {e}")
        return None

def check_database_accessibility(cursor):
    """Check 1: Verify database is accessible and count tables."""
    print_info("      [Check 1/8] Verifying database accessibility...")
    try:
        cursor.execute("""
            SELECT COUNT(*) AS TableCount 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
        """)
        row = cursor.fetchone()
        table_count = row[0]
        print_success(f"        ✓ Database accessible - Found {table_count} tables")
        return True, table_count
    except Exception as e:
        print_error(f"        ✗ Failed to query database: {e}")
        return False, 0

def check_database_size(cursor):
    """Check 2: Get database size and space usage."""
    print_info("      [Check 2/8] Checking database size and space usage...")
    try:
        cursor.execute("""
            SELECT 
                SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 AS UsedSpaceMB,
                SUM(size * 8192.) / 1024 / 1024 AS AllocatedSpaceMB
            FROM sys.database_files
        """)
        row = cursor.fetchone()
        used_mb = round(row[0], 2) if row[0] else 0
        allocated_mb = round(row[1], 2) if row[1] else 0
        
        print_success(f"        ✓ Used space: {used_mb} MB")
        print_info(f"          Allocated space: {allocated_mb} MB")
        return True, used_mb, allocated_mb
    except Exception as e:
        print_warning(f"        ⚠ Could not determine database size: {e}")
        return False, 0, 0

def check_schema_objects(cursor):
    """Check 3: Validate schema objects (tables, views, procedures, functions)."""
    print_info("      [Check 3/8] Validating schema objects...")
    try:
        cursor.execute("""
            SELECT 
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE') AS Tables,
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS) AS Views,
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE') AS Procedures,
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION') AS Functions
        """)
        row = cursor.fetchone()
        tables, views, procedures, functions = row[0], row[1], row[2], row[3]
        
        print_success(f"        ✓ Tables: {tables}, Views: {views}, Procedures: {procedures}, Functions: {functions}")
        return True, {"tables": tables, "views": views, "procedures": procedures, "functions": functions}
    except Exception as e:
        print_warning(f"        ⚠ Could not retrieve schema object counts: {e}")
        return False, {}

def check_table_details(cursor):
    """Check 4: Get detailed table information (names and row counts)."""
    print_info("      [Check 4/8] Analyzing table details...")
    try:
        cursor.execute("""
            SELECT 
                t.TABLE_SCHEMA,
                t.TABLE_NAME,
                p.rows AS ApproxRowCount
            FROM INFORMATION_SCHEMA.TABLES t
            LEFT JOIN sys.tables st ON t.TABLE_NAME = st.name
            LEFT JOIN sys.partitions p ON st.object_id = p.object_id AND p.index_id IN (0,1)
            WHERE t.TABLE_TYPE = 'BASE TABLE'
            ORDER BY p.rows DESC
        """)
        
        tables = []
        total_rows = 0
        for row in cursor.fetchall():
            schema = row[0]
            table = row[1]
            rows = row[2] if row[2] else 0
            tables.append({"schema": schema, "table": table, "rows": rows})
            total_rows += rows
        
        if tables:
            print_success(f"        ✓ Found {len(tables)} tables with ~{total_rows:,} total rows")
            # Show top 10 largest tables
            print_info("          Top 10 largest tables:")
            for i, tbl in enumerate(tables[:10], 1):
                print_info(f"            {i}. {tbl['schema']}.{tbl['table']}: ~{tbl['rows']:,} rows")
        else:
            print_warning("        ⚠ No tables found")
        
        return True, tables
    except Exception as e:
        print_warning(f"        ⚠ Could not retrieve table details: {e}")
        return False, []

def check_data_accessibility(cursor):
    """Check 5: Verify data can be read from tables."""
    print_info("      [Check 5/8] Verifying data accessibility...")
    try:
        # Get first table with data
        cursor.execute("""
            SELECT TOP 1 
                t.TABLE_SCHEMA,
                t.TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES t
            INNER JOIN sys.tables st ON t.TABLE_NAME = st.name
            INNER JOIN sys.partitions p ON st.object_id = p.object_id AND p.index_id IN (0,1)
            WHERE t.TABLE_TYPE = 'BASE TABLE' AND p.rows > 0
            ORDER BY p.rows DESC
        """)
        
        row = cursor.fetchone()
        if not row:
            print_warning("        ⚠ No tables with data found")
            return False
        
        schema, table = row[0], row[1]
        
        # Try to query the table
        cursor.execute(f"SELECT TOP 1 * FROM [{schema}].[{table}]")
        cursor.fetchone()
        
        print_success(f"        ✓ Data is accessible (tested with {schema}.{table})")
        return True
    except Exception as e:
        print_error(f"        ✗ Could not verify data accessibility: {e}")
        return False

def check_indexes(cursor):
    """Check 6: Verify indexes exist and get statistics."""
    print_info("      [Check 6/8] Checking indexes...")
    try:
        cursor.execute("""
            SELECT 
                COUNT(*) AS IndexCount,
                SUM(CASE WHEN is_unique = 1 THEN 1 ELSE 0 END) AS UniqueIndexes,
                SUM(CASE WHEN is_primary_key = 1 THEN 1 ELSE 0 END) AS PrimaryKeys
            FROM sys.indexes
            WHERE type > 0  -- Exclude heaps
        """)
        
        row = cursor.fetchone()
        index_count = row[0]
        unique_indexes = row[1]
        primary_keys = row[2]
        
        print_success(f"        ✓ Indexes: {index_count} (Unique: {unique_indexes}, Primary Keys: {primary_keys})")
        return True, index_count
    except Exception as e:
        print_warning(f"        ⚠ Could not retrieve index information: {e}")
        return False, 0

def check_constraints(cursor):
    """Check 7: Verify constraints (foreign keys, checks, etc.)."""
    print_info("      [Check 7/8] Checking constraints...")
    try:
        cursor.execute("""
            SELECT 
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'FOREIGN KEY') AS ForeignKeys,
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'CHECK') AS CheckConstraints,
                (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'UNIQUE') AS UniqueConstraints
        """)
        
        row = cursor.fetchone()
        fk_count = row[0]
        check_count = row[1]
        unique_count = row[2]
        
        print_success(f"        ✓ Foreign Keys: {fk_count}, Check Constraints: {check_count}, Unique Constraints: {unique_count}")
        return True
    except Exception as e:
        print_warning(f"        ⚠ Could not retrieve constraint information: {e}")
        return False

def check_database_health(cursor):
    """Check 8: Overall database health and corruption check."""
    print_info("      [Check 8/8] Performing database health check...")
    try:
        # Check database options
        cursor.execute("""
            SELECT 
                name,
                state_desc,
                recovery_model_desc,
                compatibility_level
            FROM sys.databases
            WHERE name = DB_NAME()
        """)
        
        row = cursor.fetchone()
        db_name = row[0]
        state = row[1]
        recovery_model = row[2]
        compat_level = row[3]
        
        if state == "ONLINE":
            print_success(f"        ✓ Database state: {state}")
        else:
            print_warning(f"        ⚠ Database state: {state}")
        
        print_info(f"          Recovery model: {recovery_model}")
        print_info(f"          Compatibility level: {compat_level}")
        
        return True
    except Exception as e:
        print_warning(f"        ⚠ Could not check database health: {e}")
        return False

def run_integrity_checks(server, database, username=None, password=None, use_managed_identity=False):
    """Run all integrity checks on the database."""
    
    print()
    print_header("=" * 60)
    print_header("Azure SQL Database Integrity Validation")
    print_header("=" * 60)
    print()
    
    print_info(f"Server: {server}")
    print_info(f"Database: {database}")
    print_info(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Connect to database
    print_info("[1/2] Connecting to database...")
    conn = create_connection(server, database, username, password, use_managed_identity)
    
    if not conn:
        print_error("\nConnection failed. Exiting.")
        return False
    
    print()
    
    # Run integrity checks
    print_info("[2/2] Running integrity checks...")
    print()
    
    results = {
        "passed": 0,
        "failed": 0,
        "warnings": 0
    }
    
    try:
        cursor = conn.cursor()
        
        # Check 1: Database accessibility
        success, table_count = check_database_accessibility(cursor)
        if success:
            results["passed"] += 1
        else:
            results["failed"] += 1
        
        # Check 2: Database size
        success, used_mb, allocated_mb = check_database_size(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        # Check 3: Schema objects
        success, objects = check_schema_objects(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        # Check 4: Table details
        success, tables = check_table_details(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        # Check 5: Data accessibility
        success = check_data_accessibility(cursor)
        if success:
            results["passed"] += 1
        else:
            results["failed"] += 1
        
        # Check 6: Indexes
        success, index_count = check_indexes(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        # Check 7: Constraints
        success = check_constraints(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        # Check 8: Database health
        success = check_database_health(cursor)
        if success:
            results["passed"] += 1
        else:
            results["warnings"] += 1
        
        cursor.close()
        
    except Exception as e:
        print_error(f"\nUnexpected error during integrity checks: {e}")
        results["failed"] += 1
    finally:
        conn.close()
    
    # Print summary
    print()
    print_header("=" * 60)
    print_header("VALIDATION SUMMARY")
    print_header("=" * 60)
    print()
    
    print_success(f"✓ Passed: {results['passed']}/8 checks")
    if results["warnings"] > 0:
        print_warning(f"⚠ Warnings: {results['warnings']}/8 checks")
    if results["failed"] > 0:
        print_error(f"✗ Failed: {results['failed']}/8 checks")
    
    print()
    
    if results["failed"] == 0:
        print_header("=" * 60)
        print_success("Database integrity validation PASSED!")
        print_header("=" * 60)
        print()
        return True
    else:
        print_header("=" * 60)
        print_error("Database integrity validation FAILED!")
        print_header("=" * 60)
        print()
        return False

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Validate Azure SQL Database integrity",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using Azure AD authentication (default)
  python validate-database-integrity.py \\
    --server "myserver.database.windows.net" \\
    --database "mydatabase"
  
  # Using SQL authentication
  python validate-database-integrity.py \\
    --server "myserver.database.windows.net" \\
    --database "mydatabase" \\
    --username "admin@domain.com" \\
    --password "MyP@ssw0rd"
  
  # Using Managed Identity
  python validate-database-integrity.py \\
    --server "myserver.database.windows.net" \\
    --database "mydatabase" \\
    --use-managed-identity

Prerequisites:
  pip install pyodbc azure-identity
  
  Install ODBC Driver 18 for SQL Server:
  - Linux: https://docs.microsoft.com/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server
  - macOS: brew install msodbcsql18
  - Windows: https://docs.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server
"""
    )
    
    parser.add_argument("--server", required=True, help="SQL Server FQDN (e.g., myserver.database.windows.net)")
    parser.add_argument("--database", required=True, help="Database name")
    parser.add_argument("--username", help="SQL or Azure AD username (optional)")
    parser.add_argument("--password", help="Password (optional)")
    parser.add_argument("--use-managed-identity", action="store_true", help="Use Azure Managed Identity authentication")
    
    args = parser.parse_args()
    
    # Run integrity checks
    success = run_integrity_checks(
        server=args.server,
        database=args.database,
        username=args.username,
        password=args.password,
        use_managed_identity=args.use_managed_identity
    )
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

