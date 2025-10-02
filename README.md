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

## CI/CD

### Lint and Terraform Validation
- Every push to any branch except main branch triggers a workflow that runs tflint and validation to terraform modules
<br>

### Build, Publish, Deploy and Test
1. Build
- builds a docker image which consolidates all the required libraries, the application source code<br>
```docker build -t $IMAGE_NAME:$IMAGE_TAG -f application/Dockerfile .```
2. Publish
- Pushes the docker image created to the ECR Repository<br>
```docker tag $IMAGE_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG```<br>
```docker push $ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/$IMAGE_NAME:$IMAGE_TAG```
3. Deploy
- Applies terraform module for Lambda function to update Lambda function with the new docker image
4. Test
- Post deployment tests to create and retrieve an event. Run Lambda Invocation to test the API application

** It uses the Git Commit Short SHA as Docker Image tag and Event ID for testing **

<br>
<br>

## How to test manually
```Pre-requisite: Make sure you have right access to invoke the Lambda function
How to create event?
1. Create JSON file containing the following example (Creating Event)
post_event.json 
          {
            "version": "2.0",
            "routeKey": "POST /events",
            "rawPath": "/events",
            "rawQueryString": "",
            "headers": {},
            "queryStringParameters": null,
            "requestContext": {
              "http": {
                "method": "POST",
                "path": "/events",
                "protocol": "HTTP/1.1",
                "sourceIp": "127.0.0.1",
                "userAgent": "GitHubActions"
              }
            },
            "body": "{\"id\":\"$EVENT_ID\",\"type\":\"test\",\"payload\":{\"foo\":\"bar\"}}",
            "isBase64Encoded": false
          }

2. Run the following commands which will convert the payload to base64 format, and invole the Lambda Function
cat post_event.json | base64 > post_event.b64
aws lambda invoke --function-name sin-dev-event-logger-api --payload file://post_event.b64 response_post.json
cat response_post.json


How to retrieve event?
1. Create JSON file containing the following example (Retrieving Event)
get_event.json
          {
            "version": "2.0",
            "routeKey": "GET /events/$EVENT_ID",
            "rawPath": "/events/$EVENT_ID",
            "rawQueryString": "",
            "headers": {},
            "queryStringParameters": null,
            "requestContext": {
              "http": {
                "method": "GET",
                "path": "/events/$EVENT_ID",
                "protocol": "HTTP/1.1",
                "sourceIp": "127.0.0.1",
                "userAgent": "GitHubActions"
              }
            },
            "body": null,
            "isBase64Encoded": false
          }

2. Run the following commands which will convert the payload to base64 format, and invole the Lambda Function
cat get_event.json | base64 > get_event.b64 
aws lambda invoke --function-name sin-dev-event-logger-api --payload file://get_event.b64 response_get.json
cat response_get.json
```
<br>
--- 

<br>

### If I have more time:
- I would create more tests especially for python scripts
- I would simplify the terraform more
- I would make the IAM policies more restrictive

<br>

### What coulbe next steps?
- For high-availability, multiple replica of application servers could be created with load balancer on top.
- API gateway is also a good improvement for a more secured connection
- It could alse be deployed in a Kubernetes cluster for auto-scaling
- More simple code for terraform and should be reusable for other environment

<br>

### What could be done before production-ready?
- There should be an authentication when creating or retrieving events
- Data retention of events should be considered
- Client-facing endpoint with WAF and/or API gateway

