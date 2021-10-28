#!/bin/bash

printf "miniflux-filter - git.mgrote.net/mg/miniflux-filter\n"

## Beispiel-Variablen
###  werden in jedem durchlauf neu eingelesen, script muss also nicht neugestartet werden fur filteraenderungen
### miniflux api key
### export mf_auth_token="XN2klsvvDUKf[...]dcHPaeQ="
### minuflux url
### export mf_api_url="https://miniflux.[...].net/v1"
### datei mit filter ausdruecken
mf_filterlist_file="${mf_filterlist_file:=/data/filter.txt}"
### wartezeit zwischen durchlaeufen
mf_sleep="${mf_sleep:=30}"
### mf_debug_output output
# standardmäßig 0 = aus
mf_debug_output="${mf_debug_output:=0}"
### zaehlvariable
n=1
anzahl="0"

function debug_output {
  echo Filterlist-File: $mf_filterlist_file
  echo Sleep-Intervall: $mf_sleep
  echo Auth-Token: $mf_auth_token
  echo MF-Url: $mf_api_url
  echo Anzahl Filter: $(wc -l $mf_filterlist_file)
}

function check_vars {
  # pruefe ob alle vars gesetzt sind
  if [[ -z "${mf_auth_token}" ]]; then
    echo '"$mf_auth_token"' not set.
    exit 2
  fi
  if [[ -z "${mf_api_url}" ]]; then
    echo '"$mf_api_url"' not set.
    exit 3
  fi
  # pruefe ob filter-datei NICHT existiert
  if [ ! -e "$mf_filterlist_file" ]; then
    echo "$mf_filterlist_file" not readable!
    exit 1
  fi
}
function filter_entries {
  echo "Checking filters..."
  # fuer jede Zeile in $mf_filterlist_file
  while read -r line; do
    # setze $url auf den Wert vor dem Trennzeichen/Delimiter, ersetze alle Grossschreibungen durch Kleinschreibung
    url=$(echo "$line" | tr '[:upper:]' '[:lower:]' | cut --delimiter=: --field=1)
    # setze $suchbegriff auf den Wert vor dem Trennzeichen/Delimiter, ersetze alle Grossschreibungen durch Kleinschreibung
    suchbegriff=$(echo "$line" | tr '[:upper:]' '[:lower:]' | cut --delimiter=: --field=2)
    # hole alle ungelesenen eintraege von miniflux, pipe an jq
    # in jq uebergebe shell-variablen an jq selber
    # entferne die erste ebene
    # suche jeden eintrag wo die feed_url == $url, konvertiere in kleinschreibung, das selbe fur den title
    # gebe dann nur die id aus
    # die id, wird dann an die variable marked_entries angehangen
    # z.B. 53443 52332 48787 [...]
    if [[ -n "$url" ]]; then
      # abfangen der letzten zeile die leer ist; sonst wird alles gefiltert
      if [[ -n "$suchbegriff" ]]; then
        # abfangen der letzten zeile die leer ist; sonst wird alles gefiltert
        if [[ $mf_debug_output -eq 1 ]]; then
          echo URL "$url" - Suchbegriff: "$suchbegriff"
        fi
        marked_entries+=" $(curl --silent --header "X-Auth-Token: $mf_auth_token" "$mf_api_url/entries?status=unread&limit=0" | jq --arg url "$url" --arg suchbegriff "$suchbegriff" '.entries[] | select(.feed.site_url | ascii_downcase | contains($url)) | select(.title | ascii_downcase | contains($suchbegriff)) | .id' )"
      fi
    fi
    # erhoehe die zaehlvariable
    n=$((n+1))
  done < "$mf_filterlist_file"
}
function mark_as_read {
  # fuer jede zahl(leerzeichen-getrennt) in $marked_entries
  # sende in put request mit curl
  # der wert muss escaped werden, aber NICHT die variable die uebergeben wird
  for i in $marked_entries; do
    anzahl=$((anzahl+1))
    curl --request PUT --silent --header "X-Auth-Token: $mf_auth_token" --header "Content-Type: application/json" --data "{\"entry_ids\": [$i], \"status\": \"read\"}" "$mf_api_url/entries"
    # gebe aus welcher eintrag gefilter wurde, cur begrenzt die maximale laenge auf 40 zeichen
    echo Filtered entry "$i" - "$(curl --silent --header "X-Auth-Token: $mf_auth_token" $mf_api_url/entries/"$i" | jq .title | cut -c -70)".
  done
  # gebe gesamzzahl gefilterter item aus
  if [ "$anzahl" -eq "1" ]; then
    echo "$anzahl" entry got filtered.
  fi
  if [ "$anzahl" -gt "1" ]; then
    echo "$anzahl" entries got filtered.
  fi
  # setze variablen auf leer
  marked_entries=""
  anzahl="0"
}
function check_dependencies {
  # pruefe ob jq installiert ist
  # https://stackoverflow.com/questions/592620/how-can-i-check-if-a-program-exists-from-a-bash-script
  if ! command -v jq &> /dev/null
  then
    echo "jq could not be found!"
    exit 5
  fi
  if ! command -v curl &> /dev/null
  then
    echo "curl could not be found!"
    exit 6
  fi
}


# fuehre script durchgaengig aus
check_dependencies
while true; do
  check_vars
  if [[ $mf_debug_output -eq 1 ]]; then
    debug_output
  fi
  filter_entries
  mark_as_read
  # warte zeit x
  sleep $mf_sleep
done




# Exit-Code
# 1 - Filter-Datei nicht gefunden
# 2 - mf_auth_token nicht gesetzt
# 3 - mf_api_url nicht gesetzt
# 5 - jq ist nicht installiert
# 6 - curl ist nicht installiert
