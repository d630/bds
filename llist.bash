#!/usr/bin/env bash

Llist ()
{
	trap '
		status=$?;
		trap -- - RETURN;
		s=$status __.cleanup;
	' RETURN;

	function __.addNodeAfter {
		# USAGE: __.addNodeAfter INDEX [ELEMENT]

		declare -i index=$1;
		shift 1;

		declare name="${!list}_$((${list[id]} + 1))";
		declare -g -A "$name=()";
		declare -n \
			newNode=$name \
			node=${nodes[$index]};

		newNode[data]=$*;
		list[id]=$((${list[id]} + 1));
		newNode[next]=${node[next]};
		newNode[prev]=${!node};
		node[next]=$name;

		if
			((${#nodes[@]} == index + 1));
		then
			nodes+=("$name");
		else
			nodes=(
				"${nodes[@]:0:index+1}"
				"$name"
				"${nodes[@]:index+1}"
			);
			# declare i ii
			# declare -a t
			# t=("${nodes[@]}")
			# for ((i=0, ii=index+1; i < ii; i++))
			# do
			#         unset -v "t[$i]"
			# done
			# for ((i=index+1, ii=${#nodes[@]}; i <= ii; i++))
			# do
			#         unset -v "nodes[$i]"
			# done
			# nodes+=("$name" "${t[@]}")
		fi;
	}

	function __.addNodeHead {
		# USAGE: __.addNodeHead [ELEMENT]

		declare name="${!list}_$((${list[id]} + 1))";
		declare -g -A "$name=([prev]=NULL)";
		declare -n newNode=$name;
		newNode[data]=$*;
		list[id]=$((${list[id]} + 1));

		if
			((${#nodes[@]}));
		then
			newNode[next]=${nodes[0]};
			declare -n node=${nodes[0]};
			node[prev]=$name;
			nodes=("$name" "${nodes[@]}");
		else
			newNode[next]=NULL;
			nodes[0]=$name;
		fi;
	}

	function __.cleanup {
		unset -v status;
		unset -f \
			__.{addNode{After,Head},removeNode{After,Head}} \
			__.{cleanup,usage} \
			Llist.{append,index,insert,length,range,replace} \
			Llist.{set,traverse,unset};

		return $s;
	};

	function __.removeNodeAfter {
		# USAGE: __.removeNodeAfter INDEX

		declare -i index=$1;
		declare -n \
			node=${nodes[$index + 1]} \
			prevNode=${nodes[$index]};

		[[ ${node[next]} == NULL ]] || {
			declare -n nextNode=${node[next]};
			nextNode[prev]=${node[prev]};
		};
		prevNode[next]=${node[next]};
		unset -v \
			"${!node}" \
			"nodes[$index + 1]";

		nodes=("${nodes[@]}");
	}

	function __.removeNodeHead {
		# USAGE: __.removeNodeHead

		case ${#nodes[@]} in
		(0)
			return 1;;
		(1)
			unset -v "${nodes[0]}";
			nodes=();;
		(*)
			declare -n nextNode=${nodes[1]};
			nextNode[prev]=NULL;
			unset -v \
				"${nodes[0]}" \
				"nodes[0]";
			nodes=("${nodes[@]}");;
		esac;
	}

	function __.usage {
		declare -A "u=(
			[append]='[element ...]'
			[index]='[index]'
			[insert]='index [element ...]'
			[length]='[-t]'
			[range]='[-r] first last'
			[replace]='first last [element ...]'
			[set]='[element ...]'
			[traverse]='[-r] index'
			[unset]=''
		)";

		printf 'usage: %s %s lname %s\n' "${FUNCNAME[1]}" "$1" "${u[$1]}" 1>&2;
	};

	function Llist.append {
		Llist.insert "${#nodes[@]}" "$@";
	}

	function Llist.index {
		if
			(($#));
		then
			declare -i index=$1;
			if
				[[ -v ${nodes[$index]}[data] ]] 2>/dev/null;
			then
				declare -n node=${nodes[$index]};
				printf '%s\n' "${node[data]@Q}";
			else
				return 1;
			fi;
		else
			Llist.range 0 ${#nodes[@]};
		fi;
	}

	function Llist.insert {
		declare -i index=$1;
		shift 1;

		case $index in
		(0|-[0-9]*)
			declare e;
			for ((e=$#; e > 0; e--));
			do
				__.addNodeHead "${@:e:1}" ||
					return 1;
			done;;
		(*)
			((index > ${#nodes[@]})) &&
				return 1;
			declare e i;
			for ((e=$#, i=index-1; e > 0; e--));
			do
				__.addNodeAfter "$i" "${@:e:1}" ||
					return 1;
			done;;
		esac;
	}

	function Llist.length {
		case ${1#-} in
		(t)
			Llist.traverse 0 | {
				# declare -i i=
				# while
				#         read -r
				# do
				#         ((i++))
				# done
				# printf '%d\n' "${i}";
				mapfile -t;
				printf '%d\n' "${#MAPFILE[@]}";
			};;
		(*)
			printf '%d\n' "${#nodes[@]}";;
		esac;
	}

	function Llist.range {
		declare -i rev=0;

		[[ $1 == -r ]] &&
			declare rev=1 &&
			shift 1;
		declare -i \
			first=$1 \
			last=$2;

		((
			first = first < 0 ? 0 : first,

			last =
			last == -1 || last >= ${#nodes[@]}
			? ${#nodes[@]}-1
			: last
		));

		((first > last)) &&
			return 1;

		declare n;
		if
			((rev));
		then
			for ((n=last; n >= first; n--));
			do
				declare -n node=${nodes[$n]} &&
					printf '%s ' "${node[data]@Q}";
			done;
		else
			for ((n=first; n <= last; n++));
			do
				declare -n node=${nodes[$n]} &&
					printf '%s ' "${node[data]@Q}";
			done;
		fi;
		printf '%s\n';
	}

	function Llist.replace {
		declare -i \
			first=$1 \
			last=$2;
		shift 2;

		case $first in
		(0|-[0-9]*)
			case $last in
			(-[0-9]*)
				first=0;;
			(0)
				__.removeNodeHead ||
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
					__.removeNodeHead ||
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
				__.removeNodeAfter "$((first - 1))" ||
					return 1;;
			(*)
				declare e f;
				for ((e=last, f=first-1; e > -1; e--));
				do
					__.removeNodeAfter "$f" ||
						return 1;
				done;;
			esac;;
		esac;

		Llist.insert "$first" "$@";
	}

	function Llist.set {
		declare -n \
			list=$1 \
			nodes=$1_idx;

		Llist.unset;

		declare -g -A "${!list}=(
			[type]=llist
			[nodes]='${!list}_idx'
			[id]=-1
		)";
		declare -g -a "${!nodes}=()";

		shift 1;
		Llist.insert 0 "$@";
	}

	function Llist.traverse {
		declare link=next;
		[[ $1 == -r ]] &&
			link=prev &&
			shift 1;

		declare -n node=${nodes[$1]} 2>/dev/null || {
			printf '%s: index does not exist\n' "$FUNCNAME" 1>&2;
			return 1;
		};

		while
			[[ -v node[$link] ]];
		do
			printf '%s[data]=%q\n' "${!node}" "${node[data]}";
			declare -n node=${node[$link]};
		done;
	}

	function Llist.unset {
		unset -v "${!list}";

		declare -i n;
		((${#nodes[@]})) && {
			for ((n=${#nodes[@]}-1; n > -1; n--));
			do
				unset -v "${nodes[$n]}";
			done;
		};
	}

	declare op=$1;
	shift 1 2>/dev/null;

	declare -i a;
	case $op in
	(append) a="$# >= 1";;
	(index) a="$# >= 1";;
	(insert) a="$# >= 2";;
	(length) a="$# >= 1";;
	(range) a="$# >= 3";;
	(replace) a="$# >= 3";;
	(traverse) a="$# >= 2";;
	(unset) a="$# == 1";;
	(set)
		(($#)) && {
			"$FUNCNAME.$op" "$@";
			return $?;
		};
		a=0;;
	(*)
		printf '%s: need an operation\n' "$FUNCNAME" 1>&2;
		return 1;;
	esac;

	((a)) || {
		__.usage "$op";
		return 1;
	};

	[[ -v ${1}[type] ]] || {
		printf '%s: %s is not a list\n' "$FUNCNAME" "$1" 1>&2;
		return 1;
	};

	declare -n \
		list=$1 \
		nodes=${1}_idx;

	"$FUNCNAME.$op" "${@:2}";
};

# vim: set ft=sh :
