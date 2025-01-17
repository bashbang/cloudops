FROM public.ecr.aws/ubuntu/ubuntu:24.04_stable

SHELL ["/bin/bash", "-c"]

RUN apt-get -y update && \
    apt-get -y upgrade

ARG DEBIAN_FRONTEND=noninteractive
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


RUN curl -sfL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && unzip awscliv2.zip -d awscliv2 && ./awscliv2/aws/install && rm awscliv2.zip

RUN curl https://rclone.org/install.sh | bash
# manually run 'rclone config' to setup the environment for each remote.

# install Openshift CLI tool oc
RUN curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.17/openshift-client-linux-4.17.1.tar.gz | tar -zxvf - -C /usr/local/bin/

# install Github CLI tool gh
RUN curl -sfL https://github.com/cli/cli/releases/download/v2.60.0/gh_2.60.0_linux_amd64.tar.gz | tar -zxvf - gh_2.60.0_linux_amd64/bin/gh --strip-components=1

# Set the default shell on openshift to use bash rather than sh
RUN /bin/sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd

ENTRYPOINT ["tail", "-f", "/dev/null"]
