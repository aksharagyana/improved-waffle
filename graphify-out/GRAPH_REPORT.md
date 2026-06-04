# Graph Report - improved-waffle  (2026-06-04)

## Corpus Check
- 20 files · ~23,658 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 495 nodes · 561 edges · 31 communities (30 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `521eeff6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]

## God Nodes (most connected - your core abstractions)
1. `Redis Cluster Client Application` - 18 edges
2. `run_integrity_checks()` - 17 edges
3. `compare_databases()` - 16 edges
4. `compare_databases()` - 15 edges
5. `Azure Private DNS Zone Terraform Module` - 14 edges
6. `print_info()` - 13 edges
7. `Provisioning Secure Azure Event Grid` - 13 edges
8. `print_success()` - 12 edges
9. `Azure Database for PostgreSQL - Flexible Server Terraform Module` - 12 edges
10. `Azure Storage Account Terraform Module` - 12 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (31 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (45): **Callback URL Security:**, code:block1 (Azure AD → Callback URL → OAuth Proxy Container), code:bash (# If you have a public domain), code:bash (# Deploy OAuth proxy to cloud (Azure, AWS, etc.)), code:bash (# Test from your machine), code:bash (# View OAuth proxy logs), code:bash (# Visit OAuth proxy), code:bash (# OAuth proxy configuration) (+37 more)

### Community 1 - "Community 1"
Cohesion: 0.13
Nodes (34): check_constraints(), check_data_accessibility(), check_database_accessibility(), check_database_health(), check_database_size(), check_indexes(), check_schema_objects(), check_table_details() (+26 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (32): Advanced Usage with Multiple Node Pools, AKS Cluster Naming Convention, Azure Kubernetes Service (AKS) Terraform Module, Basic Usage, Breaking Changes, code:hcl (# For AKS private cluster), code:hcl (module "aks_cluster" {), code:hcl (module "aks_cluster" {) (+24 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (31): Advanced Usage, Azure Private DNS Zone Terraform Module, Basic Usage, code:hcl (module "private_dns_zones" {), code:hcl (module "private_dns_zones" {), code:hcl (module "private_dns_zone" {), code:hcl (module "dev_private_dns_zone" {), code:hcl (module "prod_private_dns_zone" {) (+23 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (31): Advanced Usage with High Availability, Azure Database for PostgreSQL - Flexible Server Terraform Module, Basic Usage, Breaking Changes, code:hcl (# For PostgreSQL Flexible Server), code:hcl (module "postgresql_server" {), code:hcl (module "postgresql_server" {), code:block4 (psql-{location_short}-{project_short}-{app_short}-{suffix}) (+23 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (31): 1. terraform-validation.yml, 2. terraform-registry-publish.yml, Advanced Setup, Basic Setup, code:yaml (stages:), code:yaml (stages:), code:block3 (<type>[optional scope]: <description>), code:bash (# Major version bump) (+23 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (30): Advanced Usage with Custom Configuration, Azure Storage Account Terraform Module, Basic Usage, Breaking Changes, code:hcl (module "storage_account" {), code:hcl (module "storage_account" {), code:block3 (st{location_short}{project_short}{app_short}{suffix}), code:hcl (# For blob storage private endpoints) (+22 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (30): Advanced Usage with Multiple Endpoints, Azure Private DNS Resolver Terraform Module, Basic Usage, Breaking Changes, code:hcl (module "private_dns_resolver" {), code:hcl (module "private_dns_resolver" {), code:hcl (module "private_dns_resolver" {), code:block4 (dns-{location_short}-{project_short}-{app_short}-{suffix}) (+22 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (29): Colors, compare_databases(), compare_lists(), create_connection(), get_azure_sql_token(), get_constraints(), get_functions(), get_indexes() (+21 more)

### Community 9 - "Community 9"
Cohesion: 0.13
Nodes (25): Colors, compare_databases(), compare_lists(), create_connection(), get_azure_sql_token(), get_functions(), get_procedures(), get_table_row_counts() (+17 more)

### Community 10 - "Community 10"
Cohesion: 0.1
Nodes (20): 1) Subnet hosting Private Endpoint (PE), 2) Corporate firewall / Proxy changes, Appendix — Quick checklist for Network Team, Architecture (logical), Change Log, code:json ({), Custom Role: `werf-operator`, Egress (from Event Grid) (+12 more)

### Community 11 - "Community 11"
Cohesion: 0.15
Nodes (13): code:bash (# Build and deploy), code:yaml (securityContext:), code:yaml (resources:), code:yaml (env:), Deployment Options, Environment Variables, 🚀 Kubernetes Deployment, Option 1: Deployment (Long-running) (+5 more)

### Community 12 - "Community 12"
Cohesion: 0.15
Nodes (12): Azure Key Vault Module, code:hcl (module "key_vault" {), Features, Inputs, Naming Convention, Outputs, Prerequisites, Providers (+4 more)

### Community 13 - "Community 13"
Cohesion: 0.17
Nodes (11): Azure Container Registry Module, code:hcl (module "acr" {), Features, Inputs, Naming Convention, Outputs, Prerequisites, Providers (+3 more)

### Community 14 - "Community 14"
Cohesion: 0.17
Nodes (11): Advanced Usage with Delegation, Azure Subnet Module, Basic Usage, code:hcl (module "subnet" {), code:hcl (module "subnet" {), Features, Inputs, Outputs (+3 more)

### Community 15 - "Community 15"
Cohesion: 0.18
Nodes (11): code:bash (brew install ngrok), code:bash (./run-oauth-proxy.sh), code:bash (ngrok http 4180), code:bash (# Use the ngrok URL as callback), code:bash (# Visit ngrok URL), 📋 **Quick Setup for Testing**, **Step 1: Install ngrok**, **Step 2: Start OAuth proxy** (+3 more)

### Community 16 - "Community 16"
Cohesion: 0.18
Nodes (11): 1. Environment Setup, 2. Run with Docker Compose, 3. Run with Direct Docker, 4. Local Development, 5. Kubernetes Deployment, code:bash (# Set environment variables), code:bash (# Build and run), code:bash (# Build image) (+3 more)

### Community 17 - "Community 17"
Cohesion: 0.33
Nodes (9): cluster, Redis, startOperations(), startupNodes, testBasicOperations(), testClusterInfo(), testDataTypes(), testHashSlotDistribution() (+1 more)

### Community 18 - "Community 18"
Cohesion: 0.2
Nodes (9): 🏗️ Architecture, code:block1 (┌─────────────────┐    ┌──────────────────┐), code:block10 (🚀 Connecting to Redis Cluster...), 🚀 Features, 📄 License, 📋 Prerequisites, Redis Cluster Client Application, 🔗 Related Resources (+1 more)

### Community 19 - "Community 19"
Cohesion: 0.22
Nodes (9): code:bash (# Test basic connectivity), code:bash (# Check network policies), code:bash (# This is normal - client should handle automatically), code:bash (# Check cluster quorum), code:bash (# Enable debug logging), Common Errors, Connection Issues, Debug Mode (+1 more)

### Community 20 - "Community 20"
Cohesion: 0.29
Nodes (7): code:bash (# 1. Ensure Redis Cluster is running), code:bash (# Delete a master pod to trigger failover), code:bash (# For local Redis testing), Test Failover Scenario, Test Local Redis, Test with Your Redis Cluster, 🧪 Testing Scenarios

### Community 21 - "Community 21"
Cohesion: 0.33
Nodes (6): Build Commands, Build Stages, code:dockerfile (# Stage 1: Builder), code:bash (# Build optimized image), 🐳 Docker Multi-Stage Build, Image Optimization

### Community 22 - "Community 22"
Cohesion: 0.33
Nodes (6): 📚 Advanced Usage, code:javascript (// Add custom operations to app.js), code:javascript (// Add Prometheus metrics), Custom Operations, Monitoring Integration, Scaling Considerations

### Community 23 - "Community 23"
Cohesion: 0.33
Nodes (6): 1. Basic Read/Write Operations, 2. Hash Slot Distribution, 3. Data Types Operations, 4. Cluster Information, 5. Performance Testing, 📊 Operations Demonstrated

### Community 24 - "Community 24"
Cohesion: 0.4
Nodes (5): Code Structure, code:block25 (redis-cluster-client/), code:bash (# 1. Clone and install), 🤝 Contributing, Development Workflow

### Community 25 - "Community 25"
Cohesion: 0.5
Nodes (4): code:block7 (# Single node), 🔧 Configuration, Environment Variables, Host Format

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (4): Batch Operations, Connection Pooling, Memory Management, 📊 Performance Considerations

### Community 27 - "Community 27"
Cohesion: 0.67
Nodes (3): Best Practices, Container Security, 🔒 Security

## Knowledge Gaps
- **268 isolated node(s):** `Redis`, `startupNodes`, `Colors`, `Print a cyan header message.`, `Print a green success message.` (+263 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Redis Cluster Client Application` connect `Community 18` to `Community 11`, `Community 16`, `Community 19`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 25`, `Community 26`, `Community 27`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `OAuth Callback URL Explained` connect `Community 0` to `Community 15`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `🚀 Kubernetes Deployment` connect `Community 11` to `Community 18`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `Redis`, `startupNodes`, `Colors` to the rest of the system?**
  _268 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._