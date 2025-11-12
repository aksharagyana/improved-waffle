# Provisioning Secure Azure Event Grid

## Synopsis

Azure **Event Grid** is a fully managed event routing service that enables reliable, scalable, and near real-time delivery of event notifications. It allows applications and services to react to events from Azure resources or custom sources without complex polling or manual integration.

This document outlines how Event Grid will be **securely provisioned** in an enterprise environment:

* Provisioned with **Private Endpoints** to ensure all traffic flows through the corporate VNet and not the public internet.
* Access controlled using a custom RBAC role **`werf-operator`** with least-privilege permissions to provision and manage Event Grid resources.
* Data is protected **in transit** via TLS 1.2+ and **at rest** via Microsoft-managed keys.
* **Ingress and egress traffic** are strictly controlled via NSGs, service tags, and firewall/proxy rules limited to port 443/TCP.
* **DNS resolution** is handled via Azure Private DNS Zones to ensure private name resolution.
* **Monitoring and diagnostics** are enabled for auditing, troubleshooting, and compliance.

---

## Overview

This document describes a secure, enterprise-ready process to provision Azure Event Grid with **Private Endpoints**, and the minimum permissions required via a custom role **`werf-operator`**. It also recommends encryption, TLS usage, NSG rules, ingress/egress port requirements, and corporate network changes required to support private connectivity to Event Grid while preserving least-privilege access.

**Intended audience:** Cloud platform engineers, Azure AD / IAM administrators, Network/Security teams, and platform operators.

**References:**

