#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm. sh" ] && \. "$NVM_DIR/nvm. sh"

d ~/hashBin/replica
set -euo pipefail

if [ "$#" -1t 2 ]; then
echo "Użycie: $0 <canister_id> <method_name> [arg1 arg2 ... ]" >&2
exit 1

Fi

CANISTER_ID="$1"
IETHOD_NAME="$2"
shift 2

# Budujemy Candid argument string: ("arg1", "arg2", ... )
CANDID_ARGS=""
if [ "$#" -gt 0 ]; then
parts=()
for arg in "$@"; do
# Escapujemy wewnętrzne cudzysłowy w wartości (gdyby się trafiły)
escaped="${arg//\"/\\\"}"
parts+=("\"$escaped\"")
done
# Łączymy przecinkami
joined=$(IFS=,; echo "${parts[*]}")
CANDID_ARGS="($joined)
else
CANDID_ARGS="()"

Fi

d ~/hashBin/replica
export DFX_WARNING =- mainnet_plaintext_identity

echo " == > icp canister call $CANISTER_ID $METHOD_NAME $CANDID_ARGS -- network ic"
icp canister call "$CANISTER_ID" "$METHOD_NAME" "$CANDID_ARGS" -- network ic
