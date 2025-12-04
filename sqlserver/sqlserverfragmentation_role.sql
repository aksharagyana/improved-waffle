
-- Sql server using Entra auth, user connect with there credentials and apps with UMI. 
-- Identity must be provided with below permissions customer is just an example database
-- creation of user and permissions must be provied for all databases as in below table
-- Database   Create user?  Grant permissions? 
-- master       ✔ Yes          ✖ No 
-- customer     ✔ Yes          ✔ Yes 

USE master; 

GO 
-- Create the UAMI user at the server level (Azure SQL equivalent of CREATE LOGIN) 

IF NOT EXISTS ( 
    SELECT 1 FROM sys.database_principals WHERE name = N'umi-dev-db' 
) 

BEGIN 
    CREATE USER [umi-dev-db] FROM EXTERNAL PROVIDER; 
END 

GO 

-- Verification in master PRINT '--- Verification: User in master ---';
SELECT name, type_desc FROM sys.database_principals WHERE name = N'umi-dev-db';  

GO 


----------------------------- on each database customer is an example -------------

USE [customers]; 
GO

-- Create the UAMI user at the server level (Azure SQL equivalent of CREATE LOGIN) 

IF NOT EXISTS ( 
    SELECT 1 FROM sys.database_principals WHERE name = N'umi-dev-db' 
) 

BEGIN 
    CREATE USER [umi-dev-db] FROM EXTERNAL PROVIDER; 
END 

GO 

-- Verification in master PRINT '--- Verification: User in master ---';
SELECT name, type_desc FROM sys.database_principals WHERE name = N'umi-dev-db';  

GO 

-- Create the UAMI user inside the database 

GRANT VIEW DEFINITION TO [umi-dev-db]; 
GRANT ALTER ON DATABASE::[compass] TO [umi-dev-db]; 
GRANT ALTER ON DATABASE::[compass] TO [umi-dev-db];  
GRANT SELECT ON DATABASE::[compass] TO [umi-dev-db];  
GRANT CONTROL ON DATABASE::[compass] TO [umi-dev-db]; 

-- Run in compass database 

DECLARE @sql NVARCHAR(MAX) = N''; 

SELECT @sql = @sql + 'GRANT ALTER ON SCHEMA::' + QUOTENAME(name) + 
               ' TO [umi-dev-db];' + CHAR(13) 
FROM sys.schemas 

WHERE name NOT IN ('sys', 'INFORMATION_SCHEMA', 'guest', 'db_owner', 'db_accessadmin', 'db_securityadmin', 'db_ddladmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter'); 

-- Execute the dynamic SQL 

PRINT @sql; 
EXEC sp_executesql @sql; 

--DECLARE @sql NVARCHAR(MAX) = N''; 

 SELECT @sql = @sql + 'GRANT ALTER ON OBJECT::'  
       + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) 
       + ' TO [umi-dev-db];' + CHAR(13) 
FROM sys.tables t 
JOIN sys.schemas s ON t.schema_id = s.schema_id; 


EXEC sp_executesql @sql; 
