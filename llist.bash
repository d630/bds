#!/usr/bin/env bash

Llist ()
{
        builtin local -
        # builtin set -o pipefail
        # builtin set -o errexit
        builtin set -o errtrace
        # builtin set -o nounset

        builtin trap '
                builtin trap -- - RETURN;
                status=$? __.cleanup
        ' RETURN;

        function __.addNodeAfter {
                # USAGE: __.addNodeAfter INDEX [ELEMENT]

                builtin declare -i index=$1
                builtin shift 1

                builtin declare name="${!list}_$((${list[id]} + 1))"
                builtin declare -g -A "${name}=()"
                builtin declare -n newNode=${name}
                newNode[data]=$*
                list[id]=$((${list[id]} + 1))

                builtin declare -n node=${nodes[$index]}
                newNode[next]=${node[next]}
                newNode[prev]=${!node}
                node[next]=$name

                if
                        ((${#nodes[@]} == index + 1))
                then
                        nodes+=("$name")
                else
                        nodes=(
                                "${nodes[@]:0:index+1}"
                                "$name"
                                "${nodes[@]:index+1}"
                        )
                        # builtin declare i ii
                        # builtin declare -a t
                        # t=("${nodes[@]}")
                        # for ((i=0, ii=index+1; i < ii; i++))
                        # do
                        #         builtin unset -v "t[$i]"
                        # done
                        # for ((i=index+1, ii=${#nodes[@]}; i <= ii; i++))
                        # do
                        #         builtin unset -v "nodes[$i]"
                        # done
                        # nodes+=("$name" "${t[@]}")
                fi
        }

        function __.addNodeHead {
                # USAGE: __.addNodeHead [ELEMENT]

                builtin declare name="${!list}_$((${list[id]} + 1))"
                builtin declare -g -A "${name}=([prev]=NULL)"
                builtin declare -n newNode=${name}
                newNode[data]=$*
                list[id]=$((${list[id]} + 1))

                if
                        ((${#nodes[@]}))
                then
                        newNode[next]=${nodes[0]}
                        builtin declare -n node=${nodes[0]}
                        node[prev]=$name
                        nodes=("$name" "${nodes[@]}")
                else
                        newNode[next]=NULL
                        nodes[0]=$name
                fi
        }

        function __.cleanup {
                builtin unset -f \
                        __.{addNode{After,Head},removeNode{After,Head},cleanup,usage} \
                        Llist.{append,index,insert,length,range,replace} \
                        Llist.{set,traverse,unset;
        }

        function __.removeNodeAfter {
                # USAGE: __.removeNodeAfter INDEX

                builtin declare -i index=$1

                builtin declare -n prevNode=${nodes[$index]}
                builtin declare -n node=${nodes[$index + 1]}

                if
                        ! [[ ${node[next]} == NULL ]]
                then
                        builtin declare -n nextNode=${node[next]}
                        nextNode[prev]=${node[prev]}
                fi
                prevNode[next]=${node[next]}
                builtin unset -v "${!node}"

                builtin unset -v "nodes[$index + 1]"
                nodes=("${nodes[@]}")
        }

        function __.removeNodeHead {
                # USAGE: __.removeNodeHead

                case ${#nodes[@]} in
                0)
                        builtin return 1
                ;;
                1)
                        builtin unset -v "${nodes[0]}"
                        nodes=()
                ;;
                *)
                        builtin declare -n nextNode=${nodes[1]}
                        nextNode[prev]=NULL
                        builtin unset -v "${nodes[0]}"
                        builtin unset -v "nodes[0]"
                        nodes=("${nodes[@]}")
                esac
        }

        function __.usage
        {
                builtin declare -A "u=(
                        [append]='[element ...]'
                        [index]='[index]'
                        [insert]='index [element ...]'
                        [length]='[-t]'
                        [range]='[-r] first last'
                        [replace]='first last [element ...]'
                        [set]='[element ...]'
                        [traverse]='[-r] index'
                        [unset]=''
                )"

                builtin printf 'usage: %s %s lname %s\n' "${FUNCNAME[1]}" "$1" "${u[$1]}" 1>&2;
        }

        function Llist.append {
                Llist.insert "${#nodes[@]}" "$@"
        }

        function Llist.index {
                if
                        (($#))
                then
                        builtin declare -i index=$1
                        if
                                [[ -v ${nodes[$index]}[data] ]] 2>/dev/null;
                        then
                                builtin declare -n node=${nodes[$index]}
                                builtin printf '%s\n' "${node[data]@Q}"
                        else
                                builtin return 1
                        fi
                else
                        Llist.range 0 ${#nodes[@]}
                fi
        }

        function Llist.insert {
                builtin declare -i index=$1
                builtin shift 1

                case $index in
                0|-[0-9]*)
                        builtin declare e
                        for ((e=$#; e > 0; e--))
                        do
                                __.addNodeHead "${@:e:1}" || builtin return 1;
                        done
                ;;
                *)
                        ((index > ${#nodes[@]})) && builtin return 1;
                        builtin declare e i
                        for ((e=$#, i=index-1; e > 0; e--))
                        do
                                __.addNodeAfter "$i" "${@:e:1}" || \
                                        builtin return 1;
                        done
                esac
        }

        function Llist.length {
                case ${1#-} in
                t)
                        builtin declare -a "t=()"
                        builtin mapfile -t t < <(
                                Llist.traverse 0
                        )
                        builtin printf '%d\n' "${#t[@]}"
                ;;
                *)
                        builtin printf '%d\n' "${#nodes[@]}"
                esac
        }

        function Llist.range {
                builtin declare -i rev=0

                [[ $1 == -r ]] && builtin declare rev=1 && builtin shift 1;
                builtin declare -i \
                        first=$1 \
                        last=$2;

                ((
                        first = first < 0 ? 0 : first,

                        last =
                        last == -1 || last >= ${#nodes[@]}
                        ? ${#nodes[@]}-1
                        : last
                ))

                ((first > last)) && builtin return 1;

                builtin declare n
                if
                        ((rev))
                then
                        for ((n=last; n >= first; n--))
                        do
                                if
                                        builtin declare -n node=${nodes[$n]}
                                then
                                        builtin printf '%s ' "${node[data]@Q}"
                                fi
                        done
                else
                        for ((n=first; n <= last; n++))
                        do
                                if
                                        builtin declare -n node=${nodes[$n]}
                                then
                                        builtin printf '%s ' "${node[data]@Q}"
                                fi
                        done
                fi
                builtin printf '%s\n'
        }

        function Llist.replace {
                builtin declare -i \
                        first=$1 \
                        last=$2;
                builtin shift 2
                case $first in
                0|-[0-9]*)
                        case $last in
                        -[0-9]*)
                                first=0
                        ;;
                        0)
                                __.removeNodeHead || builtin return 1;
                        ;;
                        *)
                                builtin declare e
                                for ((e = last > ${#nodes[@]} ? ${#nodes[@]} : last; e >= 0; e--))
                                do
                                        __.removeNodeHead || builtin return 1;
                                done
                        esac
                ;;
                *)
                        ((first > ${#nodes[@]})) && return 1;
                        case $last in
                        -[0-9]*)
                                :
                        ;;
                        0)
                                __.removeNodeAfter "$((first - 1))" || \
                                        builtin return 1;
                        ;;
                        *)
                                builtin declare e f
                                for ((e = last > ${#nodes[@]} ? ${#nodes[@]} : last, f=first-1; e >= f ; e--))
                                do
                                        __.removeNodeAfter \
                                                "$((first - 1 + e))" || \
                                                builtin return 1;
                                done
                        esac
                esac

                Llist.insert "$first" "$@"
        }

        function Llist.set {
                builtin declare -n list=$1
                builtin declare -n nodes=${1}_idx

                Llist.unset

                builtin declare -g -A "${!list}=(
                        [type]=llist
                        [nodes]='${!list}_idx'
                        [id]=-1
                )"
                builtin declare -g -a "${!nodes}=()"

                builtin shift 1
                Llist.insert 0 "$@"
        }

        function Llist.traverse {
                builtin declare link=next
                [[ $1 == -r ]] && link=prev && builtin shift 1;

                if
                        ! builtin declare -n node=${nodes[$1]} 2>/dev/null;
                then
                        builtin printf '%s: index does not exist\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi

                while
                        [[ -v node[$link] ]]
                do
                        builtin printf '%s[data] := %q\n' "${!node}" "${node[data]}"
                        builtin declare -n node=${node[$link]}
                done
        }

        function Llist.unset {
                builtin unset -v "${!list}"

                builtin declare -i n
                if
                        ((${#nodes[@]}))
                then
                        for ((n=${#nodes[@]}-1; n > -1; n--))
                        do
                                builtin unset -v "${nodes[$n]}"
                        done
                fi
        }

        builtin declare op=$1
        builtin shift 1 2>/dev/null;

        builtin declare -i a
        case $op in
        (append) a="$# >= 1" ;;
        (index) a="$# >= 1" ;;
        (insert) a="$# >= 2" ;;
        (length) a="$# >= 1" ;;
        (range) a="$# >= 3" ;;
        (replace) a="$# >= 3" ;;
        (traverse) a="$# >= 2" ;;
        (unset) a="$# == 1" ;;
        (set)
                if
                        (($#))
                then
                        "${FUNCNAME}.${op}" "$@"
                        builtin return $?
                else
                        a=0
                fi
        ;;
        (*)
                builtin printf '%s: need an operation\n' "$FUNCNAME" 1>&2;
                builtin return 1
        esac

        if
                ((a))
        then
                if
                        [[ -v ${1}[type] ]]
                then
                        builtin declare -n list=$1
                        builtin declare -n nodes=${1}_idx
                else
                        builtin printf '%s: %s is not a list\n' \
                                "$FUNCNAME" \
                                "$1" 1>&2;
                        builtin return 1
                fi
                "${FUNCNAME}.${op}" "${@:2}"
        else
                __.usage "$op"
                builtin return 1
        fi
}

# vim: set ts=8 sw=8 tw=0 et :
