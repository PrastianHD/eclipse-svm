#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "ECLIPSE SVM"
echo "Author: Prastian Hidayat"
echo -e "${NC}"

command_exists() {
    command -v "$1" &> /dev/null
}

install_nvm() {
    echo -e "${YELLOW}Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    source ~/.bashrc
}

install_node() {
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    nvm install --lts
    nvm use --lts
    echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
}

command_exists nvm || install_nvm

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

command_exists node || install_node

echo -e "${YELLOW}Installing Yarn...${NC}"
npm install -g yarn

echo -e "${YELLOW}Cloning the repository...${NC}"
git clone https://github.com/Eclipse-Laboratories-Inc/eclipse-deposit.git
cd eclipse-deposit

echo -e "${YELLOW}Installing project dependencies...${NC}"
npm install

PRIVATE_KEY_FILE="../data/privatekey.txt"
ADDRESS_FILE="../data/address.txt"

if [ ! -f "$PRIVATE_KEY_FILE" ]; then
    echo -e "${RED}privatekey.txt not found in the data directory.${NC}"
    exit 1
fi

if [ ! -f "$ADDRESS_FILE" ]; then
    echo -e "${RED}address.txt not found in the data directory.${NC}"
    exit 1
fi

private_keys=$(cat "$PRIVATE_KEY_FILE")
addresses=$(cat "$ADDRESS_FILE")

IFS=$'\n' read -r -d '' -a private_key_array < <(printf '%s\0' "$private_keys")
IFS=$'\n' read -r -d '' -a address_array < <(printf '%s\0' "$addresses")

if [ ${#private_key_array[@]} -ne ${#address_array[@]} ]; then
  echo -e "${YELLOW}The number of private keys and addresses must be the same.${NC}"
  exit 1
fi

echo -e "${BLUE}Select network:${NC}"
echo -e "${YELLOW}1. Testnet (Sepolia)${NC}"
echo -e "${YELLOW}2. Mainnet${NC}"
read -p "Enter choice [1 or 2]: " network_choice

case $network_choice in
  1)
    NETWORK="--sepolia"
    EXPLORER_URL="https://explorer.dev.eclipse.xyz/address"
    CLUSTER="?cluster=testnet"
    ;;
  2)
    NETWORK="--mainnet"
    EXPLORER_URL="https://explorer.eclipse.xyz/address"
    CLUSTER=""
    ;;
  *)
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
    ;;
esac

echo -e "${BLUE}Enter ether amount you want to deposit (Min: 0.002 ETH):${NC}"
read ETH_AMOUNT
echo

for i in "${!private_key_array[@]}"; do
  private_key="${private_key_array[$i]}"
  address="${address_array[$i]}"
  
  echo "$private_key" > privatekey.txt
  
  echo -e "${YELLOW}Executing bridge for address $address with private key...${NC}"
  node bin/cli.js -k privatekey.txt -d "$address" -a "$ETH_AMOUNT" $NETWORK
  echo
  echo -e "${GREEN}Deposits will finalize and be processed in upto 5 minutes.${NC}"
  echo -e "${GREEN}You can check Eclipse Deposit Tx here: ${EXPLORER_URL}/$address${CLUSTER}${NC}"
  echo
done

echo -e "${GREEN}All bridge operations completed.${NC}"
