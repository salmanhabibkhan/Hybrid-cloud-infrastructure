flowchart LR
  subgraph OnPrem[Simulated On-Prem (us-east-1)]
    OPVPC[OnPrem VPC 10.1.0.0/16]
    OPPub[Public Subnet]
    OPServer[EC2 (MySQL Host / App)]
    OPPub --- OPServer
  end

  subgraph Cloud[AWS Cloud (us-west-1)]
    VPC[VPC 10.0.0.0/16]
    PubA[Public Subnet A]
    PubB[Public Subnet B]
    PrivA[Private Subnet A]
    PrivB[Private Subnet B]
    IGW[Internet Gateway]
    NATa[NAT GW A]
    NATb[NAT GW B]
    ALB[Internet-facing ALB]
    ASG[Auto Scaling Group (Desired=2)]
    App1[EC2 App A]
    App2[EC2 App B]
    S3[S3 Artifact Bucket]
    CD[CodeDeploy App + DG]

    VPC --- IGW
    VPC --- PubA & PubB
    VPC --- PrivA & PrivB
    PubA --- NATa
    PubB --- NATb
    PubA --- ALB
    PubB --- ALB
    PrivA --- App1
    PrivB --- App2
    ASG -.-> App1
    ASG -.-> App2
    ALB -->|HTTP:80| App1
    ALB -->|HTTP:80| App2
    CD <-->|Deploys Artifacts| S3
    CD -->|In-place| ASG
  end

  OPServer <-.- DX[Direct Connect / VPN (conceptual)] -.-> VPC