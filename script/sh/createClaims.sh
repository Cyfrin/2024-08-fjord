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
AUCTION_FACTORY=$(cast to-check-sum-address "$(jq -r '.[0].auctionFactory' "$DEPLOYMENT_FILE")")
FJORD_POINTS=$(cast to-check-sum-address "$(jq -r '.[0].fjordPoints' "$DEPLOYMENT_FILE")")
isFPOwner=$(cast call "$FJORD_POINTS" "owner()(address)" --rpc-url "$select_network")

echo "Get all Active deposits on FJORD_STAKING"
cast call ${FJORD_STAKING} "getActiveDeposits(address)(uint256[])" \
    ${USER_ADDRESS} \
    --rpc-url ${select_network}

echo "\nVerify all your staked position(s) metadata"
cast call ${FJORD_STAKING} "userData(address)(uint256,uint256,uint16,uint16)" \
    ${USER_ADDRESS} \
    --rpc-url ${select_network}
echo "totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch"

echo "\nVerify your claimed intention(s)"
CAST_CLAIM_RECEIPTS=$(cast call ${FJORD_STAKING} "claimReceipts(address)(uint16,uint256)" \
    ${USER_ADDRESS} \
    --rpc-url ${select_network})

read -r REQUEST_EPOCH _ <<< "$CAST_CLAIM_RECEIPTS"
AMOUNT=$(echo "$CAST_CLAIM_RECEIPTS" | sed -n '2s/^\([0-9]*\).*/\1/p') # sed to removing extra characters on line 2
CLAIMABLE_EPOCH=$((REQUEST_EPOCH + 3))
echo "requestEpoch: $REQUEST_EPOCH, amount: $AMOUNT"

echo "\nSubmit a claim for your rewards of FJO"
if [ "$REQUEST_EPOCH" -eq 0 ] && [ "$AMOUNT" -eq 0 ]; then
    CAST_CLAIM_REWARDS=$(cast send ${FJORD_STAKING} "claimReward(bool)" false \
        --private-key ${USER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_CLAIM_REWARDS_TXHASH=$(echo "$CAST_CLAIM_REWARDS" | jq -r '.transactionHash')
    echo "claimReward txhash ${CAST_CLAIM_REWARDS_TXHASH}"
else
    echo "No new claim reward to create. Exiting."
fi  

CURRENT_EPOCH=$(cast call ${FJORD_STAKING} "currentEpoch()(uint16)" --rpc-url ${select_network})

echo "\nComplete all claimed intentions"
# Check if REQUEST_EPOCH is not 0 and if it is also CLAIMABLE_EPOCH less than CURRENT_EPOCH
if [ "$REQUEST_EPOCH" -ne 0 ] && [ "$CLAIMABLE_EPOCH" -lt "$CURRENT_EPOCH" ]; then
    CAST_CLAIM_REQUEST=$(cast send ${FJORD_STAKING} "completeClaimRequest()" \
        --private-key ${USER_PRIVATE_KEY} \
        --rpc-url ${select_network} \
        --json)
    CAST_CLAIM_REQUEST_TXHASH=$(echo "$CAST_CLAIM_REQUEST" | jq -r '.transactionHash')
    echo "completeClaimRequest txhash ${CAST_CLAIM_REQUEST_TXHASH}"
else
    echo "Epoch $CURRENT_EPOCH not match. Exiting."
fi

echo "\nAre you the Owner to be able to call distributePoints"
if [ "$OWNER_ADDRESS" == "$isFPOwner" ]; then
    echo "calling distributePoints"
    CAST_DISTRIBUTE_POINTS=$(cast send ${FJORD_POINTS} "distributePoints()" \
    --private-key ${OWNER_PRIVATE_KEY} \
    --rpc-url ${select_network})
    CAST_DISTRIBUTE_POINTS_TXHASH=$(echo "$CAST_DISTRIBUTE_POINTS" | jq -r '.transactionHash')
    echo "distributePoints txhash ${CAST_DISTRIBUTE_POINTS_TXHASH}"
else
    echo "OWNER_ADDRESS does not match owner. Exiting."
fi

echo "\nChecking your pending points"
CAST_CLAIM_POINTS=$(cast call ${FJORD_POINTS} "users(address)(uint256,uint256,uint256)" \
    ${USER_ADDRESS} \
    --rpc-url ${select_network})

PENDING_POINTS=$(echo "$CAST_CLAIM_POINTS" | sed -n '2s/^\([0-9]*\).*/\1/p') 
echo "pending points is $PENDING_POINTS"

if [ "$PENDING_POINTS" -gt 0 ]; then
    echo "claiming your Fjord Points"
    cast send ${FJORD_POINTS} "claimPoints()" \
        --private-key ${USER_PRIVATE_KEY} \
        --rpc-url ${select_network}
else
    echo "No Points to claim now. Exiting."
fi