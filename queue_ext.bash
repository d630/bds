#!/usr/bin/env bash

Queue ()
{
	: "${1:?$FUNCNAME: need an operation and a queue name}" \
		"${2:?$FUNCNAME: need a queue name}";

	[[ $1 == set ]] || eval [[ '"${'"$2[type]"'}"' == queue_ext ]] || {
		printf '%s: <%s> is not a queue\n' "$FUNCNAME" "$2" 1>&2;
		return 1;
	};

	trap '\Queue.__cleanup "$?";' RETURN;

	function Queue.set {
		unset -v \
			"$1" \
			"${1}_head" \
			"${1}_tail";

		declare -g -a \
			"${1}_head=()" \
			"${1}_tail=()";

		declare -g -A "$1=(
			[type]=queue_ext
			[head]=${1}_head
			[head_first]=-1
			[tail]=${1}_tail
			[tail_first]=-1
		)";
	};

	function Queue.popl {
		declare -n \
			head \
			tail \
			queue;
		declare -i \
			head_first \
			tail_first;

		queue=$1;
		head=${queue[head]};
		tail=${queue[tail]};
		head_first=queue[head_first];
		tail_first=queue[tail_first];

		if
			((${#tail[@]}));
		then
			echo "${tail[-1]}";
			unset -v "tail[-1]";
			queue[tail_first]=$((${#tail[@]} ? tail_first : -1));
		elif
			((${#head[@]}));
		then
			echo "${head[head_first]}";
			unset -v "head[head_first]";
			queue[head_first]=$((${#head[@]} ? head_first + 1 : -1));
		else
			return 1;
		fi;
	};

	function Queue.popr {
		declare -n \
			head \
			tail \
			queue;
		declare -i \
			head_first \
			tail_first;

		queue=$1;
		head=${queue[head]};
		tail=${queue[tail]};
		head_first=queue[head_first];
		tail_first=queue[tail_first];

		if
			((${#head[@]}));
		then
			echo "${head[-1]}";
			unset -v "head[-1]";
			queue[head_first]=$((${#head[@]} ? head_first : -1));
		elif
			((${#tail[@]}));
		then
			echo "${tail[tail_first]}";
			unset -v "tail[tail_first]";
			queue[tail_first]=$((${#tail[@]} ? tail_first + 1 : -1));
		else
			return 1;
		fi;
	};

	function Queue.pushl {
		declare -n \
			queue \
			tail;
		declare -i tail_first;

		queue=$1;
		tail=${queue[tail]};
		tail_first=queue[tail_first];

		queue[tail_first]=$((tail_first == -1 ? 0 : tail_first));
		tail+=("${*:2}");
	};

	function Queue.pushr {
		declare -n \
			queue \
			head;
		declare -i head_first;

		queue=$1;
		head=${queue[head]};
		head_first=queue[head_first];

		queue[head_first]=$((head_first == -1 ? 0 : head_first));
		head+=("${*:2}");
	};

	function Queue.__cleanup {
		trap -- - RETURN;
		unset -f \
			Queue.{pop{l,r},push{l,r},set} \
			"$FUNCNAME";

		return "$1";
	};

	"$FUNCNAME.$1" "${@:2}";
};

# vim: set ft=sh :
