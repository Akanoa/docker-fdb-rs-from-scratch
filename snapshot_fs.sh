#!/usr/bin/env bash
docker compose up lab --build
LAST_LAB_CONTAINER_ID=$( docker container ls -aq --latest)
docker export "$LAST_LAB_CONTAINER_ID" > fs.tar