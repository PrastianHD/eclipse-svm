#!/bin/bash


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'  

# Install Solana CLI if not already installed
if ! command -v solana &> /dev/null
then
echo -e "${YELLOW}Solana CLI not found, installing Solana CLI...${NC}"
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
fi

solana --version

echo -e "${BLUE}How many wallets do you want to create?${NC}"
read -p "> " wallet_count

wallet_folder="data"
address_file="$wallet_folder/address.txt"
phrase_file="$wallet_folder/phrase.txt"

mkdir -p $wallet_folder

create_wallet() {
  wallet_index=$1
  wallet_file="$wallet_folder/wallet_$wallet_index.json"

  temp_output=$(mktemp)
  solana-keygen new --outfile $wallet_file --no-bip39-passphrase > $temp_output

  wallet_address=$(solana address -k $wallet_file)

  seed_phrase=$(grep -oP '^\w+( \w+){11,}' $temp_output)

  echo "=========================================================================" > $wallet_file
  echo "pubkey: $wallet_address" >> $wallet_file
  echo "=========================================================================" >> $wallet_file
  echo "Save this seed phrase and your BIP39 passphrase to recover your new keypair:" >> $wallet_file
  echo "$seed_phrase" >> $wallet_file
  echo "=========================================================================" >> $wallet_file

  echo $wallet_address >> $address_file
  echo $seed_phrase >> $phrase_file
  rm $temp_output

  echo -e "${GREEN}Wallet $wallet_index: $wallet_address${NC}"
}

for i in $(seq 1 $wallet_count)
do
  create_wallet $i
done

echo -e "${PURPLE}All $wallet_count wallets have been created and saved in the folder '$wallet_folder'.${NC}"