#!/bin/bash

# default settings
JAILROOT_DIR=JAIL
WORKING_DIR=working

# option parse
while getopts ":r:p:b:f:hw:" OPT
do 
  case $OPT in
    r) 
      JAILROOT_PATH=$OPTARG
      ;;
    p)
      BINARY_PORT=$OPTARG
      ;;
    b)
      BINARY_PATH=$(readlink -f $OPTARG)
      ;;
    f)
      FLAG_PATH=$(readlink -f $OPTARG)
      ;;
    h)
      echo "usage: pwnjail.sh -b [binary_path] -r [jailroot_path] -p [port_number] -w [working_path] -f [flag_path]" ;;
    w)
      WORKING_PATH=$OPTARG
      ;; 
    :) echo "[ERROR]" ;;
    \?) echo "[ERROR] Undefined options." ;;
  esac
done

# create jailroot directory
pushd ./
mkdir -p $JAILROOT_PATH
JAILROOT_PATH_FULL=$(readlink -f $JAILROOT_PATH)
echo "[+] JAILROOT PATH is $JAILROOT_PATH_FULL"
cd $JAILROOT_PATH



# create working directory
mkdir -p $WORKING_PATH
WORKING_PATH_FULL=$(readlink -f $WORKING_PATH)
echo "[+] WORKING PATH is $WORKING_PATH_FULL"

# copy binary and flag
mkdir -p $WORKING_PATH
cp "$BINARY_PATH" "$WORKING_PATH_FULL/"
echo "[+] BINARY_PATH is $WORKING_PATH_FULL/$(basename $BINARY_PATH)"
SOCAT_BINARY=$(basename $BINARY_PATH)
cp "$FLAG_PATH" "$WORKING_PATH_FULL/"
echo "[+] FLAG_PASH is $WORKING_PATH_FULL/$(basename $FLAG_PATH)"


# create etc directory
mkdir etc
echo "cd $WORKING_PATH" > ./etc/start.sh
echo "socat TCP-LISTEN:$BINARY_PORT,reuseaddr,fork EXEC:./$SOCAT_BINARY" >> ./etc/start.sh
chmod +x ./etc/start.sh

# gathering ldd information and copy user command binary
which ls > command.txt
which cat >> command.txt
which id >> command.txt
which sh >> command.txt
which socat >> command.txt
which env >> command.txt

SOCAT_PATH=$(dirname $(which socat))
echo "[+] SOCAT path is $SOCAT_PATH"

cat command.txt | xargs dirname | uniq | cut -b 2- | xargs mkdir -p

ldd $BINARY_PATH > lddlist.txt

for command_name in `cat command.txt`
do
  cp "$command_name" "`dirname $command_name | cut -b 2- `/"
  ldd $command_name >> lddlist.txt
done

# create library directory
cat lddlist.txt | grep -e "/\S*" -o | sort | uniq > lddlist_optimize.txt
cat lddlist_optimize.txt | xargs dirname | uniq | cut -b 2- | xargs mkdir -p


# copy library
for ldd_name in `cat lddlist_optimize.txt`
do
  cp "$ldd_name" "`dirname $ldd_name | cut -b 2-`/"
done

# delete temp files
rm command.txt
rm lddlist.txt
rm lddlist_optimize.txt

# launch the chroot jail
cd $WORKING_PATH
echo $PWD
chroot --userspec=1000 $JAILROOT_PATH_FULL /etc/start.sh&

# return to current directory
popd
