#!/bin/bash
#
# Recherche les fichiers identiques par leur contenu.

err() {
    echo "[$(date +'%Y-%m-%d')]: $*" >&2
}

usage() {
    echo -e "\nUse: ./$(basename "$0") file1 [file2] [file3] ... [filen]\n"
    echo -e "Type:\n   -h for help\n   -R for recursive mode\n"
}

recursive_mode() {
    for file in "$@"; do
        array_file+=($(find $file -type f | tr '\n' ' '))
    done
}

[[ $# -lt 1 ]] && err 'Missing arguments, type -h' && exit 1


### Gestion des paramètres
options=$(getopt -o hR -l help -- "$@")

eval set -- "$options" # eval for remove simple quote

while true; do
    case "$1" in 
        -R) recursive=true
            shift;;
        -h|--help) usage
            exit 0
            shift;;
        --)
            shift
            break;;
        *) usage;
            shift;;
    esac 
done


### Création des variables
if [ $recursive ]; then
    recursive_mode $*
    set "${array_file[@]}"
fi

sha=$(sha256sum $*)

while read -r line; do 
    array_hash_file+=($(echo "$line" | awk '{ print $1 }'))
    array_hash_file+=($(echo "$line" | awk '{ print $2 }'))
done <<< "${sha}"

while read -r line; do 
    array_hash_uniq[${#array_hash_uniq[@]}]=$line
done <<< "$(echo "$sha" | awk '{ print $1 }' | sort -u)"

J=$(($# * 2))
I=${#array_hash_uniq[*]}


### Algorithme
for (( i=0 ; i<"$I" ; i++ )); do
    tab_result="tab_$i"
    declare -n NameRef="$tab_result"

    for (( j=0 ; j<"$J" ; j+=2 )); do
        if [ "${array_hash_uniq[$i]}" = "${array_hash_file[$j]}" ]; then
            (( loop++ ))
            NameRef[$loop]+=$(basename "${array_hash_file[(( $j + 1 ))]}")
        fi
    done
    echo "${NameRef[*]}"
done
