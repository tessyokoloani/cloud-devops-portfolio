#!/bin/bash

# Display a header for the inventory report
echo "=============================="
echo "AWS Account Inventory Report"
echo "=============================="
echo ""

# ==========================================
# EC2 INSTANCES SECTION
# ==========================================
echo "--- EC2 Instances ---"

aws ec2 describe-instances \
    --profile personal
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' \
    --output table

echo ""
echo "--- S3 Buckets ---"

# ==========================================
# S3 BUCKETS SECTION
# ==========================================

aws s3api list-buckets \
    --profile personal
    --query 'Buckets[*].[Name, Owner.ID]' \
    --output table

echo ""
echo "--- IAM Users ---"

# ==========================================
# IAM USERS SECTION
# ==========================================

aws iam list-users \
    --profile personal
    --query 'Users[].[UserName,UserId,CreateDate]' \
    --output table

echo ""
echo "--- VPCs ---"

# ==========================================
# VPCS SECTION
# ==========================================

aws ec2 describe-vpcs \
    --profile personal
    --query 'Vpcs[*].[VpcId,OwnerId,CidrBlock,IsDefault,Tags]' \
    --output table

echo ""
echo "Report complete."
