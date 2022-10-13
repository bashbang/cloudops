FROM image-registry.apps.gold.devops.gov.bc.ca/bcgov/patroni-postgres:12.4-latest

COPY entrypoint.sh /usr/bin

ENTRYPOINT [ "/bin/bash", "/usr/bin/entrypoint.sh" ]
