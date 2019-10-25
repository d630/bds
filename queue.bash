#!/usr/bin/env bash

Queue ()
{
	: "${1:?$FUNCNAME: need an operation and a queue name}" \
		"${2:?$FUNCNAME: need a queue name}";

	[[ $1 == set || -v ${2}[type] ]] || {
		printf '%s: %s is not a queue\n' "$FUNCNAME" "$2" 1>&2;
		return 1;
	};

	trap '\Queue.__cleanup "$?";' RETURN;

	function Queue.set {
		unset -v "$1";

		declare -g -A "$1=(
			[type]=queue
			[first]=0
			[last]=-1
		)";
	};

	function Queue.popl {
		declare -n queue;
		declare -i first;

		queue=$1;
		first=queue[first];

		((queue[last] < first)) && {
			Queue.set "${!queue}";
			return 1;
		};

		echo "${queue[$first]}";
		unset -v "queue[$first]";
		queue[first]=$((first + 1));
	};

	function Queue.popr {
		declare -n queue;
		declare -i last;

		queue=$1;
		last=queue[last];

		((queue[first] > last)) && {
			Queue.set "${!queue}";
			return 1;
		};

		echo "${queue[$last]}";
		unset -v "queue[$last]";
		queue[last]=$((last - 1));
	};

	function Queue.pushl {
		declare -n queue;
		declare -i first;

		queue=$1;
		first='queue[first] - 1';

		queue[first]=$first;
		queue[$first]=${@:2};
	};

	function Queue.pushr {
		declare -n queue;
		declare -i last;

		queue=$1;
		last='queue[last] + 1';

		queue[last]=$last;
		queue[$last]=${@:2};
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
