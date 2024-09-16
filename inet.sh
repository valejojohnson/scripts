#!/bin/zsh

get_ip_info() {
  curl -s ipinfo.io/$1
}

# store your public IP and location info in variables
IP=$(get_ip_info ip)
COUNTRY=$(get_ip_info country)
CITY=$(get_ip_info city)
STATE=$(get_ip_info region)

echo "Your Public IPv4 address is $IP from $CITY, $STATE in the $COUNTRY"
