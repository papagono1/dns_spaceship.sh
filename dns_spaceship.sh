#!/usr/bin/env sh

# Spaceship DNS API integration
# Reference: https://docs.spaceship.dev
# Maintainer: ChatGPT 修正版

SPACESHIP_API="https://api.spaceship.dev/api/v1"

######## Public functions ########

dns_spaceship_add() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if [ -z "$SPACESHIP_API_KEY" ] || [ -z "$SPACESHIP_API_SECRET" ]; then
    _err "SPACESHIP_API_KEY or SPACESHIP_API_SECRET not defined"
    return 1
  fi

  _saveaccountconf_mutable SPACESHIP_API_KEY "$SPACESHIP_API_KEY"
  _saveaccountconf_mutable SPACESHIP_API_SECRET "$SPACESHIP_API_SECRET"

  export _H1="Authorization: sso-key $SPACESHIP_API_KEY:$SPACESHIP_API_SECRET"

  domain=$(echo "$fulldomain" | sed 's/^_acme-challenge\.//')
  subdomain="_acme-challenge"

  _debug "Parsed domain: $domain"
  _debug "Adding TXT record for $subdomain.$domain"

  data="{\"type\":\"TXT\",\"name\":\"$subdomain\",\"data\":\"$txtvalue\",\"ttl\":300}"

  response="$(_post "$data" "$SPACESHIP_API/domains/$domain/records")"
  _debug2 response "$response"

  if ! printf "%s\n" "$response" | grep -q '"id":'; then
    _err "Error creating DNS record"
    return 1
  fi

  return 0
}

dns_spaceship_rm() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if [ -z "$SPACESHIP_API_KEY" ] || [ -z "$SPACESHIP_API_SECRET" ]; then
    _err "SPACESHIP_API_KEY or SPACESHIP_API_SECRET not defined"
    return 1
  fi

  export _H1="Authorization: sso-key $SPACESHIP_API_KEY:$SPACESHIP_API_SECRET"

  domain=$(echo "$fulldomain" | sed 's/^_acme-challenge\.//')

  _debug "Parsed domain: $domain"

  records="$(_get "$SPACESHIP_API/domains/$domain/records")"
  record_id="$(echo "$records" | grep -oE '"id":[0-9]+' | head -1 | cut -d ':' -f2)"

  if [ -z "$record_id" ]; then
    _err "Could not find TXT record to delete"
    return 1
  fi

  _debug "Deleting record ID: $record_id"
  response="$(_delete "$SPACESHIP_API/domains/$domain/records/$record_id")"
  _debug2 response "$response"

  return 0
}
