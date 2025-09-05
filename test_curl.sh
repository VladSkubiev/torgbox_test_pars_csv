#!/bin/bash

set -euo pipefail

curl -s https://fsa.gov.ru/opendata/7736638268-rss/ > /torgbox/link.txt
link=$(grep -A2 "Гиперссылка" /torgbox/link.txt | grep https | cut -d '"' -f 2)
echo $link
rm -f /torgbox/link.txt
curl -so /torgbox/ftp_data/FSA_data/declaration/original/archive.7z  $link
#link=cat /home/user/Рабочий\ стол/link1.txt | grep Гиперссылка -A2

#echo | $link | grep -A2 Гиперссылка
#link=link | grep -A2 Гиперссылка

