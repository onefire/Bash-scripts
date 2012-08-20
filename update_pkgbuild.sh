#!/bin/bash

#Author: onefire <onefire.myself@gmail.com>

#Script to automate the updates of PKGBUILDS. Its basic usage is:
#./update_pkgbuild.sh $version

#Where $version is the new version of the package. The program updates the version and and runs makepkg -g to update the md5sum fields. It is smart enough to do this twice, one for each architeture (i686 and x86_64), so that it updates not only for the arch of the machine. It also uses sed, so the md5sums go to the right place.

#Updating (or downgrading) packages most of the time only involves changes the "pkgver" field and the md5sums. This requires downloading the new versions, computing the md5sums and pasting them to the appropriate fields. This script does all this stuff making the entire process much faster.

#You can also use as second argument "clean=no". In this case the script does not delete the directory "work" that it creates (useful for example, if you want to keep the source files because, say, you are going to build the package)
#./update_pkgbuild.sh $version clean=no

#Very simple function. Change the "pkgver" line of the PKGBUILD 
update_version() {
sed -e s/`grep "pkgver=" PKGBUILD`/pkgver=$1/g PKGBUILD > junk && mv junk PKGBUILD
}

#This function does most of the work. Basically, it sends the md5sums to two files, md5sums_old and md5sums_new. Then it uses sed, replacinh each expression that matches a given line in md5sums_old with the scorresponding expression in md5sums_new. This way we can update PKGBUILDs with multiple sources. And because we let makepkg do all the work, the script can be used with PKGBUILDs that use sha1sums, for example.   
updater() {

#Temporary files where we store the md5sums of the two versions. 
file1=md5sums_old
file2=md5sums_new

#Run makepkg -g for old version. Since makepkg by default will compile for 64bit, we need to force the definition of CARCH, so that we can generate 32bit (i686) md5sums
#Add CARCH definition to first line of PKGBUILD
sed '1i CARCH=i686' PKGBUILD > junk && mv junk PKGBUILD
#run makepkg -g and store the result in a file
#delete the file (in case it existed) and create it again
if [ -f $file1 ]
then
rm $file1
fi
touch $file1
#Send md5sums to $file1
makepkg -g PKGBUILD >> $file1 
#restore the PKGBUILD by removing the first line
sed 1d PKGBUILD > junk && mv junk PKGBUILD

#Now run makepkg again (this time for x86_64)
makepkg -g PKGBUILD >> $file1

#Now we do the same for the new version 
#change version
update_version $1

#Set it up to compile for i686
sed '1i CARCH=i686' PKGBUILD > junk && mv junk PKGBUILD
if [ -f $file2 ]
then
rm $file2
fi
touch $file2 
#Send md5sums to $file2
makepkg -g PKGBUILD >> $file2 
sed 1d PKGBUILD > junk && mv junk PKGBUILD

#Send results with x86_64 to $file2
makepkg -g PKGBUILD >> $file2

#Count number of lines in $file1 (this is the number of sources that we need to verify)
nlines=`wc -l < $file1`
#Now use a while loop, where in iteration $i we look for expressions (in the PKGBUILD) matching the $line-th line of $file1 and replace those with the $line-th line of $file2  
line=1
while [ "$line" != "$(($nlines+1))" ]
do  
 #note how we combine head and tail to get a specific line of a file
 sed -e s/"`cat $file1 | head -n $line | tail -1`"/"`cat $file2 | head -n $line | tail -1`"/g  PKGBUILD > junk && mv junk PKGBUILD
 #go to the next line
 line=$(($line+1))
done

}

#If the 'source' field exists in the PKGBUILD, we update the md5sums 
if grep "source" PKGBUILD 
then
echo "Found 'source' variable"
#We create this temporary directory to work on
mkdir work
install * work

cd work
#Most of the stuff is done with updater
updater $1
#get the PKGBUILD back to its original place
install PKGBUILD ../PKGBUILD
cd ../


#clean up
if [ "$2" != "--clean=no" ]
then
echo "Cleaning up..." 
rm -rf work 
else
echo "" > /dev/null 
fi

else
#Otherwise we just update the version
echo "PKGBUILD does not have 'source' variable. Updating version to $1..."
update_version $1
fi


