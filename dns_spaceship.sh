#!/usr/bin/env sh

# Spaceship DNS API integration
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

  _get_root "$fulldomain"
  domain="$__domain"
  subdomain="$__sub_domain"
  _debug "Parsed domain: $domain"
  _debug "Subdomain: $subdomain"

  # 建立 TXT 紀錄
  body="{\"type\":\"TXT\",\"name\":\"_acme-challenge\",\"data\":\"$txtvalue\",\"ttl\":600}"
  _debug "Request body: $body"

  response="$(_post "$body" "$SPACESHIP_API/domains/$domain/records" "" "POST")"
  _debug "Spaceship API response: $response"

  if echo "$response" | grep '"id":' >/dev/null; then
    _info "Successfully added TXT record."
    return 0
  fi

  _err "Error adding TXT record"
  return 1
}

dns_spaceship_rm() {
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

  _get_root "$fulldomain"
  domain="$__domain"
  subdomain="$__sub_domain"
  _debug "Parsed domain: $domain"
  _debug "Subdomain: $subdomain"

  records="$(_get "$SPACESHIP_API/domains/$domain/records")"
  _debug "Fetched records: $records"

  record_id=$(echo "$records" | grep -oE '"id":[0-9]+' | head -n1 | cut -d':' -f2)

  if [ -z "$record_id" ]; then
    _info "No record found to delete."
    return 0
  fi

  _debug "Deleting record ID: $record_id"
  _response="$(_post "" "$SPACESHIP_API/domains/$domain/records/$record_id" "" "DELETE")"
  _debug "Delete response: $_response"

  return 0
}
