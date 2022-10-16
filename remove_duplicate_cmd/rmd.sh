#!/bin/bash
#
# Recherche les fichiers identiques par leur contenu.

err() {
    echo "[$(date +'%Y-%m-%d')]: $*" >&2
}

usage() {
    echo -e "\nUse: ./$(basename "$0") file1 [file2] [file3] ... [filen]
               [-h] [-R] [-d] [-a dest_file] [-f {z | g | b | x}]\n"
    echo -e "Type:
    -h for help
    -R for recursive mode
    -d for dry-run mode
    -a for compress files before delete
    -f for using specific compression software (gzip default)\n"
}

bB='\e[94m\e[1m'
gB='\e[92m\e[1m'
r='\e[31m'
n='\e[0m'


### Gestion des paramètres
options=$(getopt -o hRqda:f: -l help -- "$@")

eval set -- "$options" # eval for remove simple quote

while true; do
    case "$1" in
        -h|--help) usage
            exit 0
            shift;;
        -q) exec &>/dev/null
            shift;;
        -R) recursive=true
            shift;;
        -d) dryrun=true
            shift;;
        -a) archive="$2"
            shift 2;;
        -f) case "$2" in
                z)  compression='zip'
                    shift 2;;
                g)  compression='gzip'
                    shift 2;;
                b)  compression='bzip2'
                    shift 2;;
                x)  compression='xz'
                    shift 2;;
                *)  err 'Bad arguments for -f, type -h' && exit 1
                    ;;
            esac;;
        --) shift
            break;;
        *)  err "Internal error"; exit 1
            shift;;
    esac 
done

[[ $# -lt 1 ]] && err 'Missing arguments, type -h' && exit 1


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

    if [ ${#NameRef[*]} -lt 2 ]; then
        echo -e "${bB}Fichier unique :${n} ${NameRef[*]}"
    else
        echo -e "${bB}Fichiers identiques :${n} ${NameRef[*]}"
    fi

    if [ ${#NameRef[*]} -gt 1 ]; then # Si fichiers identiques

        while read -r line; do 
            (( volume+=$line ))
            (( total_volume+=$line ))
        done <<< "$(stat -c "%s" ${NameRef[*]:1})"

        if [ $dryrun ]; then
            echo "Les fichiers suivants vont être supprimés : ${NameRef[*]:1}"
            echo "Un lien symbolique de ${NameRef[0]} sera établit vers ${NameRef[*]:1}"
            [ -v $archive ] || echo "Ajout des fichiers ${NameRef[*]:1} dans une archive nommée ${archive}.tar"
        else
            [ -v $archive ] || echo -e "${r}tar rf${n} : ${archive}.tar -> ${NameRef[*]:1}"

            for k in ${NameRef[*]:1}; do
                echo -e "${r}rm -f${n} -> $k"
                echo -e "${r}ln -rs${n} : ${NameRef[0]} -> $k"
            done

        fi

        echo -e "Volumétrie totale des doublons : $volume\n"
    fi
done

echo -e "${gB}"
if ! [ -v $archive ]; then
    case ${compression:-gzip} in
        zip) [ $dryrun ] && echo "Compression de ${archive}.tar avec zip" || zip ${archive}.tar
            ;;
        gzip) [ $dryrun ] && echo "Compression de ${archive}.tar avec gzip" || gzip ${archive}.tar 
            ;;
        bzip2) [ $dryrun ] && echo "Compression de ${archive}.tar avec bzip2" || bzip2 ${archive}.tar
            ;;
        xz) [ $dryrun ] && echo "Compression de ${archive}.tar avec xz" || xz ${archive}.tar
            ;;
        *) err "Internal error"; exit 1
            ;;
    esac
fi

echo -e "Volume total libéré : ${total_volume}o (volume de l'archive non déduit si option -a)\n"