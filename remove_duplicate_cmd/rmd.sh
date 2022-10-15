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


[[ $# -lt 1 ]] && err 'Missing arguments, type -h' && exit 1


### Gestion des paramètres
options=$(getopt -o hRqd -l help -- "$@")

eval set -- "$options" # eval for remove simple quote

while true; do
    case "$1" in 
        -R) recursive=true
            shift;;
        -h|--help) usage
            exit 0
            shift;;
        -q) exec &>/dev/null
            shift;;
        -d) dryrun=true
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
    for file in "$@"; do
        array_file+=($(find $file -type f | tr '\n' ' '))
    done
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
for (( i=0 ; i<"$I" ; i++ )); do # Pour tous les hash différents
    tab_result="tab_$i"
    declare -n NameRef="$tab_result"
    loop=0
    volume=0

    for (( j=0 ; j<"$J" ; j+=2 )); do # Pour tous les hashs
        if [ "${array_hash_uniq[$i]}" = "${array_hash_file[$j]}" ]; then
            NameRef[$loop]+=${array_hash_file[(( $j + 1 ))]}
            (( loop++ ))
        fi
    done
    echo "Fichiers identiques : ${NameRef[*]}"

    if [ ${#NameRef[*]} -gt 1 ]; then # Si fichiers identiques

        while read -r line; do 
            (( volume+=$line ))
            (( total_volume+=$line ))
        done <<< "$(stat -c "%s" ${NameRef[*]:1})"

        if [ $dryrun ]; then
            echo "Les fichiers suivants vont être supprimés : ${NameRef[*]:1}"
            echo "Un lien symbolique de ${NameRef[0]} sera établit vers ${NameRef[*]:1}"
        else
            for k in ${NameRef[*]:1}; do
                echo "rm --> $k"
                echo "symlink from ${NameRef[0]} to $k"
            done
        fi

        echo -e "Volumétrie totale des doublons : $volume\n"
    fi
done

echo -e "\nVolume total libéré : ${total_volume}o"