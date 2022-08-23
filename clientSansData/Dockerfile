FROM golang:1.17-alpine

ARG ACCOUNT_PASSWORD

COPY genesis.json /tmp

#Init
RUN apk add --no-cache gcc musl-dev linux-headers git make
WORKDIR /tmp
RUN git clone https://github.com/MartiTM/go-ethereum.git
WORKDIR /tmp/go-ethereum

RUN git checkout exp

RUN make geth
RUN mv ./build/bin/geth /tmp
WORKDIR /
RUN chmod +x /tmp/geth
RUN /tmp/geth init /tmp/genesis.json \
    && rm -f ~/.ethereum/geth/nodekey \
    && echo ${ACCOUNT_PASSWORD} > /tmp/password \
    && /tmp/geth account new --password /tmp/password \
    && rm -f /tmp/password

ENTRYPOINT ["/tmp/geth"]