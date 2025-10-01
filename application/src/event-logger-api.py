from fastapi import FastAPI, Request

app = FastAPI()

# healthcheck
@app.get("/api/healthcheck")
def home():
    return {"message": "TEST: It's working!"}

# create event
@app.get("/events")
def home():
    return {"message": "TEST: You have created an event"}

# retrieve
@app.get("/events/{id}")
def get_item(id: int):
    return {"id": id, "status": "retrieved", "message": "TEST: You have retrieved an event"}