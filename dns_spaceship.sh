#!/usr/bin/env sh

# Spaceship DNS API integration
#
# Reference: https://docs.spaceship.dev
# Author: ChatGPT 修正版

SPACESHIP_API="https://api.spaceship.dev/api/v1"

########  Public functions #####################

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

  domain=$(echo "$fulldomain" | _get_root_domain)
  _debug "Parsed domain: $domain"

  subdomain="_acme-challenge.${domain}"
  _debug "Adding record to $subdomain"

  data="{\"type\":\"TXT\",\"name\":\"_acme-challenge\",\"data\":\"$txtvalue\",\"ttl\":600}"

  response="$(_post "$data" "$SPACESHIP_API/domains/$domain/records" "" "POST")"

  if _contains "$response" "\"id\":"; then
    _info "TXT record added successfully"
    return 0
  else
    _err "Failed to add TXT record"
    _err "$response"
    return 1
  fi
}

dns_spaceship_rm() {
  fulldomain="${1}"
  txtvalue="${2}"

  _info "Removal not implemented"
}

####################  Utilities  ########################

_get_root_domain() {
  echo "$1" | sed -E 's/^.*\.([^.]+\.[^.]+)$/\1/'
}
