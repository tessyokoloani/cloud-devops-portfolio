# CloudBase IAM Project - AWS Account Architecture

## 📋 Project Overview

This project demonstrates enterprise-grade AWS IAM configuration for a fictional company called "CloudBase." It implements least-privilege access controls, group-based permissions, shared guardrails, and cost protection mechanisms—all while maintaining zero running costs through disciplined resource management.

## 🏗️ Architecture Design

### AWS Account Structure

- **Account ID:** 217777498144
- **Primary Region:** us-east-1 (for billing metrics)
- **Resource State:** Zero running costs maintained throughout

### IAM Hierarchy

```text
AWS Account (217777498144)
├── IAM Groups (4)
│   ├── CloudBase-Developers
│   ├── CloudBase-QA
│   ├── CloudBase-DevOps
│   └── CloudBase-Finance
├── IAM Users (5)
│   ├── cb-alice (Developer)
│   ├── cb-bob (DevOps)
│   ├── cb-charlie (QA)
│   ├── cb-diana (Finance)
│   └── terraform-intern (Infrastructure)
├── IAM Roles (1)
│   └── EC2-S3-ReadOnly (for EC2 instances)
└── IAM Policies (7 custom + inherited)
```

## 📁 Policy Files

### Core Policies

| Policy File | Description | Permissions |
|---|---|---|
| JuniorDevPolicy.json | Entry-level developer access | Limited EC2, read-only S3 on dev bucket |
| SeniorDevPolicy.json | Full developer access | Full EC2, full S3 on dev bucket, read-only IAM |
| CloudBase-DeveloperPolicy.json | Developer team policy | EC2 management, S3 read/write on dev resources |
| CloudBase-QAPolicy.json | QA team policy | Read-only EC2, read-only S3 for testing |
| CloudBase-DevOpsPolicy.json | DevOps team policy | Full EC2, full S3, IAM read, limited IAM write |
| CloudBase-FinancePolicy.json | Finance team policy | Read-only EC2, read-only S3 (cost reporting only) |
| CloudBase-NoBucketDelete.json | Shared Guardrail | Explicitly denies s3:DeleteBucket to ALL users |

### Key Policy Example: SeniorDevPolicy.json

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::dev-artifacts-217777498144",
                "arn:aws:s3:::dev-artifacts-217777498144/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:List*",
                "iam:Get*"
            ],
            "Resource": "*"
        }
    ]
}
```

### Guardrail Policy: NoBucketDelete.json

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Action": "s3:DeleteBucket",
            "Resource": "*"
        }
    ]
}
```

## 👥 User and Group Structure

### Groups and Members

| Group Name | Members | Primary Responsibilities |
|---|---|---|
| CloudBase-Developers | cb-alice | Application development, EC2 instance management, dev deployment |
| CloudBase-DevOps | cb-bob | Infrastructure automation, CI/CD, cross-team coordination |
| CloudBase-QA | cb-charlie | Testing, validation, staging environment access |
| CloudBase-Finance | cb-diana | Cost reporting, budget monitoring, read-only access |

### User Details

| Username | Group Membership | Purpose |
|---|---|---|
| terraform-intern | (Direct user) | Infrastructure provisioning via Terraform |
| cb-alice | CloudBase-Developers | Application developer |
| cb-bob | CloudBase-DevOps | DevOps engineer |
| cb-charlie | CloudBase-QA | QA tester |
| cb-diana | CloudBase-Finance | Finance team |

## 🔧 Implementation Details

### Key Learnings Applied

- **Never use root account** - All operations performed via IAM users/roles
- **Least-privilege principle** - Each group gets only necessary permissions
- **Named profiles** - Multiple AWS profiles for different contexts
- **Tag everything** - Resources tagged for cost tracking
- **Regular cleanup** - Zero running costs maintained throughout

### Guardrail Pattern: Shared Policy Architecture

Instead of embedding `s3:DeleteBucket` deny into every team policy, we created one standalone policy (CloudBase-NoBucketDelete) and attached it to all groups. This provides:

- **Centralized management** - Update one policy instead of four
- **Consistent enforcement** - Same rule applies everywhere
- **Break-glass procedure** - Documented process for temporary removal when needed

### Role-Based Access: EC2-S3-ReadOnly

Created an IAM role for EC2 instances that provides temporary credentials via STS:

- **Trust policy:** Allows EC2 service to assume the role
- **Permissions:** Read-only access to S3 buckets
- **Instance profile:** Enables keyless access from EC2

## 🧪 Testing Results

### Test Cases Performed

| Test | Expected Result | Actual Result | Status |
|---|---|---|---|
| Developer creates EC2 instance | ✅ Allow | EC2 instance launched | ✅ PASS |
| Developer deletes S3 bucket | ❌ Deny | Access denied by guardrail | ✅ PASS |
| DevOps views IAM users | ✅ Allow | User list visible | ✅ PASS |
| QA modifies EC2 instance | ❌ Deny | Access denied | ✅ PASS |
| Finance views cost data | ✅ Allow | Billing dashboard accessible | ✅ PASS |

### Debugging Experience

