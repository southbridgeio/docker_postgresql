#!/usr/bin/env bash
set -e
#set -x

PSQL_CONFIG_FILE="${PGDATA}/postgresql.conf"
PSQL_TEMPLATE_CONFIG_FILE='/usr/local/etc/postgresql.conf'
PSQL_CUSTOM_CONFIG_FILE="${PGDATA}/postgresql.local.conf"

RECOVERY_CONFIG_FILE="${PGDATA}/recovery.conf"
RECOVERY_TEMPLATE_CONFIG_FILE='/usr/local/etc/recovery.conf'

PG_HBA_CONFIG_FILE="${PGDATA}/pg_hba.conf"

if [[ -z "${REPLICATION_USER}" ]]; then
  REPLICATION_USER='replication'
fi
if [[ -z "${REPLICATION_PASS}" ]]; then
  REPLICATION_PASS='replication'
fi

echo '[custom-entrypoint] enter'


echo '[custom-entrypoint] check whether is master instance or not'
if [[ "x$(hostname)" == "x${REPLICATION_UPSTREAM_HOST}" ]]; then
  echo '  ... master'
  MASTER_INSTANCE=true
else
  echo '  ... slave'
  MASTER_INSTANCE=false
fi


# --
# copy custom config
# add custom options to config
# --
echo '[custom-entrypoint/configure] build custom config'

echo "[custom-entrypoint/configure] copy ${PSQL_TEMPLATE_CONFIG_FILE} to ${PSQL_CONFIG_FILE}"
cp "${PSQL_TEMPLATE_CONFIG_FILE}" "${PSQL_CONFIG_FILE}"

echo "[custom-entrypoint/configure] configure ${PSQL_CUSTOM_CONFIG_FILE}"
echo "
#
#------------------------------------------------------------------------------
# DOCKER AUTOGENERATED
#------------------------------------------------------------------------------
" >> "${PSQL_CUSTOM_CONFIG_FILE}"

IFS=',' read -ra CONFIG_PAIRS <<< "${POSTGRES_CUSTOM_CONFIG}"
for CONFIG_PAIR in "${CONFIG_PAIRS[@]}"
do
    IFS=':' read -ra CONFIG <<< "${CONFIG_PAIR}"
    VAR="${CONFIG[0]}"
    VAL="${CONFIG[1]}"
    echo "[custom-entrypoint/configure] adding config '${VAR}'='${VAL}' "
    echo "${VAR} = ${VAL}" >> "${PSQL_CUSTOM_CONFIG_FILE}"
done


# --
# add pg_hba replication entry
# --
echo '[custom-entrypoint/pg_hba] add pg_hba entry for replication user'
echo -e "host\treplication\t${REPLICATION_USER}\t0.0.0.0/0\tmd5" >> "${PG_HBA_CONFIG_FILE}"


# --
# master/slave main logic
# --
if ${MASTER_INSTANCE}; then
  # --
  # add replication user
  # --
  echo "[custom-entrypoint/master] create replication user '${REPLICATION_USER}'"
  psql -U "${POSTGRES_USER}" -c "CREATE ROLE ${REPLICATION_USER} WITH REPLICATION PASSWORD '${REPLICATION_PASS}' LOGIN"
else
  # --
  # build and copy recovery.conf
  # --
  if [[ -z "${REPLICATION_UPSTREAM_HOST}" ]]; then
    echo '[!ERROR!] instance ought to be a slave, but $REPLICATION_UPSTREAM_HOST is not set'
    exit
  fi

  if [[ -n "${REPLICATION_UPSTREAM_HOST_IP}" ]]; then
    echo "[custom-entrypoint/set ip addres] REPLICATION_UPSTREAM_HOST set to $REPLICATION_UPSTREAM_HOST_IP"
    REPLICATION_UPSTREAM_HOST=${REPLICATION_UPSTREAM_HOST_IP}
  fi

#  echo '[custom-entypoint/slave] copy recovery.conf'
#  cp "${RECOVERY_TEMPLATE_CONFIG_FILE}" "${RECOVERY_CONFIG_FILE}"

#  echo '[custom-entrypoint/slave] build connifo property'
#  CONN_INFO="primary_conninfo = 'user=${REPLICATION_USER} password=${REPLICATION_PASS} port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres host=${REPLICATION_UPSTREAM_HOST} application_name=$(hostname)'"
#  sed "s/^#primary_conninfo.*/${CONN_INFO}/" -i "${RECOVERY_CONFIG_FILE}"

  echo '[custom-entrypoint/slave] stop psql and clean up $PGDATA'
  pg_ctl -D "${PGDATA}" -m fast -w stop
  rm -rf "${PGDATA}"/*

  echo '[custom-entrypoint/slave] copy master database'
  PGPASSWORD=${REPLICATION_PASS} pg_basebackup -h "${REPLICATION_UPSTREAM_HOST}" -U "${REPLICATION_USER}" -P -R -D "${PGDATA}"
  echo "trigger_file='${PGDATA}/start_master'" >> "${PGDATA}/recovery.conf"

  pg_ctl -D "${PGDATA}" -w start
fi
