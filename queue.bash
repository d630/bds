#!/usr/bin/env bash

Queue ()
{
	(($# < 2)) && {
		printf '%s: need an operation and a queue name\n' "$FUNCNAME" 1>&2;
		return 1;
	};

	[[ $1 == set || -v ${2}[type] ]] || {
		printf '%s: %s is not a queue\n' "$FUNCNAME" "$2" 1>&2;
		return 1;
	};

	trap '
		status=$?;
		trap -- - RETURN;
		s=$status \__.cleanup;
	' RETURN;

	function Queue.set {
		(($#)) || {
			printf '%s: need a name\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		unset -v "$1";

		declare -g -A "$1=(
			[type]=queue
			[first]=0
			[last]=-1
		)";
	};

	function Queue.popl {
		(($#)) || {
			printf '%s: need a name\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		declare -n queue=$1;
		declare -i first=queue[first];

		((queue[last] < first)) && {
			printf 'queue is empty\n' 1>&2;
			return 1;
		};

		printf '%s\n' "${queue[$first]}";
		unset -v "queue[$first]";
		((queue[first] = first + 1));
	};

	function Queue.popr {
		(($#)) || {
			printf '%s: need a name\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		declare -n queue=$1;
		declare -i last=queue[last];

		((queue[first] > last)) && {
			printf 'queue is empty\n' 1>&2;
			return 1;
		};

		printf '%s\n' "${queue[$last]}";
		unset -v "queue[$last]";
		((queue[last] = last - 1));
	};

	function Queue.pushl {
		(($#)) || {
			printf '%s: need a name\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		declare -n queue=$1;
		declare -i first='queue[first] - 1';
		queue[first]=$first;
		queue[$first]=${@:2};
	};

	function Queue.pushr {
		(($#)) || {
			printf '%s: need a name\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		declare -n queue=$1;
		declare -i last='queue[last] + 1';
		queue[last]=$last;
		queue[$last]=${@:2};
	};

	function __.cleanup {
		unset -v status;
		unset -f \
			Queue.{pop{l,r},push{l,r},set} \
			__.{cleanup};

		return $s;
	};

	"$FUNCNAME.$1" "${@:2}";
};

# vim: set ft=sh :