- **Issue:** Policy had wrong bucket ARN format (included region/account)
- **Diagnosis:** Used `aws iam get-policy-version` to compare versions
- **Resolution:** Corrected ARN to `arn:aws:s3:::dev-artifacts-217777498144`

## 💰 Cost Protection Implementation

### Three-Layer Defense

**1. CloudWatch Alarm ($5 threshold)**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name MonthlySpendingAlarm \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --region us-east-1
```

**2. AWS Budget ($10 limit)**

- Fixed budget with email alerts at 80% and 100%
- Per-service breakdown enabled

**3. Anomaly Detection**

- ML-based monitoring of spending patterns
- Default services monitor configured

## 📊 Current Account State

| Resource Type | Count | Details |
|---|---|---|
| EC2 Instances | 0 | All terminated after testing |
| S3 Buckets | 1 | dev-artifacts-217777498144 |
| IAM Users | 5 | Groups: 4, Direct: 1 |
| IAM Groups | 4 | Developers, QA, DevOps, Finance |
| IAM Policies | 7 | 6 team policies + 1 guardrail |
| IAM Roles | 1 | EC2-S3-ReadOnly |
| Instance Profiles | 1 | EC2-S3-ReadOnly-Profile |
| Budgets | 1 | $10 monthly limit |
| CloudWatch Alarms | 1 | $5 spending alert |
| Anomaly Monitors | 1 | Service-level monitoring |
| VPCs | 1 | Default VPC only (non-production) |
| **Running Costs** | **$0** | **All resources cleaned up** |

## 🚀 How to Deploy

### Prerequisites

- AWS CLI installed and configured
- Appropriate IAM permissions
- `jq` for JSON parsing (optional)

### Steps to Recreate

**1. Clone the repository**

```bash
git clone https://github.com/yourusername/cloud-devops-portfolio.git
cd cloud-devops-portfolio
```

**2. Create IAM policies**

```bash
# For each policy file in /policies directory
aws iam create-policy \
  --policy-name CloudBase-DeveloperPolicy \
  --policy-document file://policies/CloudBase-DeveloperPolicy.json
```

**3. Create IAM groups**

```bash
aws iam create-group --group-name CloudBase-Developers
aws iam create-group --group-name CloudBase-DevOps
aws iam create-group --group-name CloudBase-QA
aws iam create-group --group-name CloudBase-Finance
```

**4. Attach policies to groups**

```bash
aws iam attach-group-policy \
  --group-name CloudBase-Developers \
  --policy-arn arn:aws:iam::217777498144:policy/CloudBase-DeveloperPolicy
```

**5. Create users and add to groups**

```bash
aws iam create-user --user-name cb-alice
aws iam add-user-to-group --group-name CloudBase-Developers --user-name cb-alice
```

**6. Set up cost protection** (see commands above)

## 🔍 Verification Commands

### Test Policy Attachments

```bash
# List policies attached to a group
aws iam list-attached-group-policies --group-name CloudBase-Developers

# Simulate policy
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::217777498144:user/cb-alice \
  --action-names s3:DeleteBucket \
  --resource-arns arn:aws:s3:::dev-artifacts-217777498144
```

### Verify Guardrail

```bash
# This should fail (Deny)
aws s3api delete-bucket --bucket dev-artifacts-217777498144 --profile cb-alice
```

### Check Running Resources

```bash
# EC2 instances
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]'

# S3 buckets
aws s3api list-buckets --query 'Buckets[].Name'

# IAM users
aws iam list-users --query 'Users[].[UserName,CreateDate]'
```

## 📚 Interview Talking Points

| Question | Real Experience from This Project |
|---|---|
| "Tell me about a time you debugged an access issue" | Day 2: Policy had wrong bucket ARN (included region), diagnosed with get-policy-version and fixed format |
| "Tell me about a time your security controls caused an issue" | Day 4: NoBucketDelete policy blocked my own admin user; used documented break-glass procedure to temporarily remove, perform action, reattach |
| "How would you set up IAM for a new team?" | Built complete CloudBase structure: 4 groups, 5 users, least-privilege policies, shared guardrails, tested thoroughly |
| "What's the difference between users and roles?" | Proved roles work on EC2 with zero access keys using temporary STS credentials |
| "How do you manage AWS costs?" | Implemented three layers: billing alarm ($5), budget ($10 with % alerts), ML anomaly detection |

## 📝 Key Lessons Learned

- **Deny Always Wins** - Even admin users are blocked by explicit Deny statements
- **Deletion Order Matters** - Clean up dependencies before deleting resources
- **Guardrails Should Be Separate Policies** - One shared policy is cleaner than embedding rules everywhere
- **Always Test Policies** - Don't assume; test both allow and deny cases
- **Document Break-Glass Procedures** - When guardrails block legit work, have a process
- **Billing Metrics Only in us-east-1** - Alarms must be in this region
- **Tag Everything** - Essential for cost tracking and ownership

## 🎯 Project Status

- ✅ **Week 1 Complete:** IAM, CLI, and Account Architecture
- ⏭️ **Next:** Week 2 - Networking (VPC Deep Dive)

---

*This project maintains $0 running costs through disciplined resource cleanup and follows AWS best practices for enterprise IAM configuration.*
