FROM postgres:9.6
ARG POSTGRES_VERSION=9.6

RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8
RUN localedef -i fr_FR -c -f UTF-8 -A /usr/share/locale/locale.alias fr_FR.UTF-8
RUN localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


#
# Inherited variables from base image
#
#ENV PGDATA /var/lib/postgresql/data  # root directory for PostgreSQL data
#
#ENV POSTGRES_USER monkey_user        # superuser name
#ENV POSTGRES_PASSWORD monkey_pass    # superuser password
#ENV POSTGRES_DB monkey_db            # custom database owned by ${POSTGRES_USER}

#
# master/slave
#
# -- host name of upstream server.
# -- if its same to hostname this instance is blame as master, otherwise - as slave 
#ENV REPLICATION_UPSTREAM_HOST pgmaster
#ENV REPLICATION_UPSTREAM_HOST_IP 172.17.0.2

# -- creds for connection to upstream server(recovery.conf props)
# -- or replication user creds to create for future connects
#ENV REPLICATION_USER repluser
#ENV REPLICATION_PASS qui1Goo3

#
# custom PSQL config
#
#ENV POSTGRES_CUSTOM_CONFIG="shared_buffers:512MB,"

COPY conf/* /usr/local/etc/
COPY bin/custom-entrypoint.sh /docker-entrypoint-initdb.d/
COPY bin/postgresql-backup.sh /usr/local/bin/
COPY bin/postgresql-backup.conf.dist /usr/local/etc/
RUN touch /root/.postgresql

VOLUME /var/backups/postgresql
