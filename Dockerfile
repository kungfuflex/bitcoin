FROM ubuntu:22.04

# Install dependencies including CMake and SQLite3
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libssl-dev \
    libevent-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-chrono-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libminiupnpc-dev \
    libzmq3-dev \
    libdb-dev \
    libdb++-dev \
    libsqlite3-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create bitcoin user and group
RUN groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# Set up the data directory
RUN mkdir -p /home/bitcoin/.bitcoin && chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin

# Clone Bitcoin repository
WORKDIR /tmp
RUN git clone https://github.com/bitcoin/bitcoin.git

# Apply the modification to remove the 80-byte OP_RETURN limit
WORKDIR /tmp/bitcoin
RUN sed -i 's/static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT \/ WITNESS_SCALE_FACTOR;/static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT;/' src/policy/policy.h

# Build Bitcoin Core using CMake
RUN mkdir -p build && \
    cd build && \
    cmake -DBUILD_BITCOIN_WALLET=OFF -DBUILD_BITCOIN_QT=OFF .. && \
    make -j$(nproc) && \
    make install

# Clean up
RUN rm -rf /tmp/bitcoin

# Set working directory to bitcoin home
WORKDIR /home/bitcoin

# Switch to bitcoin user
USER bitcoin

# Expose ports
EXPOSE 8332 8333 18332 18333 18443 18444

# Set data directory
VOLUME ["/home/bitcoin/.bitcoin"]

# Start bitcoind
CMD ["bitcoind", "-datadir=/home/bitcoin/.bitcoin"]
