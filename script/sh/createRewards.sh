#!/bin/bash

set -e
source .env

select_network="$1"
CHAIN_ID=$(cast chain-id --rpc-url "$select_network")
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
SAFE=$(jq --arg network "${select_network}" '.[] | select(has($network)) | .[$network]' "${PROJECT_ROOT}/deployments/safe.json")
DEPLOYMENT_FILE=$(find "$PROJECT_ROOT/deployments" -maxdepth 1 -type f -name "$CHAIN_ID-*.json")
OWNER_ADDRESS=$(cast wallet address --private-key "${OWNER_PRIVATE_KEY}")
USER_ADDRESS=$(cast wallet address --private-key "${USER_PRIVATE_KEY}")

ASSET=$(cast to-check-sum-address "$(echo "${SAFE}" | jq -r '.protocolSettings.fjoAddress')")
FJORD_STAKING=$(cast to-check-sum-address "$(jq -r '.[0].fjordStaking' "$DEPLOYMENT_FILE")")

AMOUNT_1=$(cast to-unit 6ether wei)
AMOUNT_2=$(cast to-unit 311ether wei)
# TOTAL_AMOUNT=$(echo "$AMOUNT_1 + $AMOUNT_2" | bc)

## SEND FJO INTO FJO_STAKING

echo "approve ASSET to be used by fjordStaking"
CAST_APPROVE=$(cast send ${ASSET} "approve(address,uint256)" \
    ${FJORD_STAKING} ${AMOUNT_1} \
    --private-key ${USER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_APPROVE_TXHASH=$(echo "$CAST_APPROVE" | jq -r '.transactionHash')
echo "approve txhash ${CAST_APPROVE_TXHASH}"

echo "\nsend FJO to fjordStaking"
CAST_SEND_FJO=$(cast send ${ASSET} "transfer(address,uint256)" \
    ${FJORD_STAKING} \
    ${AMOUNT_1} \
    --private-key ${USER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_SEND_FJO_TXHASH=$(echo "$CAST_SEND_FJO" | jq -r '.transactionHash')
echo "transfer FJO into staking txhash ${CAST_SEND_FJO_TXHASH}"

# CALL ADD_REWARD ON FJORD_STAKING
# Check if OWNER_ADDRESS equals rewardAdmin
rewardAdmin=$(cast call "$FJORD_STAKING" "rewardAdmin()(address)" --rpc-url "$select_network")

if [ "$OWNER_ADDRESS" == "$rewardAdmin" ]; then
    echo "approve ASSET to be used by fjordStaking"
    CAST_APPROVE2=$(cast send ${ASSET} "approve(address,uint256)" \
        ${FJORD_STAKING} ${AMOUNT_2} \
        --private-key ${USER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_APPROVE2_TXHASH=$(echo "$CAST_APPROVE2" | jq -r '.transactionHash')
    echo "approve txhash ${CAST_APPROVE2_TXHASH}"

    echo "\nCalling addReward on fjordStaking"
    CAST_ADDREWARD=$(cast send ${FJORD_STAKING} "addReward(uint256)" \
        ${AMOUNT_2} \
        --private-key ${OWNER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_ADDREWARD_TXHASH=$(echo "$CAST_ADDREWARD" | jq -r '.transactionHash')
    echo "addReward txhash ${CAST_ADDREWARD_TXHASH}"
else
    echo "OWNER_ADDRESS does not match rewardAdmin. Exiting."
fi