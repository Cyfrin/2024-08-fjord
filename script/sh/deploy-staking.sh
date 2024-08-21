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

# SablierV2LockupLinear https://docs.sablier.com/contracts/v2/deployments
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
SAFE=$(jq --arg network "${select_network}" '.[] | select(has($network)) | .[$network]' "${PROJECT_ROOT}/deployments/safe.json")

get_sablier_address_fn() {
    local sablier_name="$1"
    local sablier_address

    sablier_address=$(echo "$SAFE" | jq -r ".sablier[\"$sablier_name\"]")
    if [ "$sablier_address" != "null" ]; then
        echo "$sablier_address"
    else
        echo "Address not found for $sablier_name"
        exit 1
    fi
}

SABLIERV2_LOCKUPLINEAR=$(get_sablier_address_fn "Sablier_V2_Lockup_Linear_NFT")
FJO_ADDRESS=$(echo "${SAFE}" | jq -r '.protocolSettings.fjoAddress')
AUTHORIZED_SENDER=$(echo "${SAFE}" | jq -r '.protocolSettings.AuthorizedSender')

export SABLIERV2_LOCKUPLINEAR
export FJO_ADDRESS
export AUTHORIZED_SENDER
echo ""
echo "Sablier Lockup Linear: $SABLIERV2_LOCKUPLINEAR"
echo "FJO Address: $FJO_ADDRESS"
echo "Authorized Sender: $AUTHORIZED_SENDER"
echo ""
echo "deploing on ${select_network} with ${wallet_address} : balance is: ${wallet_balance} ETH ..."

# select_network match key from foundry.toml [rpc_endpoints] and [etherscan]
FOUNDRY_PROFILE=optimized forge script script/forge/DeployStaking.s.sol:FjordStakingScript \
    --fork-url "${select_network}" \
    --private-key "${OWNER_PRIVATE_KEY}" \
    --legacy \
    --broadcast \
    --verify

echo ""
echo "🎉 Deployed on ${select_network} 🚀, Generate deployment file!"
./script/sh/deployed.sh "${select_network}"
