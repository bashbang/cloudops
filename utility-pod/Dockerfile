FROM public.ecr.aws/ubuntu/ubuntu:24.04_stable

SHELL ["/bin/bash", "-c"]

RUN apt-get -y update && \
    apt-get -y upgrade

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM

RUN apt-get -y install \
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
        procps \
        rsync \
        telnet \
        traceroute \
        unzip \
        vim \
        wget \
        yq

RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
RUN echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
RUN apt-get -y update && \
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
    curl -sfL https://github.com/cli/cli/releases/download/v2.82.1/gh_2.82.1_linux_${GH_ARCH}.tar.gz -o gh.tar.gz; \
    tar -xzf gh.tar.gz; \
    cp gh_2.60.0_linux_${GH_ARCH}/bin/gh /usr/local/bin/gh; \
    rm -rf gh.tar.gz gh_2.60.0_linux_${GH_ARCH}

# Set the default shell on openshift to use bash rather than sh
RUN /bin/sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd

ENTRYPOINT ["tail", "-f", "/dev/null"]
