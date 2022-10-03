# Note:
#   This Dockerfile is no longer maintained and has been replaced with another:
#   https://github.com/bcgov/patroni-postgres-container/blob/master/Dockerfile
# -----------------------------------------------------------------------------
FROM postgres:11
ARG patroniv=1.6.5
ENV PATRONI_VERSION=$patroniv
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV PATRONI_HOME=/opt/patroni

ARG PGHOME=/home/postgres

RUN export DEBIAN_FRONTEND=noninteractive
RUN set -x
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend
RUN apt-get update -y
RUN apt-get install -y curl jq locales libpq-dev git build-essential python3 python3-dev python3-pip python3-wheel python3-setuptools python3-virtualenv
RUN echo 'Make sure we have a en_US.UTF-8 locale available'
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN pip3 --isolated --no-cache-dir install psycopg2-binary
RUN pip3 --isolated --no-cache-dir install "patroni[kubernetes]==${PATRONI_VERSION}"
RUN PGHOME=/home/postgres
RUN mkdir -p $PGHOME
RUN sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd
RUN echo 'Setting permissions for OpenShift'
RUN chmod 664 /etc/passwd
RUN mkdir -p $PGHOME/pgdata/pgroot
RUN chgrp -R 0 $PGHOME
RUN chown -R postgres $PGHOME
RUN chmod -R 775 $PGHOME
RUN echo 'Cleaning up'
RUN apt-get remove -y git build-essential python3-dev python3-pip python3-wheel python3-setuptools
RUN apt-get autoremove -y
RUN apt-get clean -y
RUN rm -rf /var/lib/apt/lists/* /root/.cache

COPY contrib/root /

VOLUME /home/postgres/pgdata
EXPOSE 5432 8008
USER postgres
WORKDIR /home/postgres
CMD ["/bin/bash", "/usr/bin/entrypoint.sh"]
