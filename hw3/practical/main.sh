#!/bin/bash
#
# This script offer a simple interface to configure iptables firewall.
# In order to run this script, you need to have iptables installed.
# Tested on Debian GNU/Linux 11 and iptables v1.8.7.
# Run this script with sufficient privileges.


main_menu_items=(
    "Block incoming/outgoing traffic to/from a specific IP, domain RegEx URL, or port."
    "Block incoming/outgoing traffic base on count, protocol, and request type."
    "Block traffic if header contains a specific string."
    "Config DoS attack prevention."
    "Use DB to improve DoS attack prevention."
    "Block port scan and port knocking."
    "Flush all rules."
    "Hi."
)

main_menu_functions=(
    block_traffic_ip_url_port
    block_traffic_count_protocol_request_type
    block_traffic_header_string
    config_dos_attack_prevention
    use_db_improve_dos_attack_prevention
    block_port_scan_and_port_knocking
    flush_all_rules
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

block_traffic_count_protocol_request_type_menu_items=(
    "FTP, Block specific file"
    "SSH, Blcok specific username"
    "DNS, Block specific domain"
    "DHCP, Block specific MAC address"
    "HTTP and HTTPS, Block specific content"
    "SMTP, Block specific email address"
)

block_traffic_count_protocol_request_type_menu_functions=(
    block_traffic_count_protocol_request_type_ftp
    block_traffic_count_protocol_request_type_ssh
    block_traffic_count_protocol_request_type_dns
    block_traffic_count_protocol_request_type_dhcp
    block_traffic_count_protocol_request_type_http_https
    block_traffic_count_protocol_request_type_smtp
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
# Get traffic type from user.
# Returns:
#   Traffic type (INPUT, OUTPUT, FORWARD), a string.
#######################################
ask_traffic_type() {
    echo "Enter traffic type(incoming[i], outgoing[o], forward[f]): "
    read -r traffic_type
    case $traffic_type in
        i)
            return "INPUT"
            ;;
        o)
            return "OUTPUT"
            ;;
        f)
            return "FORWARD"
            ;;
        *)
            echo "Invalid traffic type."
            exit 1
            ;;
    esac
}

#######################################
# Block incoming/outgoing traffic to/from a specific IP, domain RegEx URL, or port.
#######################################
block_traffic_ip_url_port() {
    clear
    echo_menu "${block_traffic_menu_items[@]}"
    ${block_traffic_menu_functions[ $(( $? - 1 )) ]}
}

#######################################
# Block incoming/outgoing traffic base on count, protocol, and request type.
#######################################
block_traffic_count_protocol_request_type() {
    clear
    echo_menu "${block_traffic_count_protocol_request_type_menu_items[@]}"
    ${block_traffic_count_protocol_request_type_menu_functions[ $(( $? - 1 )) ]}
}

#######################################
# Block traffic if header contains a specific string.
#######################################
block_traffic_header_string() {
    clear 
}

#######################################
# Config DoS attack prevention.
#######################################
config_dos_attack_prevention() {
    clear
}

#######################################
# Use DB to improve DoS attack prevention.
#######################################
use_db_improve_dos_attack_prevention() {
    clear
}

#######################################
# Block port scan and port knocking.
#######################################
block_port_scan_and_port_knocking() {
    clear
}

#######################################
# Flush all rules.
#######################################
flush_all_rules() {
    echo "Flushing all rules..."
    iptables --flush
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
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
# Block specfic file in FTP protocol
#######################################
block_traffic_count_protocol_request_type_ftp() {
    echo -n "Enter the file to block: "
    read -r file
    iptables -A INPUT -p tcp --dport 21 -m string --string $file --algo bm -j DROP
}

#######################################
# Hi
#######################################
hi() {
    echo "Hi"
}

#######################################
# Show main menu.
#######################################
main_menu() {
    clear
    echo_menu "${main_menu_items[@]}"
    ${main_menu_functions[ $(( $? - 1 )) ]}
}

#######################################
# Script starting point.
# Loop on main menu until user exits.
#######################################
main() {
    while true; do
        main_menu
        sleep_time=3
        echo "Showing main menu in $sleep_time seconds..."
        sleep $sleep_time
    done
}

main