FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# docker buildx build --platform linux/amd64 -t us-central1-docker.pkg.dev/burner-mayagarw-02/kfp/python-lib:v2 .
# docker push us-central1-docker.pkg.dev/burner-mayagarw-02/kfp/python-lib:v2
