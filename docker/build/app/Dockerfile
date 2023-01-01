FROM python:3.11-alpine
RUN apk add \
      git \
      py3-pip \
    && git clone --depth 1 https://gitlab.com/rejaku/itchbot.git /app \
    && cd /app \
    && pip install -r requirements.txt
WORKDIR /app
ENTRYPOINT ""
CMD ["python", "main.py"]
