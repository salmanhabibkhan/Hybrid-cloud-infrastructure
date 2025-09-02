# Direct Connect + DMS (Concept and Steps)

Follow these steps to establish private connectivity and migrate MySQL using Database Migration Service.

(A) Plan Direct Connect

Ensure non-overlapping CIDRs (VPC 10.0.0.0/16; On-Prem 10.1.0.0/16)
1) Choose the connection
- Dedicated Connection (1/10 Gbps) or Hosted Connection from a DX Partner.
- Select the nearest DX location with the required capacity.

2) Create the DX connection
- In the DX console, create a connection; download the LOA‑CFA.
- Have your colocation/carrier partner provision the cross‑connect using the LOA‑CFA.
- Optional: Create a LAG (Link Aggregation Group) for more bandwidth/HA.

3) Create a Direct Connect Gateway (DXGW)
- DXGW lets a Private VIF reach one or more VPCs (via VGW) across regions.

4) Create a Private Virtual Interface (VIF)
- Type: Private
- Attach to: DXGW
- VLAN: Unique ID (e.g., 101)
- BGP ASN (Customer): Your on‑prem ASN (e.g., 65000)
- BGP peer IPs: Use 169.254.0.0/16 link‑local /30 or /31
  - AWS peer: 169.254.100.1/30
  - Customer peer: 169.254.100.2/30
- BGP MD5 key: Recommended
- MTU: 1500 (or Jumbo if both sides support)

5) Create a Virtual Private Gateway (VGW) and attach it to VPC
- In the VPC console (us‑west‑1), create a VGW and attach it to your application VPC.

6) Associate DXGW with VGW
- In the DX console, associate the DXGW to the VGW (accept the association if prompted).

7) Routing and propagation
- On‑prem router:
  - Create a VLAN sub‑interface for the Private VIF VLAN.
  - Configure BGP to AWS with your ASN and the DX‑provided AWS ASN.
  - Advertise your on‑prem prefixes (e.g., 10.1.0.0/16).
  - Accept learned routes (e.g., 10.0.0.0/16).
  - Optional: Enable BFD for faster detection.
- In AWS (VPC route tables):
  - Enable Route Propagation from VGW on the private route tables where EC2/DMS reside.
  - You will see a propagated route for 10.1.0.0/16; no manual static route to VGW is required.

8) Security boundaries
- On‑prem firewall: Allow DMS private IP(s) to reach MySQL:3306.
- AWS Security Groups/NACLs: Permit DMS → RDS:3306, App SG → RDS:3306, and ephemeral return traffic in NACLs.

9) Validate connectivity
- Verify BGP session is “up” and routes are exchanged (DX console and router CLI).
- From a private EC2 (via SSM Session Manager):
  - nc -vz <ONPREM_MYSQL_PRIVATE_IP> 3306
  - mysql -h <ONPREM_MYSQL_PRIVATE_IP> -u <user> -p -e "select 1"

(B) RDS for MySQL (separate)
- Create RDS with the provided infra in us-west-1.
- steps to create RDS provided in README.md.
- SG: allow 3306 from App SG and from DMS replication SG during migration
- Backups and encryption enabled.

(C) DMS Replication
- Create DMS replication instance.
- Source endpoint: on-prem MySQL (private IP)
- Target endpoint: RDS endpoint (private)
- Create task: Full load + CDC
- Validate, cut over, then update db_url SSM parameter to point app to RDS

You can create DMS (DATABASE MIGRATION SERVICE) with Infra (AWS CDK Python - CloudFormation)
- Go into the Repositry Hybrid-cloud-infrastrcture
- cd database-migration-service/dms-replication-instance
- Fill all the variables in setting.py which is necessary to run infra.
- You can Read the README.md file in dms-replication-instance to install dependencies, which is necessary to run Infra.
- After Installing dependdencies. please Run the below cmds.
- cdk synth
- cdk bootstrap
- cdk deploy

Once DMS Instance is Created, Create the Replication Task and Endpoints
- Go into the Repositry Hybrid-cloud-infrastrcture
- cd database-migration-service/dms-replication-task
- Fill all the variables in setting.py which is necessary to run infra.
- You can Read the README.md file in dms-replication-task to install dependencies, which is necessary to run Infra.
- After Installing dependdencies. please Run the below cmds.
- cdk synth
- cdk bootstrap
- cdk deploy