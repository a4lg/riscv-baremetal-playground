#! /bin/sh
if test $# -ne 1
then
    echo "usage: $0 NAME_OF_PROGRAM" 1>&2
    exit 1
fi
if test ! -f data/templates/bare.S
then
    echo "ERROR: this script must be run on the top of the source tree." 1>&2
    exit 1
fi
case "$1" in
.* | /* | */.*)
    echo "ERROR: name of program \`$1' is not valid." 1>&2
    exit 1
    ;;
esac
cp -f data/templates/bare.S $1.bare.S
echo "src_targets += $1.bare.S" >>SOURCES.mk
