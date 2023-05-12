FROM public.ecr.aws/ubuntu/ubuntu:18.04_stable

SHELL ["/bin/bash", "-c"]

RUN apt-get -y update && \
    apt-get -y upgrade

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install awscli


RUN apt-get -y install \
    dnsutils \
    build-essential \
    curl \
    git \
    htop \
    nmap \
    iperf \
    iputils-ping \
    lynx \
    postgresql \
    postgresql-contrib \
    postgresql-client \
    procps \
    rsync \
    telnet \
    traceroute \
    unzip \
    vim \
    wget

RUN curl https://rclone.org/install.sh | bash
# manually run 'rclone config' to setup the environment for each remote.

# install Openshift CLI tool oc
RUN curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.10/openshift-client-linux.tar.gz | tar -zxvf - -C /usr/local/bin/

# install Github CLI tool gh
RUN curl -sfL https://github.com/cli/cli/releases/download/v2.20.2/gh_2.20.2_linux_amd64.tar.gz | tar -zxvf - gh_2.20.2_linux_amd64/bin/gh --strip-components=1

# Set the default shell on openshift to use bash rather than sh
RUN /bin/sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd

CMD tail -f /dev/null
