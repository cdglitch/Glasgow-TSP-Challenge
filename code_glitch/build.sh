#! /bin/sh
 ./clean.sh
#fpc -fPIC -gl $1 -gh -gv
fpc -fPIC -gl $1
./clean.sh

exit
