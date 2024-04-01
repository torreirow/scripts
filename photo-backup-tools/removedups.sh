#!/usr/bin/env bash
#

function removequotes() {
 sed -i "s/\"//g" $csv_file
} 

# Functie om de csv-bestanden te lezen en te verwerken met behulp van Awk
process_csv_with_awk() {
    awk -F', ' '{ printf "ID: %s\nFiles:\n", $1; for(i=2; i<=NF; i++) { if(i >= 3) { print $i } } print "--------------------" }' "$1"
}

process_csv_with_awk_script() {
       awk -F', ' '{ for(i=3; i<=NF; i++) { print $i } }' "$1" > $1.sh 
}
# Main
echo "Geef het pad naar het CSV-bestand:"
read -r csv_file
if [[ ! -f "$csv_file" ]]; then
    echo "Het opgegeven bestand bestaat niet."
    exit 1
fi

removequotes "$csv_file"
process_csv_with_awk "$csv_file"
process_csv_with_awk_script "$csv_file"
