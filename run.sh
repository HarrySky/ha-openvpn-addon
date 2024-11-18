#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json

OPENVPN_CONFIG=""

########################################################################################################################
# Initialize the tun interface for OpenVPN if not already available
# Arguments:
#   None
# Returns:
#   None
########################################################################################################################
function init_tun_interface(){
    # create the tunnel for the openvpn client
    mkdir -p /dev/net
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi
}

########################################################################################################################
# Check if VPN config is set by user
# Arguments:
#   None
# Returns:
#   0 if config is available and 1 otherwise
########################################################################################################################
function check_config_available(){
    OPENVPN_CONFIG="$(bashio::config 'ovpn_config')"
    if [[ -z "${OPENVPN_CONFIG}" ]] ; then
        bashio::log.warning "Config is empty!"
        return 1
    fi

    return 0
}
########################################################################################################################
# Wait until the user has set .ovpn configuration in order to setup the VPN connection.
# Arguments:
#   None
# Returns:
#   None
########################################################################################################################
function wait_configuration() {
    bashio::log.info "Waiting until the user sets the config..."
    while true; do
        check_config_available
        if [[ $? == 0 ]] ; then
            break
        fi

        sleep 5
    done

    bashio::log.info "Config available! Saving..."
    echo "${OPENVPN_CONFIG}" > /etc/openvpn/client.ovpn
}

init_tun_interface
wait_configuration
bashio::log.info "Starting VPN tunnel"
openvpn --config /etc/openvpn/client.ovpn
