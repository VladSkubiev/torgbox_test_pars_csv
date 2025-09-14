#!/bin/bash

# Функция для обработки 
process_data() {
    local url="$1"
    local type="$2"
    local source_dir="$3"
    local dest_dir="$4"
    
    local checksum_file="$source_dir/last_checksum_${type}.txt"
    
    echo "=== Обработка $type ==="
    echo "URL: $url"
    echo "Source: $source_dir"
    echo "Destination: $dest_dir"

    # Скачивание архива
    echo "Скачивание архива..."
    local link=$(curl -s "$url" | 
        grep -A2 "Гиперссылка" | 
        grep https | 
        cut -d '"' -f 2)
    
    if [ -z "$link" ]; then
        echo "Ошибка: не удалось получить ссылку для $type"
        return 1
    fi
    
    local arh=$(basename "$link")
    local archive_path="$source_dir/$arh"

    # Скачивание архива во временный файл для проверки
    local temp_archive="$source_dir/temp_$arh"
    if ! curl -s -o "$temp_archive" "$link"; then
        echo "Ошибка скачивания для $type"
        rm -f "$temp_archive"
        return 1
    fi

    # Проверяем изменения
    if [ -f "$archive_path" ]; then
        local old_checksum=$(sha256sum "$archive_path" 2>/dev/null | cut -d' ' -f1)
        local new_checksum=$(sha256sum "$temp_archive" | cut -d' ' -f1)
        
        if [ "$old_checksum" = "$new_checksum" ]; then
            echo "Данные $type не изменились. Пропуск."
            rm -f "$temp_archive"
            echo "=== Завершение обработки $type (данные не изменились) ==="
            return 0
        fi
    fi

    # JОбработка архива
    mv "$temp_archive" "$archive_path"
    local new_checksum=$(sha256sum "$archive_path" | cut -d' ' -f1)
    echo "$new_checksum" > "$checksum_file"
    
    echo "Обработка архива $type..."
    
    # Распаковка
    echo "Распаковка архива $type..."
    7z x -y "$archive_path" -o"$source_dir" > /dev/null

    # Поиск CSV
    local CSV_FILENAME=$(find "$source_dir" -maxdepth 1 -name "*.csv" -printf "%f\n" | head -1)
    local path="$source_dir/$CSV_FILENAME"
    echo "Обработка файла: $CSV_FILENAME"

    # Дата файлов для нейминга
    local file_date=$(date -r "$path" +"%Y%m%d")
    
    # Создание временной директории
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    echo "Создание JSON и архивация..."
    local batch_size=1000

    # Переход на awk вместо sed (тест на оптимизацию скорости)
    awk -F';' -v type="$type" -v batch_size="$batch_size" -v source_dir="$source_dir" -v file_date="$file_date" '
    BEGIN {
        # Чтение загаловка
        getline
        for (i=1; i<=NF; i++) {
            gsub(/[\r"]/, "", $i)
            headers[i] = $i
        }
        header_count = NF
        file_counter = 0
        archive_count = 0
        total_lines = 0
    }
    {
        total_lines++
        if (total_lines % 10000 == 0) {
            printf "Обработано строк: %d\n", total_lines > "/dev/stderr"
        }
        
        # Создание JSON
        file_counter++
        json_file = sprintf("%s_%s_%06d.json", type, file_date, file_counter)
        printf "{\n" > json_file
        
        for (i=1; i<=NF; i++) {
            # Отчистка
            value = $i
            gsub(/["\\]/, "", value)
            gsub(/\n/, " ", value)
            gsub(/\r/, " ", value)
            
            printf "  \"%s\": \"%s\"", headers[i], value > json_file
            if (i < NF) printf "," > json_file
            printf "\n" > json_file
        }
        
        printf ",\n  \"_type\": \"%s\"\n}\n", type > json_file
        close(json_file)
        
        # Архивация
        if (file_counter % batch_size == 0) {
            archive_count++
            archive_name = type "_" file_date "_" archive_count ".7z"
            
            # Архивация всех JSON текущего батча
            cmd = "7z a -y " source_dir "/" archive_name " " type "_" file_date "_*.json > /dev/null 2>&1"
            system(cmd)
            
            # Удаление временных JSON 
            cmd = "rm -f " type "_" file_date "_*.json"
            system(cmd)
            
            printf "Архивировано: %d строк в %s\n", total_lines, archive_name > "/dev/stderr"
        }
    }
    END {
        # Архивация остатка
        if (file_counter % batch_size != 0) {
            archive_count++
            archive_name = type "_" file_date "_" archive_count ".7z"
            
            cmd = "7z a -y " source_dir "/" archive_name " " type "_" file_date "_*.json > /dev/null 2>&1"
            system(cmd)
            
            cmd = "rm -f " type "_" file_date "_*.json"
            system(cmd)
        }
        printf "Всего обработано: %d строк, создано архивов: %d\n", total_lines, archive_count > "/dev/stderr"
    }
    ' "$path"
    
    echo "Всего обработано строк: $(wc -l < "$path" | awk '{print $1-1}')"
    
    # Отчистка
    cd - >/dev/null
    rm -rf "$temp_dir"

    # Удаление CSV
    rm -f "$path"

    # Перемещение архивов по годам
    echo "Распределение архивов $type по годам..."
    
    for archive in "$source_dir/${type}_${file_date}"_*.7z; do
        [ -f "$archive" ] || continue
        
        # Получение даты создания архива
        local FILE_DATE=$(stat -c %y "$archive")
        local YEAR=$(date -d "$FILE_DATE" +"%Y")
        local YEAR_DIR="$dest_dir/$YEAR"
        
        # Создание директории года если не существует
        mkdir -p "$YEAR_DIR"
        
        # Перемещение архива
        mv "$archive" "$YEAR_DIR/"
        
        echo "Перемещен: $(basename "$archive") -> $YEAR_DIR/"
    done
    
    echo "=== Успешное завершение обработки $type ==="
    return 0
}

# Вызов функции с параметрами для сертификатов и деклараций
echo "Начало обработки всех данных..."

# Параметры для деклараций
process_data \
    "https://fsa.gov.ru/opendata/7736638268-rds/" \
    "declaration" \
    "/torgbox/ftp_data/FSA_data/declaration/original/" \
    "/torgbox/ftp_data/FSA_data/declaration"

# Параметры для сертификатов
process_data \
    "https://fsa.gov.ru/opendata/7736638268-rss/" \
    "certificate" \
    "/torgbox/ftp_data/FSA_data/certificate/original/" \
    "/torgbox/ftp_data/FSA_data/certificate"

echo "Вся обработка завершена!"
