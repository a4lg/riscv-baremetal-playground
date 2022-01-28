#! /bin/sh
if test $# -ne 1
then
    echo "usage: $0 NAME_OF_PROGRAM" 1>&2
    exit 1
fi
if test ! -f data/templates/newlib.c && test ! -f data/templates/newlib.cpp
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
if test -f data/templates/newlib.cpp
then
    cp -f data/templates/newlib.cpp $1.newlib.cpp
else
    cp -f data/templates/newlib.c $1.newlib.cpp
fi
echo "src_targets += $1.newlib.cpp" >>SOURCES.mk
