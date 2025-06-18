#!/bin/bash

# This script provides a convenient way to interact with the Bitcoin Core node
# running in the Docker container.

# Check if the container is running
if ! docker ps | grep -q bitcoin-node; then
  echo "Error: bitcoin-node container is not running."
  echo "Start it with: docker-compose up -d"
  exit 1
fi

# Pass all arguments to bitcoin-cli inside the container
docker exec -it bitcoin-node bitcoin-cli -datadir=/home/bitcoin/.bitcoin "$@"