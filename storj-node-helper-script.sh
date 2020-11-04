#!/bin/bash

NC='\033[0m'
CYAN='\033[0;36m'

read -p "Enter your wallet address: " WALLET_ADDRESS
read -p "Enter your email address: " EMAIL_ADDRESS
read -p "Enter your IP address or DDNS name: " IP_ADDRESS_OR_DNS_NAME
read -p "How much storage are you willing to share? Example: 700GB " HOW_MUCH_STORAGE_TO_SHARE_IN_GB
read -p "Where is your storage folder located? " STORAGE_PATH

if [[ $WALLET_ADDRESS != '' ]] && [[ $EMAIL_ADDRESS != '' ]] && [[ $IP_ADDRESS_OR_DNS_NAME != '' ]] && [[ $HOW_MUCH_STORAGE_TO_SHARE_IN_GB != '' ]] && [[ $STORAGE_PATH != '' ]]; then
        printf "You've entered: \n${CYAN}$WALLET_ADDRESS${NC}\n${CYAN}$EMAIL_ADDRESS${NC}\n${CYAN}$IP_ADDRESS_OR_DNS_NAME${NC}\n${CYAN}$HOW_MUCH_STORAGE_TO_SHARE_IN_GB${NC}\n${STORAGE_PATH}\nPress CTRL+C if this doesn't look right. \n" && read -p "Or just press enter to continue. "
elif [[ $WALLET_ADDRESS = '' ]] || [[ $EMAIL_ADDRESS = '' ]] || [[ $IP_ADDRESS_OR_DNS_NAME = '' ]] || [[ $HOW_MUCH_STORAGE_TO_SHARE_IN_GB = '' ]] || [[ $STORAGE_PATH = '' ]]; then
        printf "Mate, you can't run a script this way, please enter all the arguments.\n" && exit
fi

cat << EOF | cat > /root/storj.sh
docker stop storagenode
docker rm storagenode
docker pull storjlabs/storagenode:latest
docker run -d --restart unless-stopped -p 28967:28967 -p 14002:14002 -e WALLET="${WALLET_ADDRESS}" -e EMAIL="${EMAIL_ADDRESS}" -e ADDRESS="${IP_ADDRESS_OR_DNS_NAME}:28967" -e BANDWIDTH="256TB" -e STORAGE="${HOW_MUCH_STORAGE_TO_SHARE_IN_GB}" --mount type=bind,source="/root/.local/share/storj/identity/storagenode/",destination=/app/identity --mount type=bind,source="${STORAGE_PATH}",destination=/app/config --name storagenode storjlabs/storagenode:latest

docker stop watchtower
docker rm watchtower
docker pull storjlabs/watchtower
docker run -d --restart=always --name watchtower -v /var/run/docker.sock:/var/run/docker.sock storjlabs/watchtower storagenode watchtower --stop-timeout 300s --interval 21600
EOF

chmod +x /root/storj.sh
echo '@reboot bash -c "/root/storj.sh"' >> /etc/crontab

bash -c "/root/storj.sh"

IPADDR=$(ip a | grep "192\|10\|172" | awk '{print $2}' | awk '/^192|^10/' | sed 's/\/.*//')
printf "All done. Go and checkout your dashboard at: ${CYAN}http://${IPADDR}:14002${NC} \n"