* Azure troubleshooting & network connectivity guide: [https://learn.microsoft.com/en-us/azure/event-grid/troubleshoot-network-connectivity](https://learn.microsoft.com/en-us/azure/event-grid/troubleshoot-network-connectivity)

---

## Goals

* Provision Event Grid Topics / Domains with private connectivity (Private Endpoints).
* Use a custom role `werf-operator` that has the minimum permissions required to create and manage Event Grid topics and domains.
* Ensure encryption in transit (TLS 1.2+) and at rest (Microsoft-managed keys).
* Ensure private DNS and NSG rules allow secure, auditable communication between producers/consumers and Event Grid.
* Provide example CLI / Terraform snippets to accelerate implementation.

---

## Architecture (logical)

1. **Resource Group** containing Event Grid Domain / Topic and Private Endpoint.
2. **Private Endpoint** for Event Grid attached into a secured subnet in the corporate VNet.
3. **Private DNS Zone** (privatelink.eventgrid.azure.net) linked to the VNet so that Event Grid service FQDN resolves to the PE IP.
4. **NSG / Firewall** controlling inbound/outbound traffic for the subnet that hosts the private endpoint.
5. **Encryption**: All communications to Event Grid require TLS 1.2 or above. Event Grid data at rest is automatically encrypted using Microsoft-managed keys.
6. **Identity & Access**: A custom RBAC role `werf-operator` assigned to the operator/service principal that provisions topics.

---

## Encryption & TLS

* **In transit:** Event Grid requires TLS 1.2+ for all HTTPS communications. TLS 1.0/1.1 are blocked.
* **At rest:** All data within Event Grid is automatically encrypted using **Microsoft-managed keys**. Customer-managed keys (CMK) are **not supported**.
* **Validation:** Ensure applications consuming Event Grid endpoints validate TLS certificates correctly.

---

## Ingress & Egress (Networking)

### Ingress (to Event Grid)

* Ingress traffic flows from your producers to Event Grid over **TCP 443 (HTTPS)**.
* When using private endpoints, ingress traffic terminates at the private IP in your subnet.
* Ensure only trusted subnets or application VNets can send ingress traffic to the Event Grid PE IP.

### Egress (from Event Grid)

* Event Grid delivers events to subscribers (webhooks, storage queues, event hubs, functions, etc.) via **TCP 443**.
* If your subscriber endpoint is behind a firewall or NSG, ensure inbound HTTPS is allowed from the Event Grid service.
* Use **service tags** (e.g., `EventGrid`) where available to simplify rule maintenance.

### Port summary

* **443/TCP** — Required for both ingress (publishers → Event Grid) and egress (Event Grid → subscribers).
* No other ports are required.

---

## Custom Role: `werf-operator`

Create a custom role that gives permissions necessary to provision Event Grid domains / topics and manage them.

### Role definition (JSON example)

```json
{
  "Name": "werf-operator",
  "IsCustom": true,
  "Description": "Operator role to provision and manage Event Grid domains and topics (create/read/write/delete).",
  "Actions": [
    "Microsoft.EventGrid/domains/*",
    "Microsoft.EventGrid/topics/*",
    "Microsoft.EventGrid/systemTopics/*",
    "Microsoft.EventGrid/eventSubscriptions/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Network/privateEndpoints/*",
    "Microsoft.Network/privateDnsZones/*",
    "Microsoft.Authorization/roleAssignments/read",
    "Microsoft.Insights/*/read"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/<SUBSCRIPTION_ID>"]
}
```

---

## NSG & Corporate Network Recommendations

Below are recommended controls to maintain a secure posture while enabling Event Grid private connectivity.

### 1) Subnet hosting Private Endpoint (PE)

* **Deny** inbound traffic from Internet to PE subnet.
* **Allow** inbound traffic only from trusted application subnets / IP ranges over **TCP 443**.
* **Outbound**: Restrict outbound to required Azure service FQDNs over **TCP 443**.

Recommended NSG rules (example):

* Allow: Source = AppSubnet (or specific application IPs), Destination = PE subnet, Protocol = TCP, Destination Port = 443, Priority = 100
* Deny: Source = Internet, Destination = PE subnet, Protocol = Any, Priority = 4096
* Allow: Source = PE subnet, Destination = Azure management/service tags (e.g., `AzureResourceManager`, `EventGrid`, `AzureCloud`), Protocol = TCP, Port = 443, Priority = 2000

### 2) Corporate firewall / Proxy changes

* Whitelist the following over **HTTPS (443)**:

  * `*.eventgrid.azure.net` (or `privatelink.eventgrid.azure.net` for private DNS)
  * `management.azure.com`
  * `login.microsoftonline.com` (for Azure AD auth)
  * `*.core.windows.net` (if Event Grid integrates with Storage)

---

## Troubleshooting tips (network connectivity)

* Validate **TLS version** with tools such as `openssl s_client -connect <FQDN>:443` (must negotiate TLS 1.2+).
* Run `nslookup` from inside the VNet to confirm FQDN resolves to private IP.
* Confirm only port **443/TCP** is open in NSG/firewall.
* Check Event Grid PE connection status and diagnostic logs if events are not delivered.

---

## Operational & Security Best Practices

* **Enforce TLS 1.2+** across clients and integrations.
* **Restrict ingress** to PE IPs from only trusted subnets.
* **Restrict egress** to required FQDNs over port 443.
* **Audit** TLS connections and Event Grid diagnostics via Log Analytics.

---

## Appendix — Quick checklist for Network Team

1. Approve subnet/NSG for PE with ingress limited to **443/TCP** from trusted sources.
2. Ensure egress on **443/TCP** to `*.eventgrid.azure.net`, `management.azure.com`, and Azure AD endpoints.
3. Validate TLS 1.2+ enforcement.
4. Confirm Event Grid encryption at rest is enabled (Microsoft-managed keys by default).

---

## Change Log

* **v1.0** — Initial draft covering role definition, PE, DNS, NSG guidance and CLI/Terraform examples.
* **v1.1** — Added encryption (TLS/at rest), ingress/egress ports, and extended NSG/firewall recommendations.
* **v1.2** — Clarified that Event Grid at rest encryption uses Microsoft-managed keys only; CMK not supported.
* **v1.3** — Added synopsis to explain what Event Grid is and how it will be securely provisioned.

---
