#!/bin/bash

#Author: onefire <onefire.myself@gmail.com>
#Date: 09/26/2012

#UPDATE: The 2013 version works with C++! (it used to be incompatible with newer versions of gcc) 

#This script installs the non commercial Fortran and C/C++ compilers from Intel on Linux machines. For systems based on deb, rpm or pkg packages, the script also checks for the dependencies required by the compilers (Java, gcc, gcc, cpio and libstdc++) and installs them if necessary. The script was tested with Linux Mint 13, Fedora 17 and an updated version of Arch Linux, but it should also work on similar systems (i.e, Ubuntu, Red Hat, etc). If you use something different like Gentoo, you may have to install the dependencies yourself. 

#On a newly installed Fedora 17, I had a couple of problems. First, unlike pretty much any other distro, wget is not installed by default, so you need to either install it (yum install wget) because the script needs it to download the files (alternatively, you can manually download the tarballs from Intel before runnihg the script). Second, you need to set selinux to "permissive" (by default, it is "enforcing), otherwise the install will fail. To do this, edit /etc/selinux/config and reboot the system. After the installation, you can set selinux to "enforcing"again if you want.

#On other distributions, I did not have problems.    

#TO DO: Extend this to other distributions

#The code downloads the files from Intel: http://software.intel.com/en-us/articles/non-commercial-software-download/ but you still need to go there and spend 5 minutes filling some forms so that they can send activation codes to your email. Those are entered by you during the install process.  

#This script should be run as root. Suppose that your username is Joe (and your home folder is /home/Joe. In this case you can type (replace Joe with your user name)
#sudo ./install-intel.sh all Joe
#Use the above if you want to install both compilers. If you just need the C/C++ compilers, use:
#sudo ./install-intel.sh cplusplus Joe
#If you just need the Fortran compiler, use:
#sudo ./install-intel.sh fortran Joe  

#UPDATE: The comment below is no longer true. The current version installs both 32 bit and 64 bit tools.
#The code installs the 64 bit only versions of the compilers, not only because the files are shorter, but because otherwise we need to get 32 bit libraries (like gcc-multilib) which, from my experience, are a pain and create all sorts of compatibility issues. Plus, in the future nobody is going to use 32 bit machines, so development for those is not going to be very important. But it should be trivial to patch it so that it installs the multilib versions.

#Second argument is the name of the user 
user=$2

#cksums taken from Intel's website: http://software.intel.com/en-us/articles/intel-composer-xe-2011-checksums/ 
cksumfortran="538868532 877165394"
cksumcpp="2320263956 1615454731"

echo "Checking dependencies..."
#For Debian systems (Linux Mint, Ubuntu, etc) only, check if the dependencies are installed, otherwise install them
check_debian() {
echo "This system seems to be based on Debian"

if [ `which java` ]
then
echo "Java is already installed"
else
echo "Installing Java..."
apt-get -y install icedtea-plugin
fi

if [ `which gcc` ]
then
echo "gcc is already installed"
else
echo "Installing gcc..."
apt-get -y install gcc
fi

if [ `which g++` ]
then
echo "g++ is already installed"
else
echo "Installing g++..."
apt-get -y install g++
fi

if [ `which cpio` ]
then
echo "cpio is already installed"
else
echo "Installing cpio..."
apt-get -y install cpio
fi

if [ `dpkg -s libstdc++6 | grep "is not installed"` ]
then
echo "Installing libstdc++6..."
apt-get -y install libstdc++6 
else
echo "libstdc++6 is already installed"
fi 

echo "End of dependencies check"
}

#Check in case its Arch Linux
check_arch() {
echo "Found Arch Linux" 

if [ `which java` ]
then
echo "Java is already installed"
else
echo "Installing Java..."
pacman -S jre7-openjdk --noconfirm
fi

#In Arch Linux, g++ is included in the gcc package
if [ `which gcc` ]
then
echo "gcc is already installed"
else
echo "Installing gcc..."
pacman -S gcc --noconfirm
fi

if [ `which cpio` ]
then
echo "cpio is already installed"
else
echo "Installing cpio..."
pacman -S cpio --noconfirm
fi

#In arch the standard repositories still have libstdc++5 (kind of weird, check this later...) 
if [ `pacman -Qs libstdc++5` ]
then
echo "libstdc++5 is already installed"
else
echo "Installing libstdc++5..."
pacman -S libstdc++5 --noconfirm 
fi

echo "End of dependencies check"
}

