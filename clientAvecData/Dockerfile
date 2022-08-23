FROM gethsansdata

ARG ACCOUNT_PASSWORD

COPY ClientData /tmp

RUN /tmp/geth import /tmp/ClientData

ENTRYPOINT ["/tmp/geth"]