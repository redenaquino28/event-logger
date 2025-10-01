#!/bin/bash
set -ex

# === Config ===
PROJECT_NAME="event-logger"
ROLE_NAME="$PROJECT_NAME-provisioner-role"
GITHUB_OIDC_ROLE_NAME="$PROJECT_NAME-github-pipeline-role"
POLICY_NAME="$PROJECT_NAME-provisioner-policy"
S3_BUCKET="$PROJECT_NAME-terraform-tfstate"
DYNAMO_TABLE="$PROJECT_NAME-terraform-tfstate-locks"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-southeast-1"


if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Updating IAM Role trust policy: $ROLE_NAME"
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document file://trust-policy.json
else
  echo "Creating IAM Role: $ROLE_NAME"
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json
fi

# Create or update provisioner policy
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text)

if [ -n "$POLICY_ARN" ]; then
  echo "Updating IAM Policy: $POLICY_NAME"
  aws iam create-policy-version \
    --policy-arn "$POLICY_ARN" \
    --policy-document file://provisioner-policy.json \
    --set-as-default
else
  echo "Creating IAM Policy: $POLICY_NAME"
  POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://provisioner-policy.json \
    --query 'Policy.Arn' \
    --output text)
fi

# Check if policy already attached in provisoner role
ATTACHED=$(aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'] | length(@)" \
  --output text)

if [ "$ATTACHED" -eq 0 ]; then
  echo "Attaching Policy to Role"
  aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
else
  echo "Policy already attached to role: $ROLE_NAME"
fi

# Create OIDC provider in AWS
OIDC_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

if aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text | grep -q "$OIDC_ARN"; then
  echo "OIDC provider already exists."
else
  echo "Creating OIDC provider..."
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list a031c46782e6e6c662c2c87c76da9aa62ccabd8e
  echo "OIDC provider created."
fi

# Create IAM Role for Github OIDC
if aws iam get-role --role-name "$GITHUB_OIDC_ROLE_NAME" >/dev/null 2>&1; then
  echo "Updating IAM Role Github trust policy: $GITHUB_OIDC_ROLE_NAME"
  aws iam update-assume-role-policy \
    --role-name "$GITHUB_OIDC_ROLE_NAME" \
    --policy-document file://github-oidc-trust-policy.json
else
  echo "Creating IAM Role: $GITHUB_OIDC_ROLE_NAME"
  aws iam create-role \
    --role-name "$GITHUB_OIDC_ROLE_NAME" \
    --assume-role-policy-document file://github-oidc-trust-policy.json
fi

# Check if policy already attached in Github OIDC role
ATTACHED=$(aws iam list-attached-role-policies \
  --role-name "$GITHUB_OIDC_ROLE_NAME" \
  --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'] | length(@)" \
  --output text)

if [ "$ATTACHED" -eq 0 ]; then
  echo "Attaching Policy to Role"
  aws iam attach-role-policy \
    --role-name "$GITHUB_OIDC_ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
else
  echo "Policy already attached to role: $GITHUB_OIDC_ROLE_NAME"
fi

echo "-- DONE --"
echo "Provisioner Role: $ROLE_NAME"
echo "Github OIDC Role: $GITHUB_OIDC_ROLE_NAME"
echo "Provisioner Policy: $POLICY_ARN"