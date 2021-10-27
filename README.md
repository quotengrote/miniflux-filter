# miniflux-filter

<!-- TOC titleSize:3 tabSpaces:2 depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 skip:0 title:1 charForUnorderedList:* -->
### Table of Contents
* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [example docker-compose](#example-docker-compose)
  * [example filter-file](#example-filter-file)
* [Misc](#misc)
* [ToDo](#todo)
* [License](#license)
<!-- /TOC -->

### Introduction
``miniflux-filter`` is a small bash-script for [miniflux](https://miniflux.app) that marks certain articles as read if the search conditions met.

### Getting Started
1. create a [api-key](https://miniflux.app/docs/api.html#authentication) in miniflux
2. create a [compose-file](./docker-compose.yml)
3. create a [filter-file](./filter.txt)
4. ````docker-compose up````

#### example docker-compose
```
version: '3.2'
services:
  mf-filter:
    container_name: mf-filter
    restart: always
    environment:
      - TZ=Europe/Berlin
      - mf_auth_token=XN2klsvvD[...]-dcHPaeQ=
      - mf_api_url=https://miniflux.[...].net/v1
      - mf_sleep=60
      #- mf_debug_output=1
    image: quotengrote/miniflux-filter:latest
    volumes:
      - ./filter.txt:/data/filter.txt

```
#### example filter-file
```
<part_of_url>:<search string, anything goes, but not :>
sueddeutsche.de:FC Bayern
heise.de:software-architektur.tv
heise.de:heise-angebot
tagesschau.de:FC Barcelona
heise.de:TechStage |
[...]
```

## Misc
- [tborychowski/miniflux-filter](https://github.com/tborychowski/miniflux-filter)
- [jqplay.org](https://jqplay.org)


## ToDo
- [ ] search in content, not only title

## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](./LICENSE) file for details.
