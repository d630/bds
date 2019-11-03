#!/usr/bin/env bsh

Llist ()
{
	trap '\Llist.__cleanup "$?"' RETURN;

	function Llist.__addHeadNode {
		# USAGE: Llist.__addHeadNode [ELEMENT]

		declare newNodeName;
		declare -i newNodeId;
		declare -n newNode;

		newNodeId="${list[id]} + 1";
		newNodeName="${!list}_$newNodeId";
		list[id]=$newNodeId;

		declare -g -A "$newNodeName=([prev]=NULL)";
		newNode=$newNodeName;
		newNode[data]=$*;

		if
			((${#nodes[@]}));
		then
			declare -n nextNode;
			nextNode=${nodes[0]};
			nextNode[prev]=$newNodeName;
			newNode[next]=${nodes[0]};
			nodes=("$newNodeName" "${nodes[@]}");
		else
			newNode[next]=NULL;
			nodes[0]=$newNodeName;
		fi;
	};

	function Llist.__addTailNode {
		# USAGE: Llist.__addTailNode INDEX [ELEMENT]

		declare newNodeName;
		declare -i newNodeId;
		declare -n newNode;

		newNodeId="${list[id]} + 1";
		newNodeName="${!list}_$newNodeId";
		list[id]=$newNodeId;

		declare -g -A "$newNodeName=([next]=NULL)";
		newNode=$newNodeName;
		newNode[data]=$*;

		if
			((${#nodes[@]}));
		then
			declare -n prevNode;
			prevNode=${nodes[-1]};
			prevNode[next]=$newNodeName;
			newNode[prev]=${nodes[-1]};
			nodes+=("$newNodeName");
		else
			newNode[prev]=NULL;
			nodes[0]=$newNodeName;
		fi;
	};

	function Llist.__addMiddleNode {
		# USAGE: Llist.__addMiddleNode INDEX [ELEMENT]

		declare -i index;
		index=$1;

		shift 1;

		declare newNodeName;
		declare -i newNodeId;
		declare -n \
			newNode \
			nextNode \
			prevNode;

		prevNode=${nodes[index - 1]};
		nextNode=${nodes[index]}

		newNodeId="${list[id]} + 1";
		newNodeName="${!list}_$newNodeId";
		declare -g -A "$newNodeName=()";
		newNode=$newNodeName;

		list[id]=$newNodeId;
		newNode[data]=$*;
		newNode[next]=${!nextNode};
		newNode[prev]=${!prevNode};
		prevNode[next]=$newNodeName;
		nextNode[prev]=$newNodeName;

		nodes=(
			"${nodes[@]:0:index}"
			"$nameNodeName"
			"${nodes[@]:index}"
		);

		nodes[index]=$newNodeName;
	};

	function Llist.__cleanup {
		trap -- - RETURN;
		unset -f \
			Llist.__{{add,remove}{Head,Middle,Tail}Node,usage,print} \
			Llist.{append,index,insert,length,prepend,range,replace} \
			Llist.{set,traverse,unset} \
			"$FUNCNAME";

		return "$1";
	};

	function Llist.__print {
		# USAGE: Llist.__print INDEX

		declare -n node;
		node=${nodes[$1]};

		if
			[[ -v node[data] ]];
		then
			printf '%s ' "${node[data]@Q}";
		else
			printf '%s: list <%s> has a damaged node (data missing): %s\n' \
				"$FUNCNAME" "${!list}" "${!node}" 1>&2;
			return 1;
		fi;
	};

	function Llist.__removeHeadNode {
		# USAGE: Llist.__removeHeadNode

		case ${#nodes[@]} in
			(0)
				return 1;;
			(1)
				unset -v "${nodes[0]}";
				nodes=();;
			(*)
				declare -n nextNode;
				nextNode=${nodes[1]};
				nextNode[prev]=NULL;
				unset -v \
					"${nodes[0]}" \
					"nodes[0]";
				nodes=("${nodes[@]}");;
		esac;
	};

	function Llist.__removeTailNode {
		# USAGE: Llist.__removeTailNode INDEX

		declare -i index;
		declare -n \
			node \
			prevNode;
		index=$1;
		node=${nodes[index + 1]};
		prevNode=${nodes[index]};

		[[ ${node[next]} == NULL ]] || {
			declare -n nextNode;
			nextNode=${node[next]};
			nextNode[prev]=${node[prev]};
		};
		prevNode[next]=${node[next]};
		unset -v \
			"${!node}" \
			"nodes[$index + 1]";

		nodes=("${nodes[@]}");
	};

	function Llist.__usage {
		declare -A "u=(
			[append]='[element ...]'
			[index]='[index]'
			[insert]='index [element ...]'
			[length]='[-t]'
			[prepend]='[element ...]'
			[range]='[-r] first last'
			[replace]='first last [element ...]'
			[set]='[element ...]'
			[traverse]='[-r] index'
			[unset]=''
		)";

		if
			[[ -v u[$1] ]];
		then
			printf 'usage: %s %s lname %s\n' "${FUNCNAME[1]}" "$1" "${u[$1]}";
		else
			declare k;
			for k in "${!u[@]}";
			do
				printf 'usage: %s %s lname %s\n' "${FUNCNAME[1]}" "$k" "${u[$k]}";
			done |
				command sort;
		fi 1>&2;
	};

	function Llist.append {
		\Llist.insert "$1" -1 "${@:2}";
	};

	function Llist.index {
		declare -n \
			list \
			nodes;

		list=$1;
		nodes=$1_idx;

		if
			(($# == 2));
		then
			declare -i index;
			printf -v index '%d' "$2" 2>/dev/null || {
				printf '%s: invalid number: %s\n' "$FUNCNAME" "$2" 1>&2;
				return 1;
			};
			if
				[[ -v nodes[index] ]];
			then
				\Llist.__print "$index" ||
					return 1;
				echo;
			else
				return 1;
			fi;
		else
			\Llist.range "$1" 0 "${#nodes[@]}";
		fi;
	};

	function Llist.insert {
		declare -n \
			list \
			nodes;
		declare -i index;

		list=$1;
		nodes=$1_idx;
		printf -v index '%d' "$2" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$2" 1>&2;
			return 1;
		};

		shift 2;

		((
			index > ${#nodes[@]} ? index=${#nodes[@]} : 1,
			${#nodes[@]} == 0 && index != 0 ? index=0 : 1
		))

		declare e;
		case $index in
			(0)
				for ((e=$#; e > 0; e--));
				do
					\Llist.__addHeadNode "${@:e:1}" ||
						return 1;
				done;;
			(-[0-9]*|${#nodes[@]})
				for e in "$@";
				do
					\Llist.__addTailNode "$e" ||
						return 1;
				done;;
			(*)
				for ((e=$#; e > 0; e--));
				do
					\Llist.__addMiddleNode "$index" "${@:e:1}" ||
						return 1;
				done;;
		esac;
	};

	function Llist.length {
		declare -n nodes;
		nodes=$1_idx;

		case ${2#-} in
		(t)
			\Llist.traverse "$1" 0 | {
				mapfile -t;
				printf '%d\n' "${#MAPFILE[@]}";
			};;
		(*)
			printf '%d\n' "${#nodes[@]}";;
		esac;
	};

	function Llist.prepend {
		\Llist.insert "$1" 0 "${@:2}";
	};

	function Llist.range {
		declare -n \
			list \
			nodes;
		declare -i \
			first \
			last \
			rev;

		list=$1;
		nodes=$1_idx;
		shift 1;
		[[ $1 == -r ]] && rev=1 && shift 1;
		printf -v first '%d' "$1" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$1" 1>&2;
			return 1;
		};
		printf -v last '%d' "$2" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$2" 1>&2;
			return 1;
		};

		((
			first = first < 0 ? 0 : first,

			last =
			last == -1 || last >= ${#nodes[@]}
			? ${#nodes[@]}-1
			: last
		));

		((first > last)) &&
			return 1;

		declare -i n;
		if
			((rev));
		then
			for ((n=last; n >= first; n--));
			do
				\Llist.__print "$n" ||
					return 1;
			done;
		else
			for ((n=first; n <= last; n++));
			do
				\Llist.__print "$n" ||
					return 1;
			done;
		fi;
		echo;
	};

	function Llist.replace {
		declare -n \
			list \
			nodes;
		declare -i \
			first \
			last;

		list=$1;
		nodes=$1_idx;
		shift 1;

		printf -v first '%d' "$1" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$1" 1>&2;
			return 1;
		};
		printf -v last '%d' "$2" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$2" 1>&2;
			return 1;
		};
		shift 2;

		case $first in
			(0|-[0-9]*)
				case $last in
					(-[0-9]*)
						first=0;;
					(0)
						\Llist.__removeHeadNode ||
							return 1;;
					(*)
						declare e;
						((
							e =
							last - ${#nodes[@]} >= 0
							? ${#nodes[@]} - 1
							: last
						));
						for ((; e > -1; e--));
						do
							\Llist.__removeHeadNode ||
								return 1;
						done;;
				esac;;
			(*)
				((first >= ${#nodes[@]})) &&
					return 1;
				((
					last=
					first + last >= ${#nodes[@]}
					? ${#nodes[@]} - 1 - first
					: last
				));
				case $last in
					(-[0-9]*)
						:;;
					(0)
						\Llist.__removeTailNode "$((first - 1))" ||
							return 1;;
					(*)
						declare e f;
						for ((e=last, f=first-1; e > -1; e--));
						do
							\Llist.__removeTailNode "$f" ||
								return 1;
						done;;
				esac;;
		esac;

		\Llist.insert "${!list}" "$first" "$@";
	};

	function Llist.set {
		\Llist.unset "$1";

		declare -g -a "${1}_idx=()";
		declare -g -A "$1=(
			[type]=llist
			[nodes]=${1}_idx
			[id]=-1
		)";

		\Llist.insert "$1" 0 "${@:2}";
	};

	function Llist.traverse {
		declare -n  \
			node \
			nodes;
		declare link;
		declare -i index;

		nodes=$1_idx;
		link=next;
		shift 1;

		[[ $1 == -r ]] && link=prev && shift 1;

		printf -v index '%d' "$1" 2>/dev/null || {
			printf '%s: invalid number: %s\n' "$FUNCNAME" "$1" 1>&2;
			return 1;
		};

		if
			[[ -v nodes[index] ]];
		then
			node=${nodes[index]};
		else
			printf '%s: index does not exist: %d\n' "$FUNCNAME" "$index" 1>&2;
			return 1;
		fi;

		unset -v NULL;
		while
			[[ -v node[$link] ]];
		do
			printf '%s[data]=%q\n' "${!node}" "${node[data]}";
			declare -n "node=${node[$link]}";
		done;
	};

	function Llist.unset {
		declare -n \
			list \
			nodes;

		list=$1;
		nodes=$1_idx;

		((${#list[@]})) ||
			return 0;

		unset -v "${!list}";

		declare n;
		for n in "${nodes[@]}";
		do
			unset -v "$n";
		done;

		unset -v "${!nodes}";
	};

	declare op;
	op=${1:?$FUNCNAME: need an operation};

	shift 1;

	declare -i a;
	case $op in
		(append) a="$# >= 1";;
		(index) a="$# >= 1";;
		(insert) a="$# >= 2";;
		(length) a="$# >= 1";;
		(prepend) a="$# >= 1";;
		(range) a="$# >= 3";;
		(replace) a="$# >= 3";;
		(set) a="$# >= 1";;
		(traverse) a="$# >= 2";;
		(unset) a="$# == 1";;
		(*)
			printf '%s: unknown operation: %s\n' "$FUNCNAME" "$op" 1>&2;
	esac;

	((a)) || {
		\Llist.__usage "$op";
		return 1;
	};

	[[ $op == set ]] || eval [[ '"${'"$1[type]"'}"' == llist ]] || {
		printf '%s: <%s> is not a list\n' "$FUNCNAME" "$1" 1>&2;
		return 1;
	};

	"$FUNCNAME.$op" "$@";
};

# vim: set ft=sh :
