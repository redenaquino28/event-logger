# event-logger
Serverless Event Logger Exercise using AWS Lambda and Python
<br><br>


Event Logger is an API application made by Python. The goal is to create an API exposing 2 endpoints:
1. /events -> creates an event in DynamoDB
2. /events/{id} -> retrieves an event based on "id"

Event Shape only needs to have an "id"
Example:
{
  "id": "string",
  "type": "string",
  "payload": "payload"
}
where "id" is client supplied. "payload" can be any valid JSON object.

<br>

---
### Highlights
1. Containerized application
2. Used Terraform for provisioning
3. Github Worklflows
   <br>a. Build, Publish, Deploy and Post-deployment Test
   <br>b. Lint and Terraform Validation

<br>

---

### Prepare the Base Environment and Access
1. Create initial requirement to run terraform
   <br>a. Create S3 Bucket manually and name it "event-logger-terraform-state" for the tfstate files.
   <br>b. Create DynamoDB manually and name it "event-logger-terraform-state-locks" for the tfstate locks.

2. Configure your AWS credentials to run initial setup

3. Run support/scripts/provision-init.sh
   <br>a. It creates and updates Provisioner IAM Role for running terraform
   <br>b. It creates and updates Github OIDC IAM Role for running terraform and deployment
   <br>c. It creates and updates the policy needed by Provisioner IAM Role and Github OIDC IAM Role
   <br>d. It creates OIDC type Identity Provider in IAM

4. Navigate to terraform/env/dev and run terraform apply to create the base environment
  <br>a. It provisions the DynamoDB where the events will be stored
  <br>b. It provisions ECR repository where docker image for application API will be stored along with the policies


<br>

## Terraform

<br>

### We have 2 terraform modules
1. env -> Base environment which consists of DynamoDB, ECR Repository and policies
2. lambda -> The end product where application will be hosted and run

<br>

### Why separate Lambda Module to base environment?
- DynamoDB and ECR hold valuable assets and data which are critical in terms loss or downtime. It's better to have them in a separate module so as to prevent a breaking change.
- Lambda Function holds the application. Every change in the application source code, it must be updated. 
- Lambda Function requires some values that need to be created first in Base environment module.

<br>

### CI/CD

### Lint and Terraform Validation
- Every push to any branch except main branch triggers a workflow that runs tflint and validation to terraform modules
<br>

### Build, Publish, Deploy and Test
1. Build -> Builds a docker image which consolidates all the required libraries, the application source code
```docker build -t $IMAGE_NAME:$IMAGE_TAG -f application/Dockerfile .
2. Publish -> Pushes the docker image created to the ECR Repository
``` docker tag $IMAGE_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG
``` docker push $ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG
3. Deploy -> Applies terraform module for Lambda function
4. Test -> Post deployment tests to create and retrieve an event

** It uses the Git Cimmit Short SHA as Docker Image tag and Event ID for testing **


### Future Considerations
