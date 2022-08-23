#!/bin/bash

docker build -t gethsansdata:latest ./clientSansData/

docker build -t gethavecdata:latest ./clientAvecData/

docker build -t gethbootnode:latest ./clientBootnode/