# Direct Connect + DMS (Concept and Steps)

This project does not provision RDS/DMS in Terraform. Follow these steps to establish private connectivity and migrate MySQL.

1) Plan Direct Connect
- Ensure non-overlapping CIDRs (VPC 10.0.0.0/16; On-Prem 10.1.0.0/16)
- Order a DX connection in a nearby location (production)
- Create a Direct Connect Gateway (DXGW)
- Create a Private Virtual Interface (VIF) to DXGW with your on-prem ASN/VLAN
- Create a VGW in us-west-1 and attach to your VPC
- Associate DXGW with VGW

2) Router/BGP
- Configure on-prem router: VLAN sub-interface, BGP to AWS, advertise 10.1.0.0/16
- VPC routes: add route to 10.1.0.0/16 via VGW
- Security groups/NACLs: allow DMS and/or app to reach on-prem MySQL (3306)

3) RDS for MySQL (separate)
- Create RDS in private subnet
- SG: allow 3306 from App SG and from DMS replication SG during migration
- Backups and encryption

4) DMS Replication
- Create DMS replication instance in private subnets
- Source endpoint: on-prem MySQL (private IP)
- Target endpoint: RDS endpoint (private)
- Create task: Full load + CDC
- Validate, cut over, then update db_url SSM parameter to point app to RDS

Lab Alternative: Site-to-Site VPN steps included in the README.