#Check for rpm based distributions
check_rpm() {
echo "This system seems to use rpm packages" 

if [ `which java` ]
then
echo "Java is already installed"
else
echo "Installing Java..."
yum -y install java
fi

if [ `which gcc` ]
then
echo "gcc is already installed"
else
echo "Installing gcc..."
yum -y install gcc
fi

if [ `which g++` ]
then
echo "g++ is already installed"
else
echo "Installing g++..."
yum -y install gcc-c++
fi

if [ `which cpio` ]
then
echo "cpio is already installed"
else
echo "Installing cpio..."
yum -y install cpio
fi

#In arch the standard repositories still have libstdc++5 (kind of weird, check this later...) 
if [ `rpm -qa | grep -i libstdc++` ]
then
echo "libstdc++ is already installed"
else
echo "Installing libstdc++..."
yum -y install libstdc++
fi

echo "End of dependencies check"
}
if [ -d /var/cache/apt ]
then
check_debian
fi
if [ -d /var/cache/pacman ]
then 
check_arch
fi
if [ -d /var/cache/yum ]
then 
check_rpm
fi

#record the current directory in case Intel's script change it
dir0=`pwd`

fortran() {
cd $dir0
#Check if the correct version exists in the current directory. If it does not, download it.
if [ -f l_fcompxe_2013.0.079.tgz ]
then
echo "Found l_fcompxe_2013.0.079.tgz" 
else
#Download the multilib version of the compiler
wget http://registrationcenter-download.intel.com/akdlm/irc_nas/2724/l_fcompxe_2013.0.079.tgz
fi

#Check the authenticity of the download
echo "Checking authenticity of the download..."
echo "$cksumfortran l_fcompxe_intel64_2011.9.293.tgz" > cksumfortran.txt
if [ "`cksum l_f*.tgz`" = "`cat cksumfortran.txt`" ]
then
echo "CKSUM TEST PASSED! PROCEEDING WITH THE INSTALLATION OF THE INTEL FORTRAN COMPILER..."
fi
if [ "`cksum l_f*.tgz`" != "`cat cksumfortran.txt`" ]
then
echo "ERROR!! CANNOT VERIFY THE AUTHENTICITY OF THE DOWNLOAD. EXITING NOW..."
exit 1
fi

#Now extract the files, cd to the new directory and run Intel's installation script
tar -xzvf l_fc*.tgz
cd l_fc*
./install.sh 

#Setup .bashrc so that the system can find the compiler
echo "source /opt/intel/composer_xe_2011_sp1.9.293/bin/compilervars.sh intel64" >> /home/$user/.bashrc
}

cplusplus() {
cd $dir0
if [ -f l_ccompxe_2013.0.079.tgz ]
then
echo "Found l_ccompxe_2013.0.079.tgz"
else  
#Download the multilib C/C++ compiler (the 2013 version works with C++!) 
wget http://registrationcenter-download.intel.com/akdlm/irc_nas/2723/l_ccompxe_2013.0.079.tgz
fi

#Check the authenticity of the download
echo "Checking authenticity of the download..."
echo "$cksumcpp l_ccompxe_intel64_2011.10.319.tgz" > cksumc++.txt
if [ "`cksum l_c*.tgz`" = "`cat cksumc++.txt`" ]
then
echo "CKSUM TEST PASSED! PROCEEDING WITH THE INSTALLATION OF THE INTEL C/C++ COMPILERS..."
fi
if [ "`cksum l_c*.tgz`" != "`cat cksumc++.txt`" ]
then
echo "ERROR!! CANNOT VERIFY THE AUTHENTICITY OF THE DOWNLOAD. EXITING NOW..."
exit 1
fi

#Now extract the files, cd to the new directory and run Intel's installation script
tar -xzvf l_c*.tgz
cd l_c*
./install.sh 

echo "source /opt/intel/bin/compilervars.sh intel64" >> /home/$user/.bashrc
}

#Both Fortran and C/C++ are installed if user runs the script with all as the first argument. Otherwise, only one of the compilers is installed.
if [ $1 = "all" ]
then 
fortran
cplusplus
else
$1
fi

#clean up
cd $dir0
rm -rf l_fcompxe_intel64_2011.9.293 l_ccompxe_intel64_2011.10.319
rm *cksum*.txt










