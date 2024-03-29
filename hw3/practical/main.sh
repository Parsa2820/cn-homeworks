#!/bin/bash
#
# This script offer a simple interface to configure iptables firewall.
# In order to run this script, you need some packages:
#   - iptables
#   - sqlite3
#   - openssh-server
#   - systemd
#   - systemd-resolved
# Tested on Debian GNU/Linux 11.
# Run this script with sufficient privileges.


ddos_log_prefix="[DDoS Log] "
ddos_db_file="/var/lib/ddos.db"
ddos_db_table="trusted_hosts"
ddos_db_schema="ddos.sql"

traffic_types=(INPUT OUTPUT)

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

use_db_improve_dos_attack_prevention_menu_items=(
    "Configure input traffic log"
    "Extract log to DB"
    "Configure trusted users"
)

use_db_improve_dos_attack_prevention_menu_functions=(
    config_input_traffic_log
    extract_log_to_db
    config_trusted_users
)

block_port_scan_and_port_knocking_menu_items=(
    "Block port scan"
    "Set port knocking"
)

block_port_scan_and_port_knocking_menu_functions=(
    block_port_scan
    set_port_knocking
)


#######################################
# Echo menu with menu_items and get user input.
# Arguments:
#   $1: menu_items, array of strings.
# Returns:
#   User input, an integer.
#######################################
echo_menu() {
    clear
    local menu_items=("$@")
    echo "0. Exit"
    for ((i = 0; i < ${#menu_items[@]}; i++)); do
        echo "$((i + 1)). ${menu_items[$i]}"
    done
    echo -n "Please enter your choice: "
    read -r choice
    echo
    if [[ $choice -eq 0 ]]; then
        clear
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
    echo -n "Enter header key: "
    read -r header
    echo -n "Enter header content: "
    read -r header_content
    local rule="$header: $header_content"
    log_and_evaluate "iptables -A INPUT -m string --algo bm --string \"$rule\" -j DROP"
    log_and_evaluate "iptables -A OUTPUT -m string --algo bm --string \"$rule\" -j DROP"
}

#######################################
# Config DoS attack protection.
#######################################
config_dos_attack_prevention() {
    clear
    # /sbin/iptables --insert INPUT --proto tcp --dport 1345 --match state --state NEW --match recent --update --seconds $TIME --hitcount $HITS --jump DROP
    echo -n "Enter time in which queries should be count(seconds): "
    read -r time
    echo -n "Enter hit count: "
    read -r hits
    log_and_evaluate "iptables -A INPUT --match state --state NEW --match recent --update --seconds $time --hitcount $hits --jump DROP" 

}

#######################################
# Use DB to improve DoS attack prevention.
#######################################
use_db_improve_dos_attack_prevention() {
    clear
    echo_menu "${use_db_improve_dos_attack_prevention_menu_items[@]}"
    ${use_db_improve_dos_attack_prevention_menu_functions[ $(( $? - 1 )) ]}
}

#######################################
# Block port scan and port knocking.
#######################################
block_port_scan_and_port_knocking() {
    clear
    echo_menu "${block_port_scan_and_port_knocking_menu_items[@]}"
    ${block_port_scan_and_port_knocking_menu_functions[ $(( $? - 1 )) ]}
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
    echo -n "Enter the file name to block: "
    read -r file
    log_and_evaluate "iptables -A INPUT -p tcp --dport 21 -m string --algo bm --string \"$file\" -j DROP"
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
# Block DNS requests to specfic domain
#######################################
block_traffic_count_protocol_request_type_dns() {
    echo -n "Enter the domain to block: "
    read -r domain
    log_and_evaluate "iptables -A OUTPUT -p udp --dport 53 -m string --algo bm --string \"$domain\" -j DROP"
    log_and_evaluate "systemd-resolve --flush-caches"
}

#######################################
# Block specific MAC address in incoming traffic
#######################################
block_traffic_count_protocol_request_type_dhcp() {
    echo -n "Enter the MAC address to block: "
    read -r mac
    log_and_evaluate "iptables -A INPUT -p udp --sport 68 --dport 67 -m mac --mac-source $mac -j DROP"
}

#######################################
# Block HTTP/HTTPS requests with specific content
#######################################
block_traffic_count_protocol_request_type_http_https() {
    echo -n "Enter the content to block: "
    read -r content
    log_and_evaluate "iptables -A INPUT -p tcp --dport 80 -m string --algo bm --string \"$content\" -j DROP"
    log_and_evaluate "iptables -A INPUT -p tcp --dport 443 -m string --algo bm --string \"$content\" -j DROP"
}

#######################################
# Block specific email address in SMTP protocol
#######################################
block_traffic_count_protocol_request_type_smtp() {
    echo -n "Enter the email address to block: "
    read -r email
    log_and_evaluate "iptables -A INPUT -p tcp --dport 25 -m string --algo bm --string \"$email\" -j DROP"
}

#######################################
# Eneble logging of incoming traffic.
#######################################
config_input_traffic_log() {
    log_and_evaluate "iptables -I INPUT -m state --state NEW -j LOG --log-prefix='$ddos_log_prefix'"
}

#######################################
# Extract log to sqlite database.
#######################################
extract_log_to_db() {
    clear
    local f="$(mktemp)"
    log_and_evaluate "rm -f $f"
    log_and_evaluate "touch $f"
    log_and_evaluate "cat /var/log/kern.log | grep -i \"$ddos_log_prefix\" > $f"
    log_and_evaluate "rm -f $ddos_db_file"
    log_and_evaluate "sqlite3 $ddos_db_file < $ddos_db_schema"
    echo "Extracting log to sqlite database..."
    lines=$(cat $f)
    IFS=$'\n' 
    for line in $lines
    do
        local ip="$(echo $line | grep -oE 'SRC=([0-9\.]+)' | grep -oE '[0-9\.]+')"
        local mac="$(echo $line | grep -oE 'MAC=([0-9a-fA-F:]+)' | grep -oE '=[0-9a-fA-F:]+' | grep -oE '[0-9a-fA-F:]+')"
        mac="${mac:18:17}"
        if [[ -z $ip || -z $mac ]]; then
            continue
        fi
        sqlite3 $ddos_db_file "INSERT OR IGNORE INTO $ddos_db_table VALUES ('$mac', '$ip')"
    done
    echo "Extract complete. Database file: $ddos_db_file"
}

#######################################
# Add trusted users to DoS attack prevention system.
#######################################
config_trusted_users() {
    clear
    echo "Configuring trusted users..."
    local users="$(sqlite3 $ddos_db_file "SELECT * FROM $ddos_db_table")"
    IFS=$'\n'
    for user in $users
    do
        local info=(${user//|/$IFS})
        local mac="${info[0]}"
        local ip="${info[1]}"
        log_and_evaluate "iptables -A INPUT -m mac --mac-source \"$mac\" -j ACCEPT"
    done
    echo "Config complete."
}

#######################################
# Block port scan.
#######################################
block_port_scan() {
    echo -n "Enter the ports you are concerned with (separated by space): "
    read -r ports
    local ports_array=($ports)
    for port in "${ports_array[@]}"; do
        log_and_evaluate "iptables -A INPUT -p tcp --dport $port -m recent --set"
        log_and_evaluate "iptables -A INPUT -p tcp --dport $port -m recent --update --seconds 60 --hitcount 3 -j DROP"
    done
}

#######################################
# Setup port knocking.
#######################################
set_port_knocking() {
    echo -n "Enter first port to knock: "
    read -r port1
    echo -n "Enter second port to knock: "
    read -r port2
    echo -n "Enter third port to knock: "
    read -r port3
    echo -n "Enter target port: "
    read -r target_port
    echo -n "Enter chain name: "
    read -r chain_name
    log_and_evaluate "iptables -N $chain_name"
    log_and_evaluate "iptables -A INPUT -j $chain_name"
    log_and_evaluate "iptables -A $chain_name -p tcp --dport $target_port -m recent --rcheck --seconds 60 --reap --name knockfinal -j ACCEPT"
    log_and_evaluate "iptables -A $chain_name -p tcp -m tcp --dport $port1 -m recent --set --name knock1 -j REJECT"
    log_and_evaluate "iptables -A $chain_name -p tcp -m recent --rcheck --seconds 10 --reap --name knock1 -m tcp --dport $port2 -m recent --set --name knock2 -j REJECT"
    log_and_evaluate "iptables -A $chain_name -p tcp -m recent --rcheck --seconds 10 --reap --name knock2 -m tcp --dport $port3 -m recent --set --name knockfinal -j REJECT"
    log_and_evaluate "iptables -A INPUT -p tcp --dport $target_port -m state --state NEW,INVALID -j REJECT"
}

#######################################
# Show main menu.
#######################################
main_menu() {
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
