#!/bin/bash


LIBDIR=$1
SAMPLEDIR=$2
COMPILERBIN=$3

TMPFILE=$HOME/tmp/compile.log
FAILED=$HOME/tmp/failed.log

rm -f $FAILED

status=0
for f in `find $SAMPLEDIR -name \*.jal`
do
	if grep -i "^include[[:space:]]\+18l\?f" $f > /dev/null 2>&1
	then
	    $COMPILERBIN -s $LIBDIR -no-variable-reuse $f > $TMPFILE 2>&1 
		status=$?
	else
	    $COMPILERBIN -s $LIBDIR $f > $TMPFILE 2>&1 
		status=$?
	fi


	if [ "$status" != "0" ]
	then
		echo "$f failed !"
        echo "$f failed !" >> $FAILED
        cat $TMPFILE >> $FAILED
        echo >> $FAILED
		status=1
	fi
done

echo
echo
cat $FAILED
rm -f $FAILED

exit $status
