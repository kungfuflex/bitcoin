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

# Copy the patch file
COPY remove-op-return-limit.patch /tmp/

# Clone Bitcoin repository
WORKDIR /tmp
RUN git clone https://github.com/bitcoin/bitcoin.git

# Apply the patch to remove the 80-byte OP_RETURN limit
WORKDIR /tmp/bitcoin
RUN git apply /tmp/remove-op-return-limit.patch

# Build Bitcoin Core
RUN ./autogen.sh && \
    ./configure --disable-wallet --without-gui && \
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