ARG BASE_REGISTRY=495711089104.dkr.ecr.us-east-1.amazonaws.com
FROM ${BASE_REGISTRY}/accesshub/health-aggregator:python-3.12-slim-amd64-platform

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8080
CMD ["python", "/app/app.py"]
