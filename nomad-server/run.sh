#!/usr/bin/with-contenv bashio

set -e

NODE_NAME=$(bashio::config 'node_name')
DATACENTER=$(bashio::config 'datacenter')
REGION=$(bashio::config 'region')
BOOTSTRAP_EXPECT=$(bashio::config 'bootstrap_expect')
RETRY_JOIN=$(bashio::config 'retry_join')
BIND_ADDR=$(bashio::config 'bind_addr')
ADVERTISE_ADDR=$(bashio::config 'advertise_addr')
DATA_DIR=$(bashio::config 'data_dir')
LOG_LEVEL=$(bashio::config 'log_level')

# Build retry-join args from a comma-separated list
RETRY_JOIN_ARGS=""
if [ -n "${RETRY_JOIN}" ]; then
    IFS=',' read -ra JOIN_LIST <<< "${RETRY_JOIN}"
    for ip in "${JOIN_LIST[@]}"; do
        ip=$(echo "${ip}" | tr -d '[:space:]')
        if [ -n "${ip}" ]; then
            RETRY_JOIN_ARGS="${RETRY_JOIN_ARGS} -retry-join=${ip}"
        fi
    done
fi

# Set advertise argument only when configured
ADVERTISE_ARG=""
if [ -n "${ADVERTISE_ADDR}" ]; then
    ADVERTISE_ARG="-advertise=${ADVERTISE_ADDR}"
fi

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

bashio::log.info "Starting Nomad server as ${NODE_NAME}"
bashio::log.info "Data dir: ${DATA_DIR}"
bashio::log.info "Advertise: ${ADVERTISE_ADDR:-<default>}"
bashio::log.info "Retry join: ${RETRY_JOIN}"

exec nomad agent -server \
    -node="${NODE_NAME}" \
    -datacenter="${DATACENTER}" \
    -region="${REGION}" \
    -bootstrap-expect="${BOOTSTRAP_EXPECT}" \
    -bind="${BIND_ADDR}" \
    ${ADVERTISE_ARG} \
    -data-dir="${DATA_DIR}" \
    -log-level="${LOG_LEVEL}" \
    ${RETRY_JOIN_ARGS}
