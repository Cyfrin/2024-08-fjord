#!/bin/bash

set -e
source .env

select_network="$1"
AUCTION_ADR="$2"
CHAIN_ID=$(cast chain-id --rpc-url "$select_network")
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
DEPLOYMENT_FILE=$(find "$PROJECT_ROOT/deployments" -maxdepth 1 -type f -name "$CHAIN_ID-*.json")
# OWNER_ADDRESS=$(cast wallet address --private-key "${OWNER_PRIVATE_KEY}")
USER_ADDRESS=$(cast wallet address --private-key "${USER_PRIVATE_KEY}")
FJORD_POINTS=$(cast to-check-sum-address "$(jq -r '.[0].fjordPoints' "$DEPLOYMENT_FILE")")

#################
# AUCTION_ADR=
################# USER BID UNBID AND CLAIM
#################

echo "Bid on Fjord Auction $AUCTION_ADR on $select_network"

USER_BALANCE=$(cast call "$FJORD_POINTS" "balanceOf(address)(uint256)" ${USER_ADDRESS} --rpc-url "$select_network")
BID_10=$(echo "$USER_BALANCE / 10" | bc)
BID_20=$(echo "$USER_BALANCE * 2 / 10" | bc)

if [[ "$USER_BALANCE" -gt 0 ]]; then
    CAST_APPROVE_AUCTION=$(cast send ${FJORD_POINTS} "approve(address,uint256)" \
        ${AUCTION_ADR} ${USER_BALANCE} \
        --private-key ${USER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_APPROVE_AUCTION_TXHASH=$(echo "$CAST_APPROVE_AUCTION" | jq -r '.transactionHash')
    echo "approve txhash ${CAST_APPROVE_AUCTION_TXHASH}"

    timeEnd=$(cast call ${AUCTION_ADR} "auctionEndTime()(uint256)" --rpc-url "$select_network")

    if [[ "$timeEnd" -lt "$TIMESTAMP" ]]; then
        CAST_BID_AUCTION=$(cast send ${AUCTION_ADR} "bid(uint256)" \
            ${BID_20} \
            --private-key ${USER_PRIVATE_KEY} \
            --rpc-url ${select_network} \
            --json)
        CAST_BID_AUCTION_TXHASH=$(echo "$CAST_BID_AUCTION" | jq -r '.transactionHash')
        echo "bid txhash ${CAST_BID_AUCTION_TXHASH}"

        CAST_UNBID_AUCTION=$(cast send ${AUCTION_ADR} "unbid(uint256)" \
            ${BID_10} \
            --private-key ${USER_PRIVATE_KEY} \
            --rpc-url ${select_network} \
            --json)
        CAST_UNBID_AUCTION_TXHASH=$(echo "$CAST_UNBID_AUCTION" | jq -r '.transactionHash')
        echo "unbid txhash ${CAST_UNBID_AUCTION_TXHASH}"
    else
        CAST_END_AUCTION=$(cast send ${AUCTION_ADR} "auctionEnd()" \
            --private-key ${USER_PRIVATE_KEY} \
            --rpc-url ${select_network} \
            --json)
        CAST_END_AUCTION_TXHASH=$(echo "$CAST_END_AUCTION" | jq -r '.transactionHash')
        echo "End auction txhash ${CAST_END_AUCTION_TXHASH}"
        isEnded=$(cast call ${AUCTION_ADR} "ended()(bool)" --rpc-url "$select_network")
        echo "Auction is ended $isEnded. Exiting."

        CAST_CLAIMTOKEN_AUCTION=$(cast send ${AUCTION_ADR} "claimTokens()" \
            --private-key ${USER_PRIVATE_KEY} \
            --rpc-url ${select_network} \
            --json)
        CAST_CLAIMTOKEN_AUCTION_TXHASH=$(echo "$CAST_CLAIMTOKEN_AUCTION" | jq -r '.transactionHash')
        echo "Claim token txhash ${CAST_CLAIMTOKEN_AUCTION_TXHASH}"
    fi
else
   echo "Your balance of Fjord Point is $USER_BALANCE. Exiting." 
fi