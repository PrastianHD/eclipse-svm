#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

read -p "Your deposited ethereum will be locked for an uncertain period of time. Do you want to proceed? (y/n): " LOCK_CONFIRM
case "${LOCK_CONFIRM,,}" in
    y|yes)
        ;;
    *)
        echo -e "${YELLOW}Operation cancelled by the user.${NC}"
        exit 0
        ;;
esac

read -p "You need to deposit a minimum of 0.002 ETH. Do you want to proceed? (y/n): " MIN_AMOUNT_CONFIRM
case "${MIN_AMOUNT_CONFIRM,,}" in
    y|yes)
        ;;
    *)
        echo -e "${YELLOW}Operation cancelled by the user.${NC}"
        exit 0
        ;;
esac

read -p "This interaction does not guarantee any airdrop. Would you still like to proceed? (y/n): " AIRDROP_CONFIRM
case "${AIRDROP_CONFIRM,,}" in
    y|yes)
        ;;
    *)
        echo -e "${YELLOW}Operation cancelled by the user.${NC}"
        exit 0
        ;;
esac

command_exists() {
    command -v "$1" &> /dev/null
}

if command_exists nvm; then
    echo -e "${GREEN}NVM is already installed.${NC}"
else
    echo -e "${YELLOW}Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    source ~/.bashrc
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command_exists node; then
    echo -e "${GREEN}Node.js is already installed: $(node -v)${NC}"
else
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    nvm install --lts
    nvm use --lts
    echo -e "${GREEN}Node.js installed: $(node -v)${NC}"
fi

echo -e "${YELLOW}Installing Yarn...${NC}"
npm install -g yarn

echo
echo -e "${YELLOW}Cloning the repository...${NC}"
echo
git clone https://github.com/Eclipse-Laboratories-Inc/eclipse-deposit.git
cd eclipse-deposit
echo
echo -e "${YELLOW}Installing project dependencies...${NC}"
npm install
echo

# Ensure private-key.txt and address.txt exist in the parent directory
if [ ! -f "../private-key.txt" ] || [ ! -f "../address.txt" ]; then
    echo -e "${RED}private-key.txt or address.txt not found in the parent directory.${NC}"
    exit 1
fi

# Read private keys and addresses from files
private_keys=$(cat ../private-key.txt)
addresses=$(cat ../address.txt)

# Convert keys and addresses to arrays
IFS=$'\n' read -r -d '' -a private_key_array <<< "$private_keys"
IFS=$'\n' read -r -d '' -a address_array <<< "$addresses"

# Check if the number of private keys and addresses match
if [ ${#private_key_array[@]} -ne ${#address_array[@]} ]; then
  echo -e "${YELLOW}The number of private keys and addresses must be the same.${NC}"
  exit 1
fi

# Prompt for the amount to deposit
echo -e "${BLUE}Enter ether amount you want to deposit in Eclipse Mainnet (Min: 0.002 ETH):${NC}"
read ETH_AMOUNT
echo

# Loop through each private key and address pair and execute the bridge command
for i in "${!private_key_array[@]}"; do
  private_key="${private_key_array[$i]}"
  address="${address_array[$i]}"
  
  echo "$private_key" > pvt-key.txt
  
  echo -e "${YELLOW}Executing bridge for address $address with private key $private_key...${NC}"
  node bin/cli.js -k pvt-key.txt -d "$address" -a "$ETH_AMOUNT" --mainnet
  echo
  echo -e "${GREEN}Deposits will finalize and be processed in about 2-3 minutes.${NC}"
  echo -e "${GREEN}You can check Eclipse Deposit Tx here: https://explorer.eclipse.xyz/address/$address${NC}"
  echo
done

echo -e "${GREEN}All bridge operations completed.${NC}"
