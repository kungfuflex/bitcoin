FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
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

# Check the directory structure
WORKDIR /tmp/bitcoin
RUN ls -la

# Apply the modification to remove the 80-byte OP_RETURN limit
RUN sed -i 's/static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT \/ WITNESS_SCALE_FACTOR;/static const unsigned int MAX_OP_RETURN_RELAY = MAX_STANDARD_TX_WEIGHT;/' src/policy/policy.h

# Build Bitcoin Core
# First check if we're in the right directory and if the build scripts exist
RUN if [ -f "./autogen.sh" ]; then \
        ./autogen.sh && \
        ./configure --disable-wallet --without-gui && \
        make -j$(nproc) && \
        make install; \
    elif [ -f "./configure.ac" ]; then \
        autoreconf -i && \
        ./configure --disable-wallet --without-gui && \
        make -j$(nproc) && \
        make install; \
    else \
        echo "Could not find build scripts. Directory contents:" && \
        ls -la; \
    fi

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