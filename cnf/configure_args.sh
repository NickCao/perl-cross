#!/bin/bash

function defineyesno {
	if [ "$2" == "yes" ]; then
		setvaru "$1" "$3"
	elif [ "$2" == "no" ]; then
		setvaru "$1" "$4"
	elif [ -z "$2" ]; then
		setvaru "$1" "$3"
	else
		die "Bad value for $1, only 'yes' and 'no' are allowed"
	fi
}

function defyes { defineyesno "$1" "$2" 'define' 'undef'; }
function defno  { defineyesno "$1" "$2" 'undef' 'define'; }

config_arg0="$0"
config_argc=$#
config_args="$*"

while [ $# -gt 0 ]; do
	a="$1"; shift;	# arg ("set" or 'D')
	k=''		# key ("prefix")
	v=''		# value ("/usr/local")
	x=''

	# check what kind of option is this
	case "$a" in
		-[A-Za-z]*)
			k=`echo "$a" | sed -e 's/^-.//'`
			a=`echo "$a" | sed -e 's/^-\(.\).*/\1/'`
			;;
		--[A-Za-z]*)
			a=`echo "$a" | sed -e 's/^--//'`
			;;
		*)
			echo "Bad option $a"
			continue;
			;;
	esac
	# split --set-foo and similar constructs into --set foo
	# and things like --prefix=/foo into --prefix and /foo
	case "$a" in
		set-*|use-*|include-*)
			k=`echo "$a" | sed -e 's/^[^-]*-//' -e 's/-/_/g'`
			a=`echo "$a" | sed -e 's/-.*//'`
			;;
		dont-use-*|dont-include-*)	
			k=`echo "$a" | sed -e 's/^dont-[^-]*-//' -e 's/-/_/g'`
			a=`echo "$a" | sed -e 's/^\(dont-[^-]*\)-.*/\1/'`
			;;
		*=*)
			k=`echo "$a" | sed -e 's/^[^=]*=//'`
			a=`echo "$a" | sed -e 's/=.*//'`
			;;
	esac
	# check whether kv is required
	# note that $x==1 means $k must be set; the value, $v, may be empty
	case "$a" in
		help|regen*|mode|host|target|build) x='' ;;
		*) x=1 ;;
	esac
	# fetch argument if necessary (--set foo=bar)
	if [ -n "$x" -a -z "$k" ]; then
		k="$1"; shift
	fi
	# split kv pair into k and v (k=foo v=bar)
	case "$k" in
		*=*)
			v=`echo "$k" | sed -e 's/^[^=]*=//'`
			k=`echo "$k" | sed -e 's/=.*//'`
			;;
	esac
	if [ -z "$v" -a -n "$k" ]; then v="$k"; k=""; fi
	# ($a, $k, $v) are all set here by this point
	#echo "a=$a k=$k v=$v"

	# process the options
	case "$a" in
		mode) test -z "$mode" && setvar $a "$v" || die "Can't set mode twice!" ;;
		help) setvar "mode" "help" ;;
		regen|regenerate) setvar "mode" "regen" ;;
		prefix|html[13]dir|libsdir)	setvar $a "$v" ;;
		man[13]dir|otherlibsdir)	setvar $a "$v" ;;
		siteprefix|sitehtml[13]dir)	setvar $a "$v" ;;
		siteman[13]dir|vendorman[13]dir)setvar $a "$v" ;;
		vendorprefix|vendorhtml[13]dir)	setvar $a "$v" ;;
		#byteorder)			setvar $a "$v" ;;
		build|target|targetarch)	setvar $a "$v" ;;
		cc|cpp|ar|ranlib|objdump)	setvar $a "$v" ;;
		sysroot)			setvar $a "$v" ;;
		hint|hints)
			if [ -n "$userhints" ]; then
				userhints="$userhints,$v"
			else
				userhints="$v"
			fi
			;;
		libs)
			if [ -n "$v" ]; then
				v=`echo ",$v" | sed -e 's/,\([^,]\+\)/-l\1 /g'`
				setvar 'libs' "$v"
			fi
			;;
		host-*)
			what=`echo "$a" | sed -e 's/^host-//'`
			hco="$hco --$what='$v'"
			;;
		target-*)
			what=`echo "$a" | sed -s 's/-/_/g'`
			setvaru "$what" "$v"
			;;
		disable-mod|disable-ext|disable-module|disable-modules)
			for m in `echo "$v" | sed -e 's/,/ /g'`; do
				s=`modsymname "$m"`
				setvar "disable_$s" "1"
			done
			;;
		static-mod|static-ext|static-modules|static)
			for m in `echo "$v" | sed -e 's/,/ /g'`; do
				s=`modsymname "$m"`
				setvar "static_$s" "1"
			done
			;;
		only-mod|only-ext|only-modules|only)
			for m in `echo "$v" | sed -e 's/,/ /g'`; do
				s=`modsymname "$m"`
				setvar "only_$s" "1"
				setvar "onlyext" "$s $onlyext"
			done
			;;
		use) setvaru "use$v" 'define' ;;
		dont-use) setvaru "use$v" 'undef' ;;
		set) setvaru "$k" "$v" ;;
		has) defyes "d_$k" "$v" ;;
		no) defno "d_$k" "$v" ;;
		lacks) defno "d_$k" "$v" ;;
		include) defyes "i_$k" "$v" ;;
		dont-include) defno "i_$k" "$v" ;;
		mode|host|target|build) ;;
		*) die "Unknown argument $a" ;;
	esac
done
