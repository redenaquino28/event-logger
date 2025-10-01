from fastapi import FastAPI, HTTPException
from mangum import Mangum
import boto3
import os

# DynamoDB table name from environment variable
TABLE_NAME = os.getenv("EVENT_TABLE", "sin-dev-event-logger-dynamodb")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

app = FastAPI()

@app.post("/events")
async def create_event(event: dict):
    if "id" not in event or "type" not in event or "payload" not in event:
        raise HTTPException(status_code=400, detail="Missing fields in event")
    table.put_item(Item=event)
    return {"message": "Event created", "event": event}

@app.get("/events/{event_id}")
async def get_event(event_id: str):
    resp = table.get_item(Key={"id": event_id})
    if "Item" not in resp:
        raise HTTPException(status_code=404, detail="Event not found")
    return resp["Item"]

# Lambda handler
handler = Mangum(app)