# Dockerfiles.dockerfile
FROM ubuntu:22.04

WORKDIR /app
COPY linux_cli.sh .


RUN apt-get update && apt-get install -y dos2unix bash \
 && dos2unix /app/linux_cli.sh \
 && chmod +x /app/linux_cli.sh \
 && rm -rf /var/lib/apt/lists/*

LABEL maintainer="silvia"


ENTRYPOINT ["/app/linux_cli.sh"]
CMD ["-h"]

