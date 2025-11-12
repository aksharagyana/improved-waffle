#!/usr/bin/env python3
"""
Azure Key Vault Backup Script with SOPS Encryption

Backs up Azure Key Vault secrets to JSON, encrypts with SOPS,
and uploads to Azure Blob Storage.

Requirements:
    pip install azure-identity azure-keyvault-secrets azure-storage-blob
    
    SOPS must be installed:
    - macOS: brew install sops
    - Linux: https://github.com/mozilla/sops/releases
    
    Age (recommended - simplest):
    - macOS: brew install age
    - Linux: https://github.com/FiloSottile/age/releases
    
    Or GPG/PGP:
    - macOS: brew install gnupg
    - Linux: https://gnupg.org/download/

Usage:
    # First time: Generate Age key
    age-keygen -o ~/.sops-age-key.txt
    
    # Then backup
    python backup-keyvault-secrets.py \
        --vault-name "my-keyvault" \
        --storage-account "mystorageaccount" \
        --container "keyvault-backups" \
        --age-file ~/.sops-age-key.txt \
        [--backup-name "backup-2025-11-07.json"]
"""

import argparse
import json
import os
import sys
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

from azure.identity import DefaultAzureCredential, AzureCliCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient, BlobClient
from azure.core.exceptions import ResourceNotFoundError

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

def check_sops_installed():
    """Check if SOPS is installed and available."""
    try:
        result = subprocess.run(['sops', '--version'], 
                              capture_output=True, 
                              text=True, 
                              check=False)
        if result.returncode == 0:
            version = result.stdout.strip()
            return True, version
        return False, None
    except FileNotFoundError:
        return False, None

def get_azure_credential():
    """Get Azure credential, preferring Azure CLI."""
    try:
        # Try Azure CLI credential first (most common for scripts)
        credential = AzureCliCredential()
        # Test the credential
        credential.get_token("https://vault.azure.net/.default")
        return credential
    except Exception:
        # Fall back to DefaultAzureCredential (includes managed identity, etc.)
        try:
            credential = DefaultAzureCredential()
            credential.get_token("https://vault.azure.net/.default")
            return credential
        except Exception as e:
            print_error(f"Failed to acquire Azure credentials: {e}")
            print_info("Please ensure you're logged in: az login")
            return None

def list_keyvault_secrets(vault_url, credential):
    """List all secrets in the Key Vault."""
    try:
        client = SecretClient(vault_url=vault_url, credential=credential)
        secrets = []
        
        print_info("      Listing secrets...")
        for secret_properties in client.list_properties_of_secrets():
            if secret_properties.enabled:
                secrets.append({
                    'name': secret_properties.name,
                    'enabled': secret_properties.enabled,
                    'created': secret_properties.created_on.isoformat() if secret_properties.created_on else None,
                    'updated': secret_properties.updated_on.isoformat() if secret_properties.updated_on else None,
                    'content_type': secret_properties.content_type,
                    'tags': secret_properties.tags
                })
        
        return secrets
    except Exception as e:
        print_error(f"Failed to list secrets: {e}")
        return None

def get_secret_values(vault_url, credential, secret_names):
    """Get values for all secrets."""
    client = SecretClient(vault_url=vault_url, credential=credential)
    secrets_with_values = []
    
    print_info(f"      Retrieving {len(secret_names)} secret values...")
    
    for i, secret_info in enumerate(secret_names, 1):
        secret_name = secret_info['name']
        try:
            secret = client.get_secret(secret_name)
            secrets_with_values.append({
                'name': secret.name,
                'value': secret.value,
                'enabled': secret_info['enabled'],
                'created': secret_info['created'],
                'updated': secret_info['updated'],
                'content_type': secret_info['content_type'],
                'tags': secret_info['tags']
            })
            
            if i % 10 == 0:
                print_info(f"        Retrieved {i}/{len(secret_names)} secrets...")
        except Exception as e:
            print_warning(f"        Warning: Could not retrieve secret '{secret_name}': {e}")
    
    return secrets_with_values

def create_backup_json(secrets, vault_name):
    """Create backup JSON structure."""
    backup_data = {
        'backup_metadata': {
            'vault_name': vault_name,
            'backup_timestamp': datetime.utcnow().isoformat() + 'Z',
            'secret_count': len(secrets),
            'backup_version': '1.0'
        },
        'secrets': secrets
    }
    return backup_data

def encrypt_with_sops(json_file_path, sops_config):
    """Encrypt JSON file using SOPS."""
    try:
        # Build SOPS command
        cmd = ['sops', '--encrypt']
        
        # Add encryption method
        if sops_config.get('age'):
            cmd.extend(['--age', sops_config['age']])
        elif sops_config.get('pgp'):
            cmd.extend(['--pgp', sops_config['pgp']])
        else:
            print_error("No SOPS encryption method specified")
            return None
        
        # Input file
        cmd.append(str(json_file_path))
        
        # Run SOPS encryption
        print_info("      Running SOPS encryption...")
        result = subprocess.run(cmd, 
                              capture_output=True, 
                              text=True, 
                              check=False)
        
        if result.returncode != 0:
            print_error(f"SOPS encryption failed: {result.stderr}")
            return None
        
        return result.stdout  # Encrypted content
        
    except Exception as e:
        print_error(f"Failed to encrypt with SOPS: {e}")
        return None

