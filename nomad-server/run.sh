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

# Build retry-join HCL list from a comma-separated string
RETRY_JOIN_LIST=""
if [ -n "${RETRY_JOIN}" ]; then
    IFS=',' read -ra JOIN_LIST <<< "${RETRY_JOIN}"
    for ip in "${JOIN_LIST[@]}"; do
        ip=$(echo "${ip}" | tr -d '[:space:]')
        if [ -n "${ip}" ]; then
            # Default to Nomad Serf port 4648 if not specified
            if [[ ! "${ip}" =~ : ]]; then
                ip="${ip}:4648"
            fi
            if [ -n "${RETRY_JOIN_LIST}" ]; then
                RETRY_JOIN_LIST="${RETRY_JOIN_LIST}, "
            fi
            RETRY_JOIN_LIST="${RETRY_JOIN_LIST}\"${ip}\""
        fi
    done
fi

# Ensure data and config directories exist
mkdir -p "${DATA_DIR}"
mkdir -p /etc/nomad

# Generate Nomad server config
cat > /etc/nomad/nomad.hcl <<EOF
data_dir   = "${DATA_DIR}"
datacenter = "${DATACENTER}"
region     = "${REGION}"
name       = "${NODE_NAME}"
bind_addr  = "${BIND_ADDR}"
log_level  = "${LOG_LEVEL}"
EOF

# Add advertise block only when configured
if [ -n "${ADVERTISE_ADDR}" ]; then
    cat >> /etc/nomad/nomad.hcl <<EOF
advertise {
  http = "${ADVERTISE_ADDR}"
  rpc  = "${ADVERTISE_ADDR}"
  serf = "${ADVERTISE_ADDR}"
}
EOF
fi

cat >> /etc/nomad/nomad.hcl <<EOF
server {
  enabled          = true
  bootstrap_expect = ${BOOTSTRAP_EXPECT}
  server_join {
    retry_join = [${RETRY_JOIN_LIST}]
  }
}

consul {
  enabled = false
}
EOF

bashio::log.info "Starting Nomad server as ${NODE_NAME}"
bashio::log.info "Data dir: ${DATA_DIR}"
bashio::log.info "Advertise: ${ADVERTISE_ADDR:-<default>}"
bashio::log.info "Retry join: ${RETRY_JOIN}"

exec nomad agent -config=/etc/nomad/nomad.hcl
