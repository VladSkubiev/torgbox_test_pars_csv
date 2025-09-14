#!/bin/bash

#путь к директории
path_declar_original="/torgbox/ftp_data/FSA_data/declaration/original/"
DESTINATION_DIR="/torgbox/ftp_data/FSA_data/declaration"
echo $path_declar_original
curl -s https://fsa.gov.ru/opendata/7736638268-rds/ > /torgbox/link.txt
link=$(grep -A2 "Гиперссылка" /torgbox/link.txt | grep https | cut -d '"' -f 2)
echo "Ссылка для скачивания архива: $link"
rm -f /torgbox/link.txt
cd $path_declar_original && curl -O  $link


arh=$(basename $link)
echo $arh  
# Путь к архиву
archive_path="/torgbox/ftp_data/FSA_data/declaration/original/${arh}"
echo $archive_path

#Распаковка
7z x "$archive_path"
csv_files=$(find . -maxdepth 1 -type f -name "*.csv")
CSV_FILENAME=$(basename "$(echo "$csv_files" | head -1)")
echo "Архив распакован. CSV файл: $CSV_FILENAME"
rm -f *.7z

path=/torgbox/ftp_data/FSA_data/declaration/original/${CSV_FILENAME}
column_count=$(awk -F';' 'NR==1{print NF; exit}' $path)
file_date=$(date -r $path +"%Y%m%d")
type="declaration"
count_arh=0
count_json=0


#Подсчет строк в файале
str_count=$(tail -n +1 $path | wc -l)
str_head=$(sed -n '1p' $path | tr -d '\r"'\')
IFS=';' read -ra array_head <<< "$str_head"
echo "Строк в CSV файле: $str_count"

# Основной цикл
for ((i=2; i<=str_count; i++))
do
    # Чтение и обработка строки
    str_obj=$(sed -n "${i}p" "$path" | tr -d '\r"'\')
    IFS=';' read -ra array_obj <<< "$str_obj"
    
    # Формирование JSON с дополнительным полем _type
    json_content="{"
    for ((x=0; x<column_count; x++))
    do
        if ((x > 0)); then
            json_content+=","
        fi
        json_content+="\"${array_head[x]}\":\"${array_obj[x]}\""
    done
    # Добавление поля _type 
    json_content+=",\"_type\":\"$type\""
    json_content+="}"
    
    # Создание JSON файла
    echo "$json_content" | jq . > "${type}_${file_date}_$((i-1)).json"
    count_json=$((count_json + 1))
    echo "Создано файлов JSON: $((i-1))"
    if ((count_json % 1000 == 0)); then
        count_arh=$((count_arh + 1))
        7z a "${type}_${file_date}_${count_arh}.7z" *.json > /dev/null 2>&1
        rm -f *.json
    fi
done
#Упаковка последнего архива   
7z a "${type}_${file_date}_${count_arh}.7z" *.json > /dev/null
rm -f *.json

# Обрабатываем все файлы 7z
for archive in "$path_declar_original"/*.7z; do
    
    #извлечение года создания
    FILE_DATE=$(stat -c %y "$archive")
    YEAR=$(date -d "$FILE_DATE" +"%Y")
    YEAR_DIR="$DESTINATION_DIR/$YEAR"
  
    # Проверка и создание директории
    if [ ! -d "$YEAR_DIR" ]; then
        mkdir -p "$YEAR_DIR"
        echo "Создана папка: $YEAR_DIR"
    fi
    
    # Перенос
    mv "$archive" "$YEAR_DIR/"
    echo "Перемещен: $(basename "$archive") -> $YEAR_DIR/"
done
#_____________________________________________________________________________________________


#путь к директории
path_cert_original="/torgbox/ftp_data/FSA_data/certificate/original/"
DESTINATION_DIR="/torgbox/ftp_data/FSA_data/certificate"
echo $path_cert_original
curl -s https://fsa.gov.ru/opendata/7736638268-rss/ > /torgbox/link.txt
link=$(grep -A2 "Гиперссылка" /torgbox/link.txt | grep https | cut -d '"' -f 2)
echo "Ссылка для скачивания архива: $link"
rm -f /torgbox/link.txt
cd $path_cert_original && curl -O  $link


arh=$(basename $link)
echo $arh  
# Путь к архиву
archive_path="/torgbox/ftp_data/FSA_data/certificate/original/${arh}"
echo $archive_path

#Распаковка
7z x "$archive_path"
csv_files=$(find . -maxdepth 1 -type f -name "*.csv")
CSV_FILENAME=$(basename "$(echo "$csv_files" | head -1)")
echo "Архив распакован. CSV файл: $CSV_FILENAME"
rm -f *.7z

path=/torgbox/ftp_data/FSA_data/certificate/original/${CSV_FILENAME}
column_count=$(awk -F';' 'NR==1{print NF; exit}' $path)
file_date=$(date -r $path +"%Y%m%d")
type="certificate"
count_arh=0
count_json=0


#Подсчет строк в файале
str_count=$(tail -n +1 $path | wc -l)
str_head=$(sed -n '1p' $path | tr -d '\r"'\')
IFS=';' read -ra array_head <<< "$str_head"
echo "Строк в CSV файле: $str_count"

# Основной цикл
for ((i=2; i<=str_count; i++))
do
    # Чтение и обработка строки
    str_obj=$(sed -n "${i}p" "$path" | tr -d '\r"'\')
    IFS=';' read -ra array_obj <<< "$str_obj"
    
    # Формирование JSON с дополнительным полем _type
    json_content="{"
    for ((x=0; x<column_count; x++))
    do
        if ((x > 0)); then
            json_content+=","
        fi
        json_content+="\"${array_head[x]}\":\"${array_obj[x]}\""
    done
    # Добавление поля _type 
    json_content+=",\"_type\":\"$type\""
    json_content+="}"
    
    # Создание JSON файла
    echo "$json_content" | jq . > "${type}_${file_date}_$((i-1)).json"
    count_json=$((count_json + 1))
    echo "Создано файлов JSON: $((i-1))"
    if ((count_json % 1000 == 0)); then
        count_arh=$((count_arh + 1))
        7z a "${type}_${file_date}_${count_arh}.7z" *.json > /dev/null 2>&1
        rm -f *.json
    fi
done
#Упаковка последнего архива   
7z a "${type}_${file_date}_${count_arh}.7z" *.json > /dev/null
rm -f *.json

# Обрабатываем все файлы 7z
for archive in "$path_cert_original"/*.7z; do
    
    #извлечение года создания
    FILE_DATE=$(stat -c %y "$archive")
    YEAR=$(date -d "$FILE_DATE" +"%Y")
    YEAR_DIR="$DESTINATION_DIR/$YEAR"
  
    # Проверка и создание директории
    if [ ! -d "$YEAR_DIR" ]; then
        mkdir -p "$YEAR_DIR"
        echo "Создана папка: $YEAR_DIR"
    fi
    
    # Перенос
    mv "$archive" "$YEAR_DIR/"
    echo "Перемещен: $(basename "$archive") -> $YEAR_DIR/"
done