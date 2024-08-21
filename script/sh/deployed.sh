#!/usr/bin/env bash
set -euo pipefail

# Source environment variables
source .env

# Constants
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")"
CONTRACT="FjordStaking"
DEPLOY_SC="DeployStaking"
DEPLOYED_FILENAME="fjord"
TOML_FILE="foundry.toml"
SQL_FILE="./deployments/contract_insert.sql"
CONTRACT_VERSION="v1.0.0"

# Input
SELECTED_NETWORK="${1:-}"
CHAIN_ID=$(cast chain-id --rpc-url "$SELECTED_NETWORK")
RUN_LATEST="./broadcast/$DEPLOY_SC.s.sol/$CHAIN_ID/run-latest.json"
OUTPUT_JSON="./deployments/$CHAIN_ID-$DEPLOYED_FILENAME-$SELECTED_NETWORK.json"

# Testnets list
TESTNETS=("localhost" "sepolia" "arbitrum_sepolia" "polygon_mumbai" "base_sepolia" "linea_sepolia" "blast_sepolia" "berachain_artio" "okx_testnet" "mode_sepolia" "manta_sepolia" "taiko_hekla" "lightlink_pegasus" "sei_testnet")

# Check if the selected network is a testnet
is_testnet=$(printf '%s\n' "${TESTNETS[@]}" | grep -qx "$SELECTED_NETWORK" && echo true || echo false)

# Create or verify deployment directory and initialize output JSON
mkdir -p ./deployments
echo "[]" | jq -s add > "$OUTPUT_JSON"

# Extract scan URL for the selected network
scan_url=$(grep -oE "^$SELECTED_NETWORK\s*=\s*\{.*url\s*=\s*\"[^\"]+\"" "$TOML_FILE" | grep -oE 'url\s*=\s*"[^"]+"' | cut -d'"' -f2)

echo "Deploying to network -> $SELECTED_NETWORK (ID: $CHAIN_ID)"

# Get contract address and block number
contract_address=$(jq -r --arg contract "$CONTRACT" '.transactions | map(select(.contractName == $contract)) | first | .contractAddress' "$RUN_LATEST")
block_number=$(jq -rc --arg contract_address "$contract_address" '.receipts[] | select(.contractAddress == $contract_address) | .blockNumber' "$RUN_LATEST")
block_number_dec=$(cast --to-base "$block_number" 10)

# If contract is found, generate metadata
if [ -n "$contract_address" ]; then
    echo "Contract $CONTRACT found at $contract_address"

    # Get ABI, related contracts, and deployed bytecode
    abi=$(jq -c ".abi" "./out/$CONTRACT.sol/$CONTRACT.json")
    fjord_points=$(jq -rc 'first(.transactions[] | select(.contractName == "FjordPoints") | .contractAddress)' "$RUN_LATEST")
    auction_factory=$(jq -rc '.transactions[] | select(.contractName == "AuctionFactory") | .contractAddress' "$RUN_LATEST")
    fjord_token=$(jq -rc '.transactions[] | select(.contractName == "FjordStaking") | .arguments[0]' "$RUN_LATEST")
    deployed_bytecode=$(forge inspect "$CONTRACT" deployedBytecode)

    # Build the JSON metadata object
    contract_info=$(jq -n \
        --arg contractName "$CONTRACT" \
        --arg version "$CONTRACT_VERSION" \
        --arg fjordStaking "$contract_address" \
        --arg fjordPoints "$fjord_points" \
        --arg auctionFactory "$auction_factory" \
        --arg fjordToken "$fjord_token" \
        --arg chainName "$SELECTED_NETWORK" \
        --argjson chainID "$CHAIN_ID" \
        --argjson blockNumber "$block_number_dec" \
        --arg deployedBytecode "$deployed_bytecode" \
        '{contractName: $contractName, version: $version, fjordStaking: $fjordStaking, fjordPoints: $fjordPoints, auctionFactory: $auctionFactory, fjordToken: $fjordToken, chainName: $chainName, chainID: $chainID, blockNumber: $blockNumber, deployedBytecode: $deployedBytecode}'
    )

    # Update the output JSON with contract metadata
    jq --argjson contract_info "$contract_info" '. += [$contract_info]' "$OUTPUT_JSON" > tmpfile && mv tmpfile "$OUTPUT_JSON"

    # Save the ABI to a separate file
    echo "$abi" > "./deployments/abi.${CONTRACT}.json"
    forge inspect FjordAuction abi > deployments/abi.FjordAuction.json
    forge inspect AuctionFactory abi > deployments/abi.FjordAuctionFactory.json
    forge inspect FjordPoints abi > deployments/abi.FjordPoints.json

    # Generate SQL insert statement
    id=$(uuidgen | perl -pe 's/^.*UUID: //')
    deployer_address=$(cast wallet address --private-key "$OWNER_PRIVATE_KEY")
    ghuc_url="https://raw.githubusercontent.com/marigoldlabs/fjord-contracts/master/${OUTPUT_JSON#./}"
    abi_base64=$(echo "$abi" | base64 -w 0)

    echo "('$id', '$deployer_address', '$CONTRACT', '$contract_address', 'evm', '$SELECTED_NETWORK', $CHAIN_ID, $is_testnet, $block_number_dec, '$abi_base64', '$scan_url', '$CONTRACT_VERSION', true, '$ghuc_url')," >> "$SQL_FILE"
else
    echo "Contract not found, empty metadata for: $CONTRACT"
fi

# Finalize the SQL file
sed -i '' -e '$ s/,$/;/' "$SQL_FILE"

# Output instructions for updating PlanetScale
echo ""
echo "To push the SQL file into PlanetScale:"
echo "pscale shell --org marigold-labs fjord-dev rob"
