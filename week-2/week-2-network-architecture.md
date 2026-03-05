# Production VPC Architecture with Private Instances

## Overview

This project implements a production-style AWS VPC architecture designed to host web applications securely using private infrastructure.

The environment spans two Availability Zones and separates public-facing components from application servers. Internet traffic is terminated at an Application Load Balancer (ALB) located in public subnets, while the web servers themselves run inside private subnets with no public IP addresses.

To support secure operations:

- A **NAT Gateway** enables outbound internet access for package updates.
- A **VPC Gateway Endpoint** allows private access to Amazon S3 without routing traffic through the internet.
- **IAM roles** provide instance-level permissions without storing credentials on servers.
- A **bastion host** enables controlled administrative access to private instances.



---

## Network Diagram


                        Internet
                           |
                           v
               +-------- [ALB] --------+
               |    (Public Subnets)    |
               v                        v
         [Web Server 1]           [Web Server 2]
           Private-1a                Private-1b
               |                        |
               +--- [S3 VPC Endpoint] --+
                          |
                     [S3 Bucket]

         [Bastion Host]  ----SSH---->  [Web Servers]
          Public-1a                     Private Subnets



---

## Component Table - Core Infrastructure

| Resource | Purpose | Network Type |
|--------|--------|--------|
| VPC (10.0.0.0/16) | Isolated network environment | Private |
| Public Subnet 1a (10.0.1.0/24) | Hosts ALB and Bastion in AZ-a | Public |
| Public Subnet 1b (10.0.2.0/24) | Hosts ALB in AZ-b | Public |
| Private Subnet 1a (10.0.3.0/24) | Web Server in AZ-a | Private |
| Private Subnet 1b (10.0.4.0/24) | Web Server in AZ-b | Private |
| Internet Gateway | Provides internet connectivity for public resources | Public |
| NAT Gateway | Allows private instances to access the internet outbound | Public |
| Public Route Table | Routes 0.0.0.0/0 to Internet Gateway | Public |
| Private Route Table | Routes 0.0.0.0/0 to NAT Gateway | Private |
| ALB Security Group | Allows HTTP traffic from the internet | Public |
| Web Server Security Group | Allows HTTP from ALB and SSH from Bastion | Private |
| Bastion Security Group | Allows SSH access from the internet | Public |
| CloudBase-Prod-ALB | Distributes traffic across web servers | Public |
| CloudBase-Prod-TG | Target group for backend instances | Private |
| Web Server 1 | Apache server in Private Subnet 1a | Private |
| Web Server 2 | Apache server in Private Subnet 1b | Private |
| Bastion Host | Administrative access point to private instances | Public |
| S3 Gateway Endpoint | Private connectivity to Amazon S3 | Private |
| IAM Instance Profile | Grants S3 read-only access to instances | N/A |

---

## Security Model

### Traffic Flow

**Internet → ALB**

Users access the application through the public DNS endpoint of the Application Load Balancer over HTTP.

**ALB → Web Servers**

The ALB forwards requests to backend instances using private IP addresses within the VPC.

**Web Servers → S3**

Instances access S3 through a VPC Gateway Endpoint. This keeps traffic inside the AWS network and avoids internet routing.

**Admin Access**

Administrators connect to the **bastion host via SSH**, then connect to private instances from there.

---

### Security Controls

The architecture enforces several access restrictions:

- Web servers **do not have public IP addresses**
- Private subnets **do not route directly to the Internet Gateway**
- SSH access to web servers is **only possible via the bastion host**
- Outbound internet access from private instances is **restricted to the NAT Gateway**
- S3 access is **limited to a specific bucket using IAM policies**

This approach significantly reduces the exposed attack surface.

---

## Cost Analysis and Considerations

### Free Tier Eligible

- VPC components (subnets, route tables, internet gateway)
- S3 Gateway Endpoint (no hourly charge)
- t3.micro EC2 instances (750 hours/month)

### Paid Components

| Resource | Approx Cost |
|--------|--------|
| NAT Gateway | ~$0.045/hour (~$32/month) |
| Elastic IP (unused) | ~$0.005/hour |
| Application Load Balancer | ~$0.02/hour |

