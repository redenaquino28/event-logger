# Use official Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy dependency file and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY src .

# Expose FastAPI port
EXPOSE 8000

# Run with uvicorn
CMD ["uvicorn", "event-logger-api:app", "--host", "0.0.0.0", "--port", "8000"]