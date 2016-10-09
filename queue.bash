#!/usr/bin/env bash

Queue ()
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

        function Queue.set {
                if
                        (($#))
                then
                        builtin declare name=$1
                        builtin unset -v "$name"
                else
                        builtin printf '%s: need a name\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi

                builtin declare -g -A "${name}=(
                        [type]=queue
                        [first]=0
                        [last]=-1
                )"
        }

        function Queue.popl {
                if
                        (($#))
                then
                        builtin declare -n queue=$1
                        builtin declare -i first=queue[first]
                else
                        builtin printf '%s: need a name\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi

                if
                        ((queue[last] < first))
                then
                        builtin printf '%s\n' "queue is empty" 1>&2;
                        builtin return 1
                else
                        builtin declare value=${queue[$first]}
                        builtin unset -v "queue[$first]"
                        ((queue[first] = first + 1))
                fi

                builtin printf '%s\n' "$value"
        }

        function Queue.popr {
                if
                        (($#))
                then
                        builtin declare -n queue=$1
                        builtin declare -i last=queue[last]
                else
                        builtin printf '%s: need a name\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi

                if
                        ((queue[first] > last))
                then
                        builtin printf '%s\n' "queue is empty" 1>&2;
                        builtin return 1
                else
                        builtin declare value=${queue[$last]}
                        builtin unset -v "queue[$last]"
                        ((queue[last] = last - 1))
                fi

                builtin printf '%s\n' "$value"
        }

        function Queue.pushl {
                if
                        (($#))
                then
                        builtin declare -n queue=$1
                        builtin declare -i first="queue[first] - 1"
                        queue[first]=$first
                        queue[$first]=${@:2}
                else
                        builtin printf '%s: need a name\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi
        }

        function Queue.pushr {
                if
                        (($#))
                then
                        builtin declare -n queue=$1
                        builtin declare -i last="queue[last] + 1"
                        queue[last]=$last
                        queue[$last]=${@:2}
                else
                        builtin printf '%s: need a name\n' "$FUNCNAME" 1>&2;
                        builtin return 1
                fi
        }

        function __.cleanup {
                builtin unset -f \
                        Queue.{pop{l,r},push{l,r},new} \
                        __.{cleanup};

                builtin return "${status:-0}"
        }

        if
                (($#))
        then
                "${FUNCNAME}.${1}" "${@:2}"
        else
                builtin printf '%s: need an operation\n' "$FUNCNAME" 1>&2;
                builtin return 1
        fi
}

# vim: set ts=8 sw=8 tw=0 et :