### Cost Optimization Strategies - How I minimized cost

- Deleted NAT Gateway when not needed.
- Released unused Elastic IPs.
- Stopped instances during non-working hours.
- Used `t3.micro` all through practice.
- Planned to use smaller instances such as `t4g.nano` if the free tier is exceeded.
- Minimized NAT Gateway use times by deleting immediately after practice.
- Monitor NAT Gateway data processing charges

---

## Testing and Verification

### Target Group Health

+----------------------+-----------+
| Instance ID | Status |
+----------------------+-----------+
| i-0190df6b8283103fa | healthy |
| i-0482e538aa8bf7c31 | healthy |
+----------------------+-----------+


Both backend instances successfully passed ALB health checks.

---

### Load Balancing Test
Request 1 → Private-1b (10.0.4.0/24)
Request 2 → Private-1a (10.0.3.0/24)
Request 3 → Private-1b (10.0.4.0/24)
Request 4 → Private-1a (10.0.3.0/24)


The ALB correctly distributed traffic across both Availability Zones.

---

### Private S3 Access Test
aws s3 ls s3://dev-artifacts-217777498144 --region us-east-1

2026-02-24 00:14:54 24 test-artifact.txt


The private web server successfully accessed S3 **without requiring internet or NAT routing**.

---

### Web Server Verification

curl http://localhost

<h1>CloudBase Production</h1> <p>Subnet: Private-1a (10.0.3.0/24)</p> 

```
Apache served the application successfully from the private instance.

```

# Lessons Learned

Building and testing this architecture reinforced several important networking and troubleshooting principles within AWS environments.

## Systematic Network Debugging

When connectivity issues occur, troubleshooting is most effective when done in a structured order. The following sequence proved reliable:

1. **Route Tables** – Verify the subnet has a valid route to the destination (Internet Gateway, NAT Gateway, or internal network).
2. **Security Groups** – Confirm the required port is allowed inbound on the target instance.
3. **Network ACLs** – Ensure the subnet allows both inbound and outbound traffic, including ephemeral ports.
4. **Instance Firewall** – Check the operating system firewall if all AWS-level networking appears correct.

Starting from the network edge and moving inward helps isolate problems quickly.

## Common Connectivity Failure Patterns

During testing, several connection issues appeared repeatedly:

| Symptom | Likely Cause |
|--------|--------|
| SSH connection times out | Missing inbound port 22 in Security Group or NACL rules |
| SSH hangs (cursor blinking) | NACL allows inbound but blocks outbound ephemeral ports |
| SSH rejected (connection refused) | SSH service not running on the instance |
| SSH permission denied | Incorrect SSH key or wrong default username |
| Ping fails but SSH works | ICMP not allowed in Security Group or NACL |
| All connectivity fails | Route table misconfiguration |

Recognizing these patterns significantly reduces troubleshooting time in real environments.

## Network ACL Behavior

One key takeaway is that **Network ACLs are stateless**. This means:

- Inbound rules must allow the incoming traffic.
- Outbound rules must allow the response traffic.

For SSH, this includes allowing **ephemeral ports (1024–65535)** for return traffic.

## Instance Type Compatibility

While launching instances, the `t2.micro` instance type was unavailable in the selected environment. Switching to `t3.micro` resolved the issue. This highlights the importance of checking **instance generation availability per region or account limits** when provisioning infrastructure.

## Key Takeaway

Most connectivity issues in AWS environments are caused by **network configuration rather than instance-level problems**. Following a structured debugging process and understanding how routing, security groups, and NACLs interact makes diagnosing these issues much faster.



# Architecture Outcomes

The deployment confirmed the expected behavior of the architecture:

Private web servers operate without public IP addresses

The ALB provides controlled public access to the application

NAT Gateway enables necessary outbound internet connectivity

S3 Gateway Endpoint allows private S3 communication

IAM roles eliminate the need for static access keys

Bastion host enables controlled administrative access

This architecture reflects a common production pattern for securely hosting applications in AWS while maintaining separation between public and private resources.


