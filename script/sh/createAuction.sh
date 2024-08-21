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
FJORD_POINTS=$(cast to-check-sum-address "$(jq -r '.[0].fjordPoints' "$DEPLOYMENT_FILE")")
AUCTION_FACTORY=$(cast to-check-sum-address "$(jq -r '.[0].auctionFactory' "$DEPLOYMENT_FILE")")

PROJECT_TOKEN=$(cast to-check-sum-address 0xF8548d149fA7d0a35a2B88C441C706B3a9306f50) 
PROJECT_TOKEN_AMOUT=$(cast to-unit 13ether wei)
BIDDING_TIME=$((7 * 86400)) # 7 days auction
NONCE=$(cast nonce ${OWNER_ADDRESS} --rpc-url ${select_network})
TIMESTAMP=$(date +%s)
DATA="$NONCE$TIMESTAMP"
HASH="0x$(echo -n "$NONCE$TIMESTAMP" | sha256sum | awk '{print $1}')"
isOwner=$(cast call "$AUCTION_FACTORY" "owner()(address)" --rpc-url "$select_network")

# owner create auction
AUCTION_ADR=
if [ "$OWNER_ADDRESS" == "$isOwner" ]; then
    echo "approve PROJECT_TOKEN to be used by AUCTION_FACTORY"
    CAST_APPROVE=$(cast send ${PROJECT_TOKEN} "approve(address,uint256)" \
        ${AUCTION_FACTORY} ${PROJECT_TOKEN_AMOUT} \
        --private-key ${OWNER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_APPROVE_TXHASH=$(echo "$CAST_APPROVE" | jq -r '.transactionHash')
    echo "approve txhash ${CAST_APPROVE_TXHASH}"

    echo "\ncreate auction for PROJECT_TOKEN on AUCTION_FACTORY"
    CAST_CREATE_AUCTION=$(cast send ${AUCTION_FACTORY} "createAuction(address,uint256,uint256,bytes32)" \
        ${PROJECT_TOKEN} ${BIDDING_TIME} ${PROJECT_TOKEN_AMOUT} ${HASH} \
        --private-key ${OWNER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_CREATE_AUCTION_TXHASH=$(echo "$CAST_CREATE_AUCTION" | jq -r '.transactionHash')
    echo "createAuction txhash ${CAST_CREATE_AUCTION_TXHASH}"

    AUCTION_LOG=$(echo "$CAST_CREATE_AUCTION" | jq -c '.logs[] | select(.topics[0] == "0x8a8cc462d00726e0f8c031dd2d6b9dcdf0794fb27a88579830dadee27d43ea7c")')
    AUCTION_ADR_HEX=$(echo "${AUCTION_LOG}" | jq -r '.topics[1]')
    AUCTION_ADR=$(cast parse-bytes32-address "$AUCTION_ADR_HEX")
    echo "New Auction address ${AUCTION_ADR} created"
else
    echo "OWNER_ADDRESS does not match owner. Exiting."
fi

./script/sh/createBids.sh "${select_network}" "${AUCTION_ADR}"