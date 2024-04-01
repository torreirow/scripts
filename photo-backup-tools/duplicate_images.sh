#!/bin/bash

# Vraag om het invoerbestand
read -p "Geef de naam van het invoerbestand: " input_file

# Controleer of het invoerbestand bestaat
if [[ ! -f $input_file ]]; then
    echo "Fout: Het opgegeven invoerbestand bestaat niet."
    exit 1
fi

# Genereer de naam van het uitvoerbestand met datum en tijd
output_file="duplicate_files_$(date +"%Y%m%d_%H%M%S").txt"

# Maak een array met unieke md5sum hashes
declare -A md5sums

# Lees de inputregels en sla md5sum en bestandsnaam op in de array
while read -r line; do
    # De hash is het eerste gedeelte van de regel
    hash=$(echo "$line" | awk '{print $1}')
    # De bestandsnaam is het tweede gedeelte van de regel
    filename=$(echo "$line" | awk '{print $2}')

    # Controleer of de hash al in de array zit
    if [[ -n ${md5sums["$hash"]} ]]; then
        # Als de hash al bestaat, voeg de huidige bestandsnaam toe aan de lijst met bestandsnamen voor die hash
        md5sums["$hash"]+=" $filename"
    else
        # Als de hash nog niet bestaat, voeg een nieuwe invoer toe aan de array
        md5sums["$hash"]="$filename"
    fi
done < "$input_file"

# Schrijf de resultaten naar het uitvoerbestand
echo "Bestanden met dezelfde md5sum hash:" > "$output_file"
for hash in "${!md5sums[@]}"; do
    # Als er meer dan één bestand is met dezelfde hash, schrijf deze bestanden naar het uitvoerbestand
    if [[ $(echo "${md5sums[$hash]}" | wc -w) -gt 1 ]]; then
        # Verwijder het eerste element van elke regel
        filenames=$(echo "${md5sums[$hash]}" | awk '{$1=""; print $0}')

        echo "$filenames" >> "$output_file"
        echo "" >> "$output_file"
    fi
done

echo "Het resultaat is opgeslagen in $output_file"

