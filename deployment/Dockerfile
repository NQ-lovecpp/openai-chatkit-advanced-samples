FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_ROOT=/srv

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_ROOT}

COPY examples/cat-lounge/backend ${APP_ROOT}/cat-lounge/backend
COPY examples/customer-support/backend ${APP_ROOT}/customer-support/backend
COPY examples/metro-map/backend ${APP_ROOT}/metro-map/backend
COPY examples/news-guide/backend ${APP_ROOT}/news-guide/backend
COPY deployment/start-backends.sh /usr/local/bin/start-backends.sh

RUN pip install --upgrade pip \
    && pip install --no-cache-dir uvicorn[standard] \
    && pip install --no-cache-dir -e cat-lounge/backend \
    && pip install --no-cache-dir -e customer-support/backend \
    && pip install --no-cache-dir -e metro-map/backend \
    && pip install --no-cache-dir -e news-guide/backend

RUN chmod +x /usr/local/bin/start-backends.sh

EXPOSE 8000 8001 8002 8003

CMD ["/usr/local/bin/start-backends.sh"]
