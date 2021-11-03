#!/bin/bash

# Header
if [[ $MF_DEBUG -eq 1 ]]; then
    printf "miniflux-filter - git.mgrote.net/mg/miniflux-filter\n"
fi

### datei mit filter ausdruecken
MF_FILTERLIST_FILE="${MF_FILTERLIST_FILE:=/data/filter.txt}"
### wartezeit zwischen durchlaeufen
MF_SLEEP="${MF_SLEEP:=30}"
### MF_DEBUG output
# standardmäßig 0 = aus
MF_DEBUG="${MF_DEBUG=0}"

# Functions
function output_help {
    cat <<EOF
miniflux-filter

https://git.mgrote.net/mg/miniflux-filter

Usage:
  - filter.sh [OPTIONS]

Options:
    -h, --help                  displays this text
    *                           script gets executed

EOF
}
function check_dependencies {
    # pruefe ob jq installiert ist
    # https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] check dependencies"
    fi
    if ! command -v jq &> /dev/null
    then
        echo "[ERROR] jq could not be found!"
        exit 5
    fi
    if ! command -v curl &> /dev/null
    then
        echo "[ERROR] curl could not be found!"
        exit 6
    fi
    if ! command -v xargs &> /dev/null
    then
        echo "[ERROR] xargs could not be found!"
        exit 8
    fi
    if ! command -v sed &> /dev/null
    then
        echo "[ERROR] sed could not be found!"
        exit 9
    fi
    if ! command -v sort &> /dev/null
    then
        echo "[ERROR] sort could not be found!"
        exit 10
    fi
    if ! command -v awk &> /dev/null
    then
        echo "[ERROR] awk could not be found!"
        exit 11
    fi
}
function check_vars {
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] check if vars are (correctly) set"
    fi
    # pruefe ob alle vars gesetzt sind
    # -z = ob laenge gleich null ist
    if [[ -z "${MF_AUTH_TOKEN}" ]]; then
        # shellcheck disable=SC2016
        # shellcheck disable=SC2102
        echo [ERROR] '"$MF_AUTH_TOKEN"' not set.
        exit 2
    fi
    if [[ -z "${MF_API_URL}" ]]; then
        # shellcheck disable=SC2016
        # shellcheck disable=SC2102
        echo [ERROR] '"$MF_API_URL"' not set.
        exit 3
    fi
    # prüfe ob filter-datei ein ordner ist
    # kann bei einem falschen bind-mount passieren
    if [[ -d "$MF_FILTERLIST_FILE" ]]; then
        # shellcheck disable=SC2102
        echo [ERROR] "$MF_FILTERLIST_FILE" is a directory!
        exit 4
    fi
    # pruefe ob filter-datei NICHT existiert
    if [[ ! -e "$MF_FILTERLIST_FILE" ]]; then
        # shellcheck disable=SC2102
        echo [ERROR] "$MF_FILTERLIST_FILE" not readable!
        exit 1
    fi
}
function check_connectivity {
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] check if miniflux-api can be reached"
    fi
    # pruefe ob miniflux erreichbar ist, wenn ja setze abbruchbedingung, sonst warte
    mf_connectivity=0
    while [[ $mf_connectivity -eq 0 ]]; do
        http_status_code=$(curl --silent --header "X-Auth-Token: $MF_AUTH_TOKEN" "$MF_API_URL/me" -i | grep HTTP/2 | awk '{print $2}')
        if [[ $http_status_code -eq 200 ]]; then
            mf_connectivity=1
        else
            mf_connectivity=0
            sleep 10
            echo "[INFO] wait for miniflux-api..."
            if [[ $MF_DEBUG -eq 1 ]]; then
                echo "[DEBUG] api could not be reached, wait 10s"
            fi
        fi
    done
}
function debug_output {
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo -----------------------------------------------------
        echo [DEBUG] Filterlist-File: "$MF_FILTERLIST_FILE"
        echo [DEBUG] Sleep-Intervall: "$MF_SLEEP"
        echo [DEBUG] Auth-Token: "$MF_AUTH_TOKEN"
        echo [DEBUG] MF-Url: "$MF_API_URL"
        echo [DEBUG] Anzahl Filter: "$(wc -l "$MF_FILTERLIST_FILE")"
        echo -----------------------------------------------------
    fi
}
function get_unread_entries {
    # hole alle ungelesenen entries und speichere sie in der variable unread_entries
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] get unread entries from miniflux"
    fi
    unread_entries="$(curl --silent --header "X-Auth-Token: $MF_AUTH_TOKEN" "$MF_API_URL/entries?status=unread&limit=0")"
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] show unread entries from miniflux"
        echo -----------------------------------------------------
        echo "$unread_entries"
        echo -----------------------------------------------------
    fi
}
function filter_entries {
    echo "[INFO] Filtering entries..."
    # fuer jede Zeile in $MF_FILTERLIST_FILE
    while read -r line; do
        if [[ $MF_DEBUG -eq 1 ]]; then
            echo "[DEBUG] set search values"
        fi
        # setze $url auf den Wert vor dem Trennzeichen/Delimiter, ersetze alle Grossschreibungen durch Kleinschreibung
        url=$(echo "$line" | tr '[:upper:]' '[:lower:]' | awk --field-separator="::" '{print $1}')
        # setze $suchbegriff auf den Wert vor dem Trennzeichen/Delimiter, ersetze alle Grossschreibungen durch Kleinschreibung
        suchbegriff=$(echo "$line" | tr '[:upper:]' '[:lower:]' | awk --field-separator="::" '{print $2}')
        # in jq uebergebe shell-variablen an jq selber
        # entferne die erste ebene
        # suche jeden eintrag wo die feed_url == $url, konvertiere in kleinschreibung, dasselbe fuer den title
        # gebe dann nur die id aus
        # die id, wird dann an die variable marked_entries angehangen
        # z.B. 53443 52332 48787 [...]
        if [[ -n "$url" ]]; then
            # abfangen der letzten zeile die leer ist; sonst wird alles gefiltert
            if [[ -n "$suchbegriff" ]]; then
                # abfangen der letzten zeile die leer ist; sonst wird alles gefiltert
                if [[ $MF_DEBUG -eq 1 ]]; then
                    echo [DEBUG] url:"$url" - value:"$suchbegriff"
                fi
                # das leerzeichen am anfang ist notwendig, trennt die zahlenwerte
                # suche in titel
                marked_entries+=" $(echo "$unread_entries" | jq --arg url "$url" --arg suchbegriff "$suchbegriff" '.entries[] | select(.feed.site_url | ascii_downcase | contains($url)) | select(.title | ascii_downcase | contains($suchbegriff)) | .id' )"
                # suche in content
                marked_entries+=" $(echo "$unread_entries" | jq --arg url "$url" --arg suchbegriff "$suchbegriff" '.entries[] | select(.feed.site_url | ascii_downcase | contains($url)) | select(.content | ascii_downcase | contains($suchbegriff)) | .id' )"
            fi
        fi
    done < "$MF_FILTERLIST_FILE"
}
function mark_as_read {
    # https://stackoverflow.com/questions/3869072/test-for-non-zero-length-string-in-bash-n-var-or-var
    # wenn variabler NICHT leer...
    # sende in put request mit curl
    # der wert muss escaped werden, aber NICHT die variable die uebergeben wird
    if [[ $MF_DEBUG -eq 1 ]]; then
        echo "[DEBUG] mark entries as read"
        echo "[DEBUG] marked entry ids:"
        # https://unix.stackexchange.com/questions/353321/remove-all-duplicate-word-from-string-using-shell-script
        # entfernt doppelte eintraege innerhalb einer zeile
        echo "$marked_entries" | xargs -n1 | sort -u | xargs | sed -r 's/\s/\, /g'
    fi
    # wenn NICHT leer
    # sed wandelt 123 345 456 in 123, 245, 345 um.
    if [[ $(echo "$marked_entries" | xargs -n1 | sort -u | xargs | sed -r 's/\s/\, /g') ]]; then
        curl --request PUT --silent --header "X-Auth-Token: $MF_AUTH_TOKEN" --header "Content-Type: application/json" --data "{\"entry_ids\": [$(echo "$marked_entries" | xargs -n1 | sort -u | xargs | sed -r 's/\s/\, /g')], \"status\": \"read\"}" "$MF_API_URL/entries"
    # gebe entry-titel aus
    for i in $(echo "$marked_entries" | xargs -n1 | sort -u | xargs); do
        # gebe aus welcher eintrag gefiltert wurde, cut begrenzt die maximale laenge auf 100 zeichen
        # jq "XXX", fügt XXX in ausgabe hinzu
        echo [INFO] Filtered entry "$i" - "$(curl --silent --header "X-Auth-Token: $MF_AUTH_TOKEN" "$MF_API_URL"/entries/"$i" | jq --join-output '"url: ",.feed.site_url," - title: ", .title' | cut -c -100)".
    done
    fi
    # setze variablen auf leer
    marked_entries=""
}



# Doing
case "$1" in
    --help | -h | help)
        output_help
        ;;
    *)
        check_dependencies
        check_connectivity
        # fuehre script durchgaengig aus
        while true; do
            check_vars
            debug_output
            get_unread_entries
            filter_entries
            mark_as_read
            # warte zeit x
            sleep $MF_SLEEP
        done
esac
