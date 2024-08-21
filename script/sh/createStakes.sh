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

SENDER=$OWNER_ADDRESS
RECIPIENT=$USER_ADDRESS
TOTAL_AMOUNT=$(cast to-unit 18ether wei)
ASSET=$(cast to-check-sum-address "$(echo "${SAFE}" | jq -r '.protocolSettings.fjoAddress')")
SABLIER=$(echo "${SAFE}" | jq -r '.sablier.Sablier_V2_Lockup_Linear_NFT')
FJORD_STAKING=$(cast to-check-sum-address "$(jq -r '.[0].fjordStaking' "$DEPLOYMENT_FILE")")
CANCELABLE=true

TRANSFERABLE=true
VESTING_START=$(date -d "+10 minutes" +"%s")
VESTING_END=$(date -d "@$(($VESTING_START + 96 * 3600))" +"%s")

BROKER_ADR=0x0000000000000000000000000000000000000000
PERCENT=0

### STAKE VESTED FJO FROM SABLIER BY AUTHORISED SENDER (FJORD)

echo "approve ASSET to be used by Sablier"
CAST_APPROVE=$(cast send ${ASSET} "approve(address,uint256)" \
    ${SENDER} ${TOTAL_AMOUNT} \
    --private-key ${OWNER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_APPROVE_TXHASH=$(echo "$CAST_APPROVE" | jq -r '.transactionHash')
echo "approve txhash ${CAST_APPROVE_TXHASH}"

echo "\nsend tx to vest ${TOTAL_AMOUNT} token into Sablier on ${select_network}"
CAST_SAB_VESTING=$(cast send ${SABLIER} "createWithDurations((address,address,uint128,address,bool,bool,(uint40,uint40),(address,uint256)))" \
  "(${SENDER},${RECIPIENT},${TOTAL_AMOUNT},${ASSET},${CANCELABLE},${TRANSFERABLE},("${VESTING_START}","${VESTING_END}"),("${BROKER_ADR}","${PERCENT}"))" \
  --private-key ${OWNER_PRIVATE_KEY} \
  --rpc-url ${select_network} \
  --json)
CAST_SAB_VESTING_TXHASH=$(echo "$CAST_SAB_VESTING" | jq -r '.transactionHash')
echo "createWithDurations txhash ${CAST_SAB_VESTING_TXHASH}"
METADATA_UPDATE_LOG=$(echo "$CAST_SAB_VESTING" | jq -c '.logs[] | select(.topics[0] == "0xf8e1a15aba9398e019f0b49df1a4fde98ee17ae345cb5f6b5e2c27f5033e8ce7")')
STREAM_ID_HEX=$(echo "$METADATA_UPDATE_LOG" | jq -r '.data')
STREAM_ID=$(cast --to-dec "$STREAM_ID_HEX")
echo "New Sablier StreamID ${STREAM_ID} created"

echo "\napprove Sablier TokenID to be used by fjordStaking"
CAST_APPROVE2=$(cast send ${SABLIER} "approve(address,uint256)" \
    ${FJORD_STAKING} ${STREAM_ID} \
    --private-key ${USER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_APPROVE2_TXHASH=$(echo "$CAST_APPROVE2" | jq -r '.transactionHash')
echo "approve txhash ${CAST_APPROVE2_TXHASH}"

echo "\nsend tx to stake vested FJO"
STAKE_VESTED_FJO=$(cast send ${FJORD_STAKING} "stakeVested(uint256)" \
  ${STREAM_ID} \
  --private-key ${USER_PRIVATE_KEY} \
  --rpc-url ${select_network} \
  --json)
CAST_STAKE_VESTED_FJO_TXHASH=$(echo "$STAKE_VESTED_FJO" | jq -r '.transactionHash')
echo "stakeVested txhash ${CAST_STAKE_VESTED_FJO_TXHASH}\n"

### STAKE FJO TOKEN

echo "\nApprove FJO token to be used by FjordStaking"
CAST_APPROVE3=$(cast send ${ASSET} "approve(address,uint256)" \
    ${FJORD_STAKING} 23000000000000000000 \
    --private-key ${USER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_APPROVE3_TXHASH=$(echo "$CAST_APPROVE3" | jq -r '.transactionHash')
echo "approve txhash ${CAST_APPROVE3_TXHASH}"

echo "\nStake FJO token into FjordStaking"
STAKE_FJO=$(cast send ${FJORD_STAKING} "stake(uint256)" 23000000000000000000 \
    --private-key ${USER_PRIVATE_KEY} \
    --rpc-url ${select_network} \
    --json)
CAST_STAKE_FJO_TXHASH=$(echo "$STAKE_FJO" | jq -r '.transactionHash')
echo "stakeVested txhash ${CAST_STAKE_FJO_TXHASH}"