def upload_to_blob_storage(storage_account, container, blob_name, content, credential):
    """Upload encrypted backup to Azure Blob Storage."""
    try:
        # Create blob service client
        blob_service_client = BlobServiceClient(
            account_url=f"https://{storage_account}.blob.core.windows.net",
            credential=credential
        )
        
        # Get container client
        container_client = blob_service_client.get_container_client(container)
        
        # Create container if it doesn't exist
        try:
            container_client.get_container_properties()
            print_info(f"      Container '{container}' exists")
        except ResourceNotFoundError:
            print_info(f"      Creating container '{container}'...")
            container_client.create_container()
            print_success(f"      Container created")
        
        # Upload blob
        print_info(f"      Uploading to blob: {blob_name}")
        blob_client = blob_service_client.get_blob_client(
            container=container, 
            blob=blob_name
        )
        
        blob_client.upload_blob(content, overwrite=True)
        
        blob_url = blob_client.url
        return blob_url
        
    except Exception as e:
        print_error(f"Failed to upload to blob storage: {e}")
        return None

def backup_keyvault(vault_name, storage_account, container, sops_config, backup_name=None):
    """Main backup function."""
    
    print()
    print_header("=" * 80)
    print_header("Azure Key Vault Backup with SOPS Encryption")
    print_header("=" * 80)
    print()
    
    # Generate backup name if not provided
    if not backup_name:
        timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H%M%S')
        backup_name = f"{vault_name}-backup-{timestamp}.json"
    
    print_info(f"Vault: {vault_name}")
    print_info(f"Storage Account: {storage_account}")
    print_info(f"Container: {container}")
    print_info(f"Backup Name: {backup_name}")
    print()
    
    # Check SOPS installation
    print_header("[1/6] Checking prerequisites...")
    sops_installed, sops_version = check_sops_installed()
    if not sops_installed:
        print_error("  ✗ SOPS is not installed")
        print_error("")
        print_error("Install SOPS:")
        print_error("  macOS: brew install sops")
        print_error("  Linux: https://github.com/mozilla/sops/releases")
        print_error("  Windows: https://github.com/mozilla/sops/releases")
        return False
    print_success(f"  ✓ SOPS is installed ({sops_version})")
    print()
    
    # Get Azure credentials
    print_header("[2/6] Authenticating to Azure...")
    credential = get_azure_credential()
    if not credential:
        print_error("  ✗ Failed to authenticate")
        return False
    print_success("  ✓ Authenticated to Azure")
    print()
    
    # List Key Vault secrets
    print_header("[3/6] Listing Key Vault secrets...")
    vault_url = f"https://{vault_name}.vault.azure.net"
    secrets_list = list_keyvault_secrets(vault_url, credential)
    
    if not secrets_list:
        print_error("  ✗ No secrets found or failed to list secrets")
        return False
    
    print_success(f"  ✓ Found {len(secrets_list)} enabled secrets")
    print()
    
    # Get secret values
    print_header("[4/6] Retrieving secret values...")
    secrets_with_values = get_secret_values(vault_url, credential, secrets_list)
    
    if not secrets_with_values:
        print_error("  ✗ Failed to retrieve secret values")
        return False
    
    print_success(f"  ✓ Retrieved {len(secrets_with_values)} secret values")
    print()
    
    # Create backup JSON
    print_header("[5/6] Creating and encrypting backup...")
    backup_data = create_backup_json(secrets_with_values, vault_name)
    
    # Write to temporary file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as temp_file:
        temp_path = temp_file.name
        json.dump(backup_data, temp_file, indent=2)
    
    try:
        # Encrypt with SOPS
        encrypted_content = encrypt_with_sops(temp_path, sops_config)
        
        if not encrypted_content:
            print_error("  ✗ Encryption failed")
            return False
        
        print_success(f"  ✓ Backup encrypted with SOPS")
        
        # Add .enc suffix to backup name if not already present
        if not backup_name.endswith('.enc.json'):
            if backup_name.endswith('.json'):
                encrypted_backup_name = backup_name.replace('.json', '.enc.json')
            else:
                encrypted_backup_name = backup_name + '.enc.json'
        else:
            encrypted_backup_name = backup_name
        
        print()
        
        # Upload to blob storage
        print_header("[6/6] Uploading to Azure Blob Storage...")
        blob_url = upload_to_blob_storage(
            storage_account, 
            container, 
            encrypted_backup_name, 
            encrypted_content, 
            credential
        )
        
        if not blob_url:
            print_error("  ✗ Upload failed")
            return False
        
        print_success(f"  ✓ Uploaded successfully")
        print()
        
        # Success summary
        print_header("=" * 80)
        print_header("BACKUP COMPLETED SUCCESSFULLY")
        print_header("=" * 80)
        print()
        print_success(f"✓ Vault: {vault_name}")
        print_success(f"✓ Secrets backed up: {len(secrets_with_values)}")
        print_success(f"✓ Encrypted with SOPS: Yes")
        print_success(f"✓ Blob name: {encrypted_backup_name}")
        print_success(f"✓ Container: {container}")
        print_success(f"✓ Storage account: {storage_account}")
        print()
        print_info(f"Blob URL: {blob_url}")
        print()
        
        # Show decryption command
        print_header("=" * 80)
        print_header("TO RESTORE/DECRYPT:")
        print_header("=" * 80)
        print()
        print_info("Download and decrypt:")
        print_info(f"  az storage blob download \\")
        print_info(f"    --account-name {storage_account} \\")
        print_info(f"    --container-name {container} \\")
        print_info(f"    --name {encrypted_backup_name} \\")
        print_info(f"    --file backup.enc.json --auth-mode login")
        print_info("")
        print_info(f"  sops --decrypt backup.enc.json > backup-decrypted.json")
        print()
        
        return True
        
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Backup Azure Key Vault secrets with SOPS encryption",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:

  1. Backup using Age key (recommended - simplest):
     # First, generate Age key pair (one time):
     age-keygen -o ~/.sops-age-key.txt
     
     # Then run backup:
     python backup-keyvault-secrets.py \\
       --vault-name "my-keyvault" \\
       --storage-account "mystorageaccount" \\
       --container "keyvault-backups" \\
       --age-file ~/.sops-age-key.txt

  2. Backup using Age public key directly:
     python backup-keyvault-secrets.py \\
       --vault-name "my-keyvault" \\
       --storage-account "mystorageaccount" \\
       --container "keyvault-backups" \\
       --age "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

  3. Backup using GPG/PGP key:
     # First, generate GPG key (one time):
     gpg --generate-key
     gpg --list-keys  # Get fingerprint
     
     # Then run backup:
     python backup-keyvault-secrets.py \\
       --vault-name "my-keyvault" \\
       --storage-account "mystorageaccount" \\
       --container "keyvault-backups" \\
       --pgp "ABC123DEF456789..."

  4. Custom backup name:
     python backup-keyvault-secrets.py \\
       --vault-name "my-keyvault" \\
       --storage-account "mystorageaccount" \\
       --container "keyvault-backups" \\
       --age-file ~/.sops-age-key.txt \\
       --backup-name "production-backup-2025-11-07.json"

