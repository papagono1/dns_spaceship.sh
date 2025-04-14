#!/usr/bin/env bash

SPACESHIP_API="https://api.spaceship.com"

########  Public functions #####################

dns_spaceship_add() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  _spaceship_load_credentials || return 1
  _debug "First detect root zone"
  _get_root "$fulldomain" || return 1

  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"

  if ! _spaceship_rest POST "domains/$_domain/records" "{\"type\":\"TXT\",\"name\":\"$_sub_domain\",\"data\":\"$txtvalue\",\"ttl\":600}"; then
    _err "Add txt record error."
    return 1
  fi
  return 0
}

dns_spaceship_rm() {
  fulldomain="${1}"
  txtvalue="${2}"

  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  _spaceship_load_credentials || return 1
  _get_root "$fulldomain" || return 1

  record_id=$(_spaceship_rest GET "domains/$_domain/records" | grep -B5 "\"data\":\"$txtvalue\"" | grep -oE '"id":[0-9]+' | cut -d':' -f2)

  if [ -z "$record_id" ]; then
    _info "Don't need to remove."
  else
    _spaceship_rest DELETE "domains/$_domain/records/$record_id"
  fi
}

####################  Private functions below ##################################

_spaceship_load_credentials() {
  SPACESHIP_API_KEY="${SPACESHIP_API_KEY:-$(_readaccountconf_mutable SPACESHIP_API_KEY)}"
  SPACESHIP_API_SECRET="${SPACESHIP_API_SECRET:-$(_readaccountconf_mutable SPACESHIP_API_SECRET)}"

  if [ -z "$SPACESHIP_API_KEY" ] || [ -z "$SPACESHIP_API_SECRET" ]; then
    _err "Spaceship credentials not found."
    return 1
  fi

  _saveaccountconf_mutable SPACESHIP_API_KEY "$SPACESHIP_API_KEY"
  _saveaccountconf_mutable SPACESHIP_API_SECRET "$SPACESHIP_API_SECRET"
  return 0
}

_spaceship_rest() {
  m="$1"
  ep="$2"
  data="$3"

  export _H1="X-API-Key: $SPACESHIP_API_KEY"
  export _H2="X-API-Secret: $SPACESHIP_API_SECRET"
  if [ "$m" != "GET" ]; then
    _debug "$data"
    export _H3="Content-Type: application/json"
  fi

  url="$SPACESHIP_API/$ep"
  _debug "$m" "$url"
  response="$(_post "$data" "$url" "" "$m")"
  _debug2 response "$response"
  echo "$response"
}

_get_root() {
  fulldomain=$1

  i=1
  while true; do
    h=$(echo "$fulldomain" | cut -d . -f $i-100)
    if [ -z "$h" ]; then
      return 1
    fi
    if _spaceship_rest GET "domains/$h"; then
      if _startswith "$response" '{'; then
        _sub_domain="$(echo "$fulldomain" | sed "s/\\.$h\$//")"
        _domain="$h"
        return 0
      fi
    fi
    i=$(_math "$i" + 1)
  done
  return 1
}
