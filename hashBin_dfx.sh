#!/bin/bash
# Użycie: dfx_call.sh <canister_id> <method_name> <arg1> <arg2> ... <argN>
# Wszystkie argumenty są traktowane jako typ Candid `text`.

cd ~/HashBin/hashbin
export DFX_WARNING=-mainnet_plaintext_identity
export PATH="/home/klik/.local/share/dfx/bin:$PATH"

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Użycie: $0 <canister_id> <method_name> [arg1 arg2 ...]" >&2
    exit 1
fi

CANISTER_ID="$1"
METHOD_NAME="$2"
shift 2

# Budujemy Candid argument string: ("arg1","arg2",...)
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
    CANDID_ARGS="($joined)"
else
    CANDID_ARGS="()"
fi

cd ~/HashBin/hashbin
export DFX_WARNING=-mainnet_plaintext_identity

echo "==> dfx canister call $CANISTER_ID $METHOD_NAME $CANDID_ARGS --network ic"

dfx canister call "$CANISTER_ID" "$METHOD_NAME" "$CANDID_ARGS" --network ic