Prerequisites:
  - Azure CLI: az login
  - pip install azure-identity azure-keyvault-secrets azure-storage-blob
  - SOPS: brew install sops (macOS) or https://github.com/mozilla/sops/releases
  - Age (recommended): brew install age OR https://github.com/FiloSottile/age/releases
  - GPG (alternative): brew install gnupg OR https://gnupg.org/download/
  - Azure permissions:
    * Key Vault: Get, List secrets
    * Storage Account: Storage Blob Data Contributor

SOPS Encryption Methods:
  - Age (--age or --age-file): RECOMMENDED - Simple, modern, no Azure dependency
  - GPG/PGP (--pgp): Traditional, widely supported

To generate Age encryption key (one time):
  age-keygen -o ~/.sops-age-key.txt
  # Save this file securely! You'll need it to decrypt backups.
  
To generate GPG key (one time):
  gpg --generate-key
  gpg --list-keys  # Get your key fingerprint
"""
    )
    
    # Required arguments
    parser.add_argument("--vault-name", required=True, 
                       help="Azure Key Vault name")
    parser.add_argument("--storage-account", required=True, 
                       help="Azure Storage Account name")
    parser.add_argument("--container", required=True, 
                       help="Blob container name")
    
    # SOPS encryption method (one required)
    sops_group = parser.add_mutually_exclusive_group(required=True)
    sops_group.add_argument("--age", 
                           help="Age public key for SOPS encryption (recommended, simplest)")
    sops_group.add_argument("--pgp", 
                           help="PGP/GPG key fingerprint for SOPS encryption")
    sops_group.add_argument("--age-file",
                           help="Path to Age private key file (for auto-loading)")
    
    # Optional arguments
    parser.add_argument("--backup-name", 
                       help="Custom backup file name (default: auto-generated with timestamp)")
    
    args = parser.parse_args()
    
    # Build SOPS config
    sops_config = {}
    if args.age:
        sops_config['age'] = args.age
    elif args.age_file:
        # Read Age public key from file
        try:
            with open(args.age_file, 'r') as f:
                for line in f:
                    if line.startswith('# public key:'):
                        sops_config['age'] = line.split(':', 1)[1].strip()
                        break
            if 'age' not in sops_config:
                print_error(f"Could not find public key in {args.age_file}")
                print_info("Expected format: # public key: age1xxx...")
                sys.exit(1)
        except Exception as e:
            print_error(f"Failed to read Age key file: {e}")
            sys.exit(1)
    elif args.pgp:
        sops_config['pgp'] = args.pgp
    
    # Run backup
    success = backup_keyvault(
        vault_name=args.vault_name,
        storage_account=args.storage_account,
        container=args.container,
        sops_config=sops_config,
        backup_name=args.backup_name
    )
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

