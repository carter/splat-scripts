#!/bin/sh

# get the SRTM data files and convert them for splat use

# License: Public domain / CC-0

# path to topgraphy datafiles
TOPOFILEDIR=splat-datafiles/sdf/
# local hgt file archive
HGTFILEDIR=splat-datafiles/hgtzip/

if [ ! -x `which srtm2sdf` ]; then
  echo "error: not found in path: srtm2sdf splat conversion utility"
  exit 1
fi

if [ ! -x `which readlink` ]; then
  echo "error: not found in path: readlink"
  exit 1
fi

if [ ! -x `which wget` ]; then
  echo "error: not found in path: wget"
  exit 1
fi

if [ ! -x `which unzip` ]; then
  echo "error: not found in path: unzip"
  exit 1
fi

if [ ! -x `which bzip2` ]; then
  echo "error: not found in path: bzip2"
  exit 1
fi

echo "Please sign up for a NASA Earthdata account at: \nhttps://urs.earthdata.nasa.gov/users/new"
read -p 'NASA Earthdata Username: ' NASA_USERNAME 
read -sp 'NASA Earthdata Password: ' NASA_PASSWORD

for PAGE in 1 2 3 4 5 6
do
  INDEXURL="https://e4ftl01.cr.usgs.gov/MEASURES/SRTMGL3.003/2000.02.11/SRTMGL3_page_$PAGE.html"
  INDEXFILE=`mktemp`

  echo "getting index.."
  wget -q -O - $INDEXURL | \
    sed -r -e '/hgt.zip\"/!d; s/.* ([NSWE0-9]+\.?hgt\.zip).*$/\1/; s/<td><a href="//; s/">.*//'  \
    > $INDEXFILE
  echo $INDEXFILE
  mkdir -p $HGTFILEDIR
  mkdir -p $TOPOFILEDIR

  echo "retrieving files.."
  cd $HGTFILEDIR
  wget --http-user=$NASA_USERNAME --http-password=$NASA_PASSWORD -nv -N -B $INDEXURL -i $INDEXFILE
  cd -

  rm $INDEXFILE
done

# to minimize disk space required, run srtm2sdf on each file as it is unzipped.
HGTREALPATH=`readlink -f $HGTFILEDIR`
TOPOREALPATH=`readlink -f $TOPOFILEDIR`
PWD=`pwd`

echo "unpacking hgt files.."
cd $HGTFILEDIR
for e in *.zip ; do 
	echo $e
	nice unzip -o $e
	HGTFILE=`echo $e | sed -r -e 's/\.?.SRTMGL3.hgt.zip/.hgt/'`
	if [ -r $HGTFILE ]; then
		cd $TOPOREALPATH
		nice srtm2sdf -d /dev/null $HGTREALPATH/$HGTFILE
		echo "compressing.."
		nice bzip2 -f -- *.sdf
		echo "deleting hgt file.."
		cd $HGTREALPATH
		rm $HGTFILE
	fi
done

cd $PWD

echo "Complete.  The files in $HGTFILEDIR may be removed."


