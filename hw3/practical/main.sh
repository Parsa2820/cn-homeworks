#!/bin/bash
#
# This script offer a simple interface to configure iptables firewall.
# In order to run this script, you need to have iptables installed.
# Tested on Debian GNU/Linux 11 and iptables v1.8.7.
# Run this script with sufficient privileges.


main_menu_items=(
    "Block incoming/outgoing traffic to/from a specific IP, domain RegEx URL, or port."
    "Hi"
)

main_menu_functions=(
    block_traffic
    hi
)

block_traffic_menu_items=(
    "Block incoming traffic from IP"
    "Block outgoing traffic to IP"
    "Block incoming traffic from domain RegEx URL"
    "Block outgoing traffic to domain RegEx URL"
    "Block incoming traffic from port"
    "Block outgoing traffic to port"
)

block_traffic_menu_functions=(
    block_traffic_from_ip
    block_traffic_to_ip
    block_traffic_from_domain
    block_traffic_to_domain
    block_traffic_from_port
    block_traffic_to_port
)


#######################################
# Echo menu with menu_items and get user input.
# Arguments:
#   $1: menu_items, array of strings.
# Returns:
#   User input, an integer.
#######################################
echo_menu() {
    local menu_items=("$@")
    echo "0. Exit"
    for ((i = 0; i < ${#menu_items[@]}; i++)); do
        echo "$((i + 1)). ${menu_items[$i]}"
    done
    echo -n "Please enter your choice: "
    read -r choice
    if [[ $choice -eq 0 ]]; then
        echo "Exiting..."
        exit 0
    fi
    if [[ $choice -lt 0 || $choice -gt ${#menu_items[@]} ]]; then
        echo "Invalid choice."
        exit 1
    fi
    return $choice
}

#######################################
# Block incoming/outgoing traffic to/from a specific IP, domain RegEx URL, or port.
#######################################
block_traffic() {
    clear
    echo_menu "${block_traffic_menu_items[@]}"
    ${block_traffic_menu_functions[ $(( $? - 1 )) ]}
}

#######################################
# Block incoming traffic from IP
#######################################
block_traffic_from_ip() {
    echo -n "Enter the IP address to block: "
    read -r ip
    sudo iptables -A INPUT -s $ip -j DROP
}

#######################################
# Block outgoing traffic to IP
#######################################
block_traffic_to_ip() {
    echo -n "Enter the IP address to block: "
    read -r ip
    sudo iptables -A OUTPUT -s $ip -j DROP
}

#######################################
# Block incoming traffic from domain RegEx URL
#######################################
block_traffic_from_domain() {
    echo -n "Enter the domain RegEx URL to block: "
    read -r domain
    iptables -A INPUT -s $domain -j DROP
}

#######################################
# Hi
#######################################
hi() {
    echo "Hi"
}

#######################################
# Script starting point.
#######################################
main() {
    clear
    echo_menu "${main_menu_items[@]}"
    ${main_menu_functions[ $(( $? - 1 )) ]}
}


main $@