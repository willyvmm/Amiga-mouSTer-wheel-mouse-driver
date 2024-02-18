echo copying adf to pendrive

stick=$(lsblk | grep -v "mmcb" | sed -n "s/^.*\(\/media.*$\)/\1/p")

#fw=mouSTer.adf
fw=$1

stickf=${stick}/mouSTer
stickfw=${stickf}/${fw}



if [ -d "${stickf}" ]
then
    echo Stick found:  ${stickf}

    rm -f "$stickfw"
    if [ -f "$stickfw" ]
    then
	echo "FATAL File not deleted !!!!"
	exit -1
    fi
    cp -f "$fw" "$stickfw"
    sync
    umount "$stick"
    echo "***********************************"
    echo "*   mouSTer.adf copied to Stick   *"
    echo "***********************************"
else
    echo "No stick, No Copy ;)"
fi
