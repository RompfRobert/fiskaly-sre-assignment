FROM python:3.12-slim

# Disable .pyc writes to avoid issues with read-only root filesystems.
ENV PYTHONDONTWRITEBYTECODE=1

# Match Kubernetes runAsUser/runAsGroup with an explicit non-root identity.
RUN groupadd -r appuser --gid 10001 && useradd -r -g appuser -u 10001 appuser

WORKDIR /app
COPY app/app.py /app/app.py

USER 10001:10001

EXPOSE 8080

CMD ["python", "app.py"]
