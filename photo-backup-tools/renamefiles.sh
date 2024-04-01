#!/usr/bin/env bash

echo "Current directory: $(pwd)"
read -p "Please enter suffix for filename: " fprefix

>tmp.sh

for i in $(ls|tr " " "=")
do
oud=$(echo $i|tr "=" "  ")
if [[ ! $oud == "tmp.sh" ]]; then
new=$(echo $i|tr "=" "_"|sed "s/ /_/g"|tr -d ')' | tr -d '(' )
echo "mv \"$oud\" ${fprefix}_\"$new\"" >> tmp.sh
fi
done 
echo "-- Rename script generated ./tmp/sh"
