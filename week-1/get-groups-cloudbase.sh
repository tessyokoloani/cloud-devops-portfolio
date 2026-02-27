for group in CloudBase-Developers CloudBase-QA CloudBase-DevOps CloudBase-Finance; do
    echo "=== $group ==="
    echo "Users:"
    aws iam get-group --group-name $group --profile personal --query 'Users[*].UserName' --output text
    echo "Policies:"
    aws iam list-attached-group-policies --group-name $group --profile personal --query 'AttachedPolicies[*].PolicyName' --output text
    echo ""
done
