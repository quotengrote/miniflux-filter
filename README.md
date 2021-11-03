# miniflux-filter

<!-- TOC titleSize:3 tabSpaces:2 depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 skip:0 title:1 charForUnorderedList:* -->
### Table of Contents
* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [example docker-compose](#example-docker-compose)
  * [example filter-file](#example-filter-file)
* [Misc](#misc)
* [Debug](#debug)
  * [Exit-Codes](#exit-codes)
* [Build Container](#build-container)
* [License](#license)
<!-- /TOC -->

### Introduction
``miniflux-filter`` is a small bash-script for [miniflux](https://miniflux.app) that marks certain articles as read, if the search conditions are met.

### Getting Started
1. create an [api-key](https://miniflux.app/docs/api.html#authentication) in miniflux
2. create a [compose-file](./docker-compose.yml)
3. create a [filter-file](./filter.txt)
4. ````docker-compose up````

#### example docker-compose
```yaml
version: '3.2'
services:
  mf-filter:
    container_name: mf-filter
    restart: always
    environment:
      - TZ=Europe/Berlin
      - MF_AUTH_TOKEN=XN2klsvvD[...]-dcHPaeQ=
      - MF_API_URL=https://miniflux.[...].net/v1
      - MF_SLEEP=60
      #- MF_DEBUG=1
    image: quotengrote/miniflux-filter:latest
    volumes:
      - ./filter.txt:/data/filter.txt

```
#### example filter-file
  * Format: `url::search`
  * case-insensitive

```ini
<part_of_url>::<search string, anything goes>
sueddeutsche.de::FC Bayern
heise.de::software-architektur.tv
heise.de::heise-angebot
tagesschau.de::FC Barcelona
heise.de::TechStage |
[...]
```

## Misc
- [tborychowski/miniflux-filter](https://github.com/tborychowski/miniflux-filter)
- [jqplay.org](https://jqplay.org)

### Debug
If `MF_DEBUG` is set to `1`, `miniflux-filter`  will print extra output to stdout.
- the current Variable
- URL + Values for filtering
- almost all function calls

#### Exit-Codes
| RC | Description |
| -- | -- |
| 1 | `$MF_FILTERLIST_FILE` not found |
| 2 | `$MF_AUTH_TOKEN` not set |
| 3 | `$MF_API_URL` not set |
| 4 | `$MF_FILTERLIST_FILE` is a dir |
| 5 | `jq` is not installed |
| 6 | `curl` is not installed |
| 7 | could not connect to `miniflux` |
| 8 | `xargs` is not installed |
| 9 | `sed` is not installed |
| 10 | `sort` is not installed |
| 11 | `awk` is not installed |

## Build Container
```shell
git clone https://git.mgrote.net/mg/miniflux-filter
cd miniflux-filter
export MF_DOCKERHUB_PASS=<your_docker_hub_pass>
export MF_DOCKERHUB_USER=<your_docker_hub_user>
./build.sh
```


## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](./LICENSE) file for details.
