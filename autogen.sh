#!/bin/sh

set -e # exit on errors

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

git submodule update --init --recursive

cd egg-list-box
sed s/GOBJECT_INTROSPECTION_REQUIRE/GOBJECT_INTROSPECTION_CHECK/ -i configure.ac
sh autogen.sh --no-configure
cd ..

autoreconf -v --force --install
intltoolize -f

if [ -z "$NOCONFIGURE" ]; then
    "$srcdir"/configure ${1+"$@"}
fi
