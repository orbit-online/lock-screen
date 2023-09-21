#!/usr/bin/env bash

lock_screen() {
  set -eo pipefail
  shopt -s inherit_errexit
  local pkgroot
  pkgroot=$(upkg root "${BASH_SOURCE[0]}")
  PATH="$pkgroot/.upkg/.bin:$PATH"
  # shellcheck source=.upkg/orbit-online/records.sh/records.sh
  source "$pkgroot/.upkg/orbit-online/records.sh/records.sh"

  DOC="lock-screen - Lock the screen unless a key is held
Usage:
  lock-screen [options] USERNAME TIMEOUT REASON

Options:
  --key EV_KEY      Which key to hold [default: KEY_LEFTSHIFT]
                    (Use \`evtest /dev/input/event<NUM>\` to see available keys)
  --key-desc DESC   Description of the key [default: shift]
                    (unless --key is specified)

Note:
  USERNAME is the name of the user that should be notified
  TIMEOUT is the time in seconds (e.g. 1.5) to allow the user to hold --key
    before locking the screen
  REASON is the reason for why the screen is being locked and will be the
    notification title
"
# docopt parser below, refresh this parser with `docopt.sh lock-screen.sh`
# shellcheck disable=2016,1090,1091,2034
docopt() { source "$pkgroot/.upkg/andsens/docopt.sh/docopt-lib.sh" '1.0.0' || {
ret=$?; printf -- "exit %d\n" "$ret"; exit "$ret"; }; set -e
trimmed_doc=${DOC:0:634}; usage=${DOC:51:54}; digest=45a52; shorts=('' '')
longs=(--key --key-desc); argcounts=(1 1); node_0(){ value __key 0; }; node_1(){
value __key_desc 1; }; node_2(){ value USERNAME a; }; node_3(){ value TIMEOUT a
}; node_4(){ value REASON a; }; node_5(){ optional 0 1; }; node_6(){ optional 5
}; node_7(){ required 6 2 3 4; }; node_8(){ required 7; }
cat <<<' docopt_exit() { [[ -n $1 ]] && printf "%s\n" "$1" >&2
printf "%s\n" "${DOC:51:54}" >&2; exit 1; }'; unset var___key var___key_desc \
var_USERNAME var_TIMEOUT var_REASON; parse 8 "$@"
local prefix=${DOCOPT_PREFIX:-''}; unset "${prefix}__key" \
"${prefix}__key_desc" "${prefix}USERNAME" "${prefix}TIMEOUT" "${prefix}REASON"
eval "${prefix}"'__key=${var___key:-KEY_LEFTSHIFT}'
eval "${prefix}"'__key_desc=${var___key_desc:-shift}'
eval "${prefix}"'USERNAME=${var_USERNAME:-}'
eval "${prefix}"'TIMEOUT=${var_TIMEOUT:-}'
eval "${prefix}"'REASON=${var_REASON:-}'; local docopt_i=1
[[ $BASH_VERSION =~ ^4.3 ]] && docopt_i=2; for ((;docopt_i>0;docopt_i--)); do
declare -p "${prefix}__key" "${prefix}__key_desc" "${prefix}USERNAME" \
"${prefix}TIMEOUT" "${prefix}REASON"; done; }
# docopt parser above, complete command for generating this parser is `docopt.sh --library='"$pkgroot/.upkg/andsens/docopt.sh/docopt-lib.sh"' lock-screen.sh`
  eval "$(docopt "$@")"

  checkdeps evtest notify-send dbus-launch sudo
  NOTIFY_REPLACE_SUPPORTED=false
  if notify-send --help | grep -q replace-id; then
    debug "Notification IDs supported"
    NOTIFY_REPLACE_SUPPORTED=true
  else
    debug "Notification IDs are not supported"
  fi
  # shellcheck disable=2154
  if [[ ! $__key =~ SHIFT && $__key_desc = shift ]]; then
    __key_desc=$__key
  fi

  if holding_key "$__key"; then
    # shellcheck disable=2153
    notify_send "$USERNAME" -a 'lock-screen' "Screen lock aborted" "Screen lock has been aborted because you held $__key_desc"
    verbose "Screen lock aborted. %s was held" "$__key"
    return 0
  fi
  notify_send "$USERNAME" -a 'lock-screen' "$REASON" "Hold $__key_desc to prevent the screen from locking"
  local sleep_proc
  sleep "$TIMEOUT" &
  sleep_proc=$!
  debug "Waiting %s seconds before locking screen" "$WAIT"
  while kill -0 $sleep_proc 2>/dev/null; do
    if holding_key "$__key"; then
      kill $sleep_proc 2>/dev/null
      notify_send "$USERNAME" -a 'lock-screen' "Screen lock aborted" "Screen lock has been aborted because you held $__key_desc"
      verbose "Screen lock aborted. %s was held" "$__key"
      return 0
    fi
  done
  verbose "Locking screen"
  /bin/loginctl lock-sessions
}

notify_send() {
  local username=$1
  shift
  if [[ -n $NOTIFY_ID ]]; then
    NOTIFY_ID=$(sudo -u "$username" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$username")/bus" DISPLAY=:0 notify-send --print-id --replace-id="$NOTIFY_ID" "$@")
  elif $NOTIFY_REPLACE_SUPPORTED; then
    NOTIFY_ID=$(sudo -u "$username" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$username")/bus" DISPLAY=:0 notify-send --print-id "$@")
  else
    sudo -u "$username" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$username")/bus" DISPLAY=:0 notify-send "$@"
  fi
}

holding_key() {
  local key=$1 evt
  for evt in /dev/input/event*; do
    if ! evtest --query "$evt" EV_KEY "$key"; then
      return 0
    fi
  done
  return 1
}

lock_screen "$@"
