FROM python:3.11-alpine
COPY ./src /app
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a=rx /docker-entrypoint.sh \
    && apk add \
      py3-pip \
    && addgroup -S app && adduser -S app -G app \
    && chown -R app:app /app \
    && pip install -r /app/requirements.txt
USER app
WORKDIR /app
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "main.py"]
EXPOSE 80
