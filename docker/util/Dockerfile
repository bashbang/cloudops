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

# This presigned URL expires after a week. Can't have it longer than that unfortunatly.
# To get a new one: aws s3 presign s3://nttdata-canada/oc4 --expires-in 604800
RUN wget -O /usr/local/bin/oc https://nttdata-canada.s3.ca-central-1.amazonaws.com/oc4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQQWUE5HUH7PUSCXV%2F20221115%2Fca-central-1%2Fs3%2Faws4_request&X-Amz-Date=20221115T021334Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=462937d6144d8e650a2c01f1c384c30220236f50a51159860fa55445e8970353
RUN chmod +x /usr/local/bin/oc

# Set the default shell on openshift to use bash rather than sh
RUN /bin/sed -i 's/SHELL=\/bin\/sh/SHELL=\/bin\/bash/g' /etc/default/useradd

CMD tail -f /dev/null
