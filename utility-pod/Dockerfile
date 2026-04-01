FROM public.ecr.aws/ubuntu/ubuntu:24.04_stable

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM
ARG GH_VERSION="2.89.0"
ARG MONGODB_VERSION="8.2"

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install \
        build-essential \
        curl \
        dnsutils \
        git \
        htop \
        iperf \
        iputils-ping \
        jq \
        lynx \
        mysql-client \
        nmap \
        postgresql \
        postgresql-contrib \
        postgresql-client \
        python3 \
        python3-pip \
        procps \
        rsync \
        telnet \
        traceroute \
        unzip \
        vim \
        wget \
        yq && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages patroni[etcd] psycopg[binary]

RUN curl -fsSL https://pgp.mongodb.com/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg --dearmor && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list && \
    apt-get -y update && \
    apt-get -y install \
        mongodb-mongosh && \
    rm -rf /var/lib/apt/lists/*

# A writeable folder for OCP deployments that are non-root based runtimes
RUN mkdir /test && \
    chgrp 0 /test && \
    chmod 775 /test

RUN mkdir /test2 && \
    chgrp 0 /test2 && \
    chmod g=u /test2

RUN set -eux; \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        AWS_ARCH=x86_64; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        AWS_ARCH=aarch64; \
    else \
        echo "Unsupported platform: $TARGETPLATFORM"; exit 1; \
    fi; \
    curl -sfL https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip -o awscliv2.zip; \
    unzip awscliv2.zip; \
    ./aws/install; \
    rm -rf awscliv2.zip aws

RUN curl https://rclone.org/install.sh | bash
# manually run 'rclone config' to setup the environment for each remote.

# install Openshift CLI tool oc
RUN set -eux; \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        OCP_ARCH=""; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        OCP_ARCH="-arm64"; \
    else \
        echo "Unsupported platform: $TARGETPLATFORM"; exit 1; \
    fi; \
    curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux${OCP_ARCH}.tar.gz | tar -zxvf - -C /usr/local/bin/

# install Github CLI tool gh
RUN set -eux; \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        GH_ARCH=amd64; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        GH_ARCH=arm64; \
    else \
        echo "Unsupported platform: $TARGETPLATFORM"; exit 1; \
    fi; \
    curl -sfL https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz -o gh.tar.gz; \
    tar -xzf gh.tar.gz; \
    cp gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh /usr/local/bin/gh; \
    rm -rf gh.tar.gz gh_${GH_VERSION}_linux_${GH_ARCH}

# Set the default shell on openshift to use bash rather than sh
RUN /bin/sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd

ENTRYPOINT ["tail", "-f", "/dev/null"]
