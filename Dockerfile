# Use the official Ubuntu base image
FROM ubuntu:latest

# Set environment variables to non-interactive to avoid manual intervention during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libsasl2-dev \
    libldap2-dev \
    libdb-dev \
    libpcre3-dev \
    libcdb-dev \
    wget \
    libssl-dev \
    libicu-dev \
    ca-certificates \
    libnsl-dev \
    m4 \
    ed && \
    rm -rf /var/lib/apt/lists/*

# Create postfix and postdrop users and groups with specific IDs
RUN groupadd -g 12345 postfix && \
    groupadd -g 54321 postdrop && \
    useradd -u 12345 -g postfix -s /bin/false postfix

# Set the Postfix version to install
ENV POSTFIX_VERSION=3.9.0

# Download and extract the Postfix source code
RUN wget https://ghostarchive.org/postfix/postfix-release/official/postfix-$POSTFIX_VERSION.tar.gz && \
    tar -xzf postfix-$POSTFIX_VERSION.tar.gz && \
    rm postfix-$POSTFIX_VERSION.tar.gz

# Add placeholder configuration files
RUN mkdir -p /etc/postfix
COPY files/main.cf /etc/postfix/main.cf
COPY files/master.cf /etc/postfix/master.cf

# Build and install Postfix with LDAP, PCRE, and CDB support
WORKDIR /postfix-$POSTFIX_VERSION
RUN make makefiles CCARGS='-DUSE_TLS -DUSE_SASL_AUTH -DDEF_SERVER_SASL_TYPE=\"dovecot\" -DHAS_LDAP -I/usr/include/ldap -DHAS_PCRE -I/usr/include -DHAS_CDB' AUXLIBS='-lldap -llber -lpcre -lcdb -lssl -lcrypto -lnsl' && \
    make && \
    make upgrade

# Ensure Postfix binaries are in the PATH
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Open necessary ports
EXPOSE 25 587

# Start Postfix master process
CMD ["postfix", "start-fg"]
