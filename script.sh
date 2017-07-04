#!/bin/bash
# This should generate a list of domains 1-20 wrapped around a root "word"

echo ""
echo "____________________________________________________________________________"
echo ""

## variables
REPONAME=youtubeadsblacklist
REPODIR=/etc/"$REPONAME"/
REPOOWNER=anudeepND
GITREPOSITORYURL="github.com/"$REPOOWNER"/"$REPONAME".git"
DOCTOSPITOUT="$REPODIR"domainlist.txt
DOCTOSPITOUTOLD="$REPODIR"domainlist.lastrun.txt
ROOTSUBSLIST="$REPODIR"rootsubs.txt
ROOTSUBSOLDLIST="$REPODIR"rootsubs.lastrun.txt
TEMPFILE="$REPODIR"tempfile.temp

## whiptail required
WHATITIS=whiptail
WHATPACKAGE=whiptail
if
which $WHATITIS >/dev/null;
then
echo "$WHATITIS Already Installed"
else
echo "Installing $WHATITIS"
apt-get install -y $WHATPACKAGE
fi
echo ""

## gawk required
WHATITIS=gawk
WHATPACKAGE=gawk
if
which $WHATITIS >/dev/null;
then
echo "$WHATITIS Already Installed"
else
echo "Installing $WHATITIS"
apt-get install -y $WHATPACKAGE
fi
echo ""

echo "____________________________________________________________________________"
echo ""

## Did you pull from online?
if
(whiptail --title "$REPONAME" --yesno "Did you git pull from github?" 10 80) 
then
echo "GREAT!!!!"
else
DIDWEPULL=true
fi

if
[[ -n $DIDWEPULL ]]
then
if
(whiptail --title "$REPONAME" --yesno "Would you like to attempt git pull now?" 10 80) 
then
git -C $REPODIR pull
else
exit
fi
fi

echo "____________________________________________________________________________"
echo ""

## delete old domains list
if
ls $DOCTOSPITOUTOLD &> /dev/null;
then
rm $DOCTOSPITOUTOLD
else
:
fi

## backup old domains list
if
ls $DOCTOSPITOUT &> /dev/null;
then
mv $DOCTOSPITOUT $DOCTOSPITOUTOLD
else
:
fi

## Sort and dedupe rootsubs list
cat -s $ROOTSUBSLIST | sort -u | gawk '{if (++dup[$0] == 1) print $0;}' > $TEMPFILE
mv $TEMPFILE $ROOTSUBSLIST

## Let's skip the ones we've already handled
gawk 'NR==FNR{a[$0];next} !($0 in a)' $ROOTSUBSOLDLIST $ROOTSUBSLIST > $TEMPFILE
rm $ROOTSUBSOLDLIST
cp $ROOTSUBSLIST $ROOTSUBSOLDLIST

for source in `cat $TEMPFILE`;
do

echo "Processing $source"
echo ""

for i in {1..20}
do

DOMAINONE=r"$i"---sn-"$source".googlevideo.com
DOMAINTWO=r"$i".sn-"$source".googlevideo.com

SOURCEIPFETCHONE=`ping -c 1 $DOMAINONE | gawk -F'[()]' '/PING/{print $2}'`
SOURCEIPONE=`echo $SOURCEIPFETCHONE`
SOURCEIPFETCHTWO=`ping -c 1 $DOMAINTWO | gawk -F'[()]' '/PING/{print $2}'`
SOURCEIPTWO=`echo $SOURCEIPFETCHTWO`

if
[[ -n $SOURCEIPONE ]]
then
echo "$DOMAINONE is located at $SOURCEIPONE"
echo "$DOMAINONE" | tee --append $DOCTOSPITOUT &>/dev/null
fi

if
[[ -n $SOURCEIPTWO ]]
then
echo "$DOMAINTWO is located at $SOURCEIPTWO"
echo "$DOMAINTWO" | tee --append $DOCTOSPITOUT &>/dev/null
fi

## Done with Loop
done
echo "____________________________________________________________________________"
echo ""
done

## Remove temp file
CHECKME=$TEMPFILE
if
ls $CHECKME &> /dev/null;
then
rm $CHECKME
else
:
fi

cat $DOCTOSPITOUTOLD $DOCTOSPITOUT >> $TEMPFILE
mv $TEMPFILE $DOCTOSPITOUT

HOWMANYLINES=$(echo -e "`wc -l $DOCTOSPITOUT | cut -d " " -f 1`")
echo "New List Contains $HOWMANYLINES Domains."

## Pushlists?
if
(whiptail --title "anudeeptest" --yesno "Do you want to push list to github" 10 80) 
then
timestamp=$(echo `date`)
GITHUBUSERNAME=$(whiptail --inputbox "Github Username?" 10 80 "" 3>&1 1>&2 2>&3)
GITHUBPASSWORD=$(whiptail --inputbox "Github Password?" 10 80 "" 3>&1 1>&2 2>&3)
GITWHERETOPUSH=https://"$GITHUBUSERNAME":"$GITHUBPASSWORD"@"$GITREPOSITORYURL"
git -C $REPODIR remote set-url origin $GITWHERETOPUSH
git -C $REPODIR add .
git -C $REPODIR commit -m "Update lists $timestamp"
git -C $REPODIR push -u origin master
else
:
fi
