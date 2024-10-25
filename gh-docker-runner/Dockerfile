FROM ubuntu:20.04

ARG RUNNER_VERSION="2.309.0"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt upgrade -y
RUN apt install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

RUN mkdir -p /actions-runner
WORKDIR /actions-runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

COPY start.sh start.sh
RUN chmod -R 755 /actions-runner
RUN /actions-runner/bin/installdependencies.sh

ENTRYPOINT ["./start.sh"]
