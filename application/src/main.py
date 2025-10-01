from fastapi import FastAPI, HTTPException
from mangum import Mangum

app = FastAPI()

@app.post("/events")
async def create_event(event: dict):
    if "id" not in event or "type" not in event or "payload" not in event:
        raise HTTPException(status_code=400, detail="Missing fields in event")
    return {"message": "Event created", "event": event}

# Lambda handler
handler = Mangum(app)