#!/usr/bin/env bash

Queue ()
{
        function Queue.new {
                builtin declare name=${1?${FUNCNAME}: need a name}
                builtin unset -v "$name"
                builtin declare -g -A "${name}=(
                        [type]=queue
                        [first]=0
                        [last]=-1
                )"

                __.cleanup
        }

        function Queue.pushl {
                builtin declare -n queue=${1?${FUNCNAME}: need a name}
                builtin declare -i first="queue[first] - 1"
                queue[first]=$first
                queue[$first]=${@:2}

                __.cleanup
        }

        function Queue.pushr {
                builtin declare -n queue=${1?${FUNCNAME}: need a name}
                builtin declare -i last="queue[last] + 1"
                queue[last]=$last
                queue[$last]=${@:2}

                __.cleanup
        }

        function Queue.popl {
                builtin declare -n queue=${1?${FUNCNAME}: need a name}
                builtin declare -i first=queue[first]

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

                __.cleanup
        }

        function Queue.popr {
                builtin declare -n queue=${1?${FUNCNAME}: need a name}
                builtin declare -i last=queue[last]

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

                __.cleanup
        }

        function __.cleanup {
                builtin unset -f \
                        Queue.{pop{l,r},push{l,r},new} \
                        __.{cleanup};
        }

        "${FUNCNAME}.${1?${FUNCNAME}: need an operation}" "${@:2}"
}

Queue new A

printf '%s\n' "${A[@]}"

for i in {1..10}
do
        Queue pushr A $i
done

for i in {1..10}
do
        Queue popl A
done
Queue popl A

echo ${A[first]} ${A[last]}

Queue pushr A "::"
Queue pushr A __
Queue popl A
Queue popl A
Queue popl A
echo ${A[first]} ${A[last]}

return 0 2>/dev/null

# vim: set ts=8 sw=8 tw=0 et :
