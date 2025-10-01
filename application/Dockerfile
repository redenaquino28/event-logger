FROM public.ecr.aws/lambda/python:3.11

# Copy dependencies and install
COPY application/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY application/src /var/task

# Set Lambda handler (module_name.handler)
CMD ["main.handler"]