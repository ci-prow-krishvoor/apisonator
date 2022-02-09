#!/bin/bash

set -ev

# Builds Docker Image
docker build -t quay.io/3scale/apisonator-ci -f ./Dockerfile.ci .
