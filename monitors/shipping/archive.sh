#!/bin/bash

TOKEN_FILE="$(dirname $0)/.api_token"
API_URL="https://onetracker.app/api/parcels/%s/archive"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <package_id1> [package_id2 ...]"
  exit 1
fi

source $TOKEN_FILE

export token

archive_package() {
  local id=$1
  echo "Archiving package ID: $id"
  curl -s -X PUT -H "Cookie: api_token=$token" $(printf "https://onetracker.app/api/parcels/%s/archive" $id)
}

export -f archive_package

# Run curl requests in parallel on all passed arguments
/opt/homebrew/bin/parallel archive_package ::: "$@"

