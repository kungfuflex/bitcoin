# Modified Bitcoin Core with Unlimited OP_RETURN Size

This project provides a Docker container that runs Bitcoin Core with the 80-byte OP_RETURN size limit removed. The container is configured to run bitcoind with the database directory set to `/home/bitcoin/.bitcoin` and under the `bitcoin` user.

## Modifications

The standard Bitcoin Core has a policy limit on the size of OP_RETURN data that can be included in transactions. This limit is defined in `src/policy/policy.h` as:

```cpp
static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT / WITNESS_SCALE_FACTOR;
```

This project modifies this limit to:

```cpp
static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT;
```

This effectively removes the WITNESS_SCALE_FACTOR division (which is 4), allowing for much larger OP_RETURN data to be included in transactions. The modification is applied during the Docker build process using a sed command in the Dockerfile.

## Building the Docker Image

To build the Docker image:

```bash
docker build -t bitcoin-unlimited-opreturn .
```

## Running the Container

### Using Docker

To run the container using Docker:

```bash
docker run -d --name bitcoin-node \
  -p 8333:8333 \
  -p 8332:8332 \
  -v /path/on/host/to/bitcoin-data:/home/bitcoin/.bitcoin \
  bitcoin-unlimited-opreturn
```

Replace `/path/on/host/to/bitcoin-data` with the path on your host machine where you want to store the Bitcoin blockchain data.

### Using Docker Compose

Alternatively, you can use Docker Compose:

```bash
# Build and start the container
docker-compose up -d

# Stop the container
docker-compose down
```

By default, the Docker Compose configuration will create a `bitcoin-data` directory in your project folder to store the blockchain data.

## Configuration

You can customize the Bitcoin Core configuration by creating a `bitcoin.conf` file in your data directory before starting the container.

A sample configuration file is provided in this repository as `bitcoin.conf.sample`. You can use it as a starting point:

```bash
# If using Docker directly
cp bitcoin.conf.sample /path/on/host/to/bitcoin-data/bitcoin.conf

# If using Docker Compose
cp bitcoin.conf.sample ./bitcoin-data/bitcoin.conf
```

Make sure to edit the file and change the default values, especially the RPC password.

Basic configuration example:

```
# Network-related settings
rpcuser=your_username
rpcpassword=your_strong_password
rpcallowip=127.0.0.1
rpcallowip=172.17.0.0/16  # Docker subnet
rpcbind=0.0.0.0

# Miscellaneous options
server=1
txindex=1
```

See the `bitcoin.conf.sample` file for more configuration options and explanations.

## Accessing the Bitcoin Core RPC

### Using Docker Exec

You can access the Bitcoin Core RPC interface using:

```bash
docker exec -it bitcoin-node bitcoin-cli -datadir=/home/bitcoin/.bitcoin [command]
```

For example:

```bash
docker exec -it bitcoin-node bitcoin-cli -datadir=/home/bitcoin/.bitcoin getblockchaininfo
```

### Using the Helper Script

For convenience, a helper script is provided that simplifies interaction with the Bitcoin node:

```bash
# Make the script executable (only needed once)
chmod +x bitcoin-cli.sh

# Use the script to run Bitcoin CLI commands
./bitcoin-cli.sh getblockchaininfo
./bitcoin-cli.sh getnetworkinfo
./bitcoin-cli.sh help
```

The script automatically passes all arguments to the bitcoin-cli command inside the container.

## Important Notes

- This modification only changes a policy rule, not a consensus rule. This means that while your node will accept and relay transactions with larger OP_RETURN data, other nodes on the network that haven't been similarly modified will not relay these transactions.
- You may need to connect directly to miners who have also removed this limit to get your transactions with large OP_RETURN data included in blocks.
- This modification is intended for experimental or private network use.
