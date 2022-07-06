#!/bin/bash
#
# This script offer a simple interface to configure iptables firewall.
# In order to run this script, you need to have iptables, systemd, and openssh-server installed.
# Tested on Debian GNU/Linux 11 and iptables v1.8.7.
# Run this script with sufficient privileges.


traffic_types=(INPUT OUTPUT)

debug_mode=true

main_menu_items=(
    "Block incoming/outgoing traffic to a specific IP, domain RegEx URL, or port."
    "Block incoming/outgoing traffic base on count, protocol, and request type."
    "Block traffic if header contains a specific string."
    "Config DoS attack prevention."
    "Use DB to improve DoS attack prevention."
    "Block port scan and port knocking."
    "Show all rules."
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
    show_all_rules
    flush_all_rules
    hi
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
    echo
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
#   Traffic type (INPUT, OUTPUT), a string.
#######################################
ask_traffic_type() {
    echo -n "Enter traffic type(incoming[i], outgoing[o]): "
    read -r traffic_type
    case $traffic_type in
        i)
            return 0
            ;;
        o)
            return 1
            ;;
        *)
            echo "Invalid traffic type."
            exit 1
            ;;
    esac
}

#######################################
# Log the input string and evaluate it.
# Arguments:
#   $1: input string, a string.
#######################################
log_and_evaluate() {
    echo "$1"
    eval $1
}

#######################################
# Block incoming/outgoing traffic to a specific IP, domain RegEx URL, or port.
# ptables -A FORWARD -m string --algo bm --string "hostname" -j ACCEPT
#######################################
block_traffic_ip_url_port() {
    clear
    ask_traffic_type
    local traffic_type=${traffic_types[$?]}
    echo -n "Enter IP address (-1 if empty): "
    read -r ip
    echo -n "Enter domain RegEx URL (-1 if empty): "
    read -r domain_url
    echo -n "Enter port (-1 if empty): "
    read -r port
    if [[ $ip = "-1" && $domain_url = "-1" && $port = "-1" ]]; then
        echo "Invalid input. All fields are empty."
        exit 1
    fi
    local ip_flag=""
    local ip_rule=""
    local domain_url_flag="-m string --algo bm --string"
    local domain_url_rule=""
    local port_flag="--dport"
    local port_rule=""
    if [[ $traffic_type = "INPUT" ]]; then
        ip_flag="-s"
    else # OUTPUT
        ip_flag="-d"
    fi
    if [[ $ip != "-1" ]]; then
        ip_rule="$ip_flag $ip"
    fi
    if [[ $domain_url != "-1" ]]; then
        domain_url_rule="$domain_url_flag \"$domain_url\""
    fi
    if [[ $port = "-1" ]]; then
        log_and_evaluate "iptables -A $traffic_type $ip_rule $domain_url_rule -j DROP"
    else
        port_rule="$port_flag $port"
        log_and_evaluate "iptables -A $traffic_type -p tcp $ip_rule $port_rule $domain_url_rule -j DROP"
        log_and_evaluate "iptables -A $traffic_type -p udp $ip_rule $port_rule $domain_url_rule -j DROP"
    fi
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
# Show all rules.
#######################################
show_all_rules() {
    iptables -S
    echo "----------------------------"
    iptables -L -v -n
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
    echo "Flush complete."
}

#######################################
# Hi
#######################################
hi() {
    echo "Hi"
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
# Block incoming ssh to specfic user
#######################################
block_traffic_count_protocol_request_type_ssh() {
    echo -n "Enter the user to block: "
    read -r user
    log_and_evaluate "echo \"DenyUsers $user\" >> /etc/ssh/sshd_config"
    log_and_evaluate "systemctl restart ssh.service"
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
        echo
        echo -n "Press enter to start over..."
        read -r
    done
}

main
