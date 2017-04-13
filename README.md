# docker_postgresql

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

# -- creds for connection to upstream server(recovery.conf props)
# -- or replication user creds to create for future connects
#ENV REPLICATION_USER repluser
#ENV REPLICATION_PASS qui1Goo3

#
# custom PSQL config
#
#ENV POSTGRES_CUSTOM_CONFIG 
