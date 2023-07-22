FROM python:3.11-alpine
LABEL org.opencontainers.image.source=https://github.com/AkibaAT/itchbot-docker
LABEL org.opencontainers.image.description="Python 3.11 for ItchBot"
LABEL org.opencontainers.image.licenses=MIT
COPY requirements.txt /app/requirements.txt
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a=rx /docker-entrypoint.sh \
    && apk add \
      py3-pip \
    && addgroup -S app && adduser -S app -G app \
    && chown -R app:app /app \
    && pip install -r /app/requirements.txt
RUN chown -R app:app /app
USER app
WORKDIR /app
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80
