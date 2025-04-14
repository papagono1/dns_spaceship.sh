#!/usr/bin/env sh

# Spaceship DNS API integration
# Reference: https://docs.spaceship.dev
# Author: ChatGPT 修正版

SPACESHIP_API="https://api.spaceship.dev/api/v1"
SPACESHIP_API_HOST="104.21.33.136"

######## Public functions ########

dns_spaceship_add() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "${fulldomain}"
  _debug txtvalue "${txtvalue}"

  if [ -z "$SPACESHIP_API_KEY" ] || [ -z "$SPACESHIP_API_SECRET" ]; then
    _err "SPACESHIP_API_KEY or SPACESHIP_API_SECRET not defined"
    return 1
  fi

  _saveaccountconf_mutable SPACESHIP_API_KEY "$SPACESHIP_API_KEY"
  _saveaccountconf_mutable SPACESHIP_API_SECRET "$SPACESHIP_API_SECRET"

  export _H1="Authorization: sso-key $SPACESHIP_API_KEY:$SPACESHIP_API_SECRET"
  export CURL_IPRESOLVE=4
  CURL_OPTIONS="--resolve api.spaceship.dev:443:$SPACESHIP_API_HOST"

  domain=$(echo "$fulldomain" | _get_root_domain)
  _debug "Parsed domain: $domain"

  subdomain="_acme-challenge.${domain}"
  _debug "Adding record to $subdomain"

  data="{\"type\":\"TXT\",\"name\":\"_acme-challenge\",\"value\":\"$txtvalue\",\"ttl\":300}"
  response="$(_post "$data" "$SPACESHIP_API/domains/$domain/records" "" "$CURL_OPTIONS")"

  _debug "Response: $response"
  if ! printf "%s" "$response" | grep "TXT"; then
    _err "Error adding TXT record"
    return 1
  fi
  return 0
}

dns_spaceship_rm() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "${fulldomain}"
  _debug txtvalue "${txtvalue}"

  domain=$(echo "$fulldomain" | _get_root_domain)
  subdomain="_acme-challenge.${domain}"

  export _H1="Authorization: sso-key $SPACESHIP_API_KEY:$SPACESHIP_API_SECRET"
  CURL_OPTIONS="--resolve api.spaceship.dev:443:$SPACESHIP_API_HOST"

  record_id="$(curl -s $CURL_OPTIONS -H "$_H1" "$SPACESHIP_API/domains/$domain/records" | grep -B 2 "$txtvalue" | grep '"id"' | head -1 | cut -d ':' -f2 | tr -d ', ')"
  _debug "Found record ID: $record_id"

  if [ -z "$record_id" ]; then
    _err "No record found to delete"
    return 1
  fi

  response="$(curl -s -X DELETE $CURL_OPTIONS -H "$_H1" "$SPACESHIP_API/domains/$domain/records/$record_id")"
  _debug "Delete response: $response"

  return 0
}
