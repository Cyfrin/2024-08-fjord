#!/usr/bin/env bash
set -e

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed. https://github.com/jqlang/jq/releases."
    exit 1
fi

source .env

if [ $# -eq 0 ]; then
    # Please provide or edit a valid deployment environment from your foundry.toml
    PS3="Select deployment environment (enter the number): "
    options=("localhost" "sepolia" "mainnet")
    select select_network in "${options[@]}"; do
        if [[ "$REPLY" -ge 1 && "$REPLY" -le "${#options[@]}" ]]; then
            break
        else
            echo "Invalid selection. Please enter a number between 1 and ${#options[@]}."
        fi
    done
else
    select_network="$1"
fi

wallet_address=$(cast wallet address --private-key "$OWNER_PRIVATE_KEY")
wallet_balance=$(cast balance --rpc-url "$select_network" "$wallet_address" -e)

if (($(echo "$wallet_balance < 0.02" | bc -l))); then
    echo -e "\033[0;91mWARNING: ${wallet_address} LOW BALANCE ${wallet_balance} ETH. [CTRL+C] to abort or Wait 5 seconds...\033[0m"
    sleep 5
fi

echo "deploing on ${select_network} with ${wallet_address} : balance is: ${wallet_balance} ETH ..."

# select_network match key from foundry.toml [rpc_endpoints] and [etherscan]
FOUNDRY_PROFILE=optimized forge script script/forge/DeployToken.s.sol:FjordTokenScript \
    --fork-url "${select_network}" \
    --private-key "${OWNER_PRIVATE_KEY}" \
    --legacy \
    --broadcast \
    --verify
