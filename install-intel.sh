#!/bin/bash

#Author: onefire <onefire.myself@gmail.com>
#Date: 11/29/2012

#UPDATE: The 2013 version works with C++! (it used to be incompatible with newer versions of gcc) 

#This script installs the non commercial Fortran and C/C++ compilers from Intel on Linux machines. For systems based on deb, rpm or pkg packages, the script also checks for the dependencies required by the compilers (Java, gcc, gcc, cpio and libstdc++) and installs them if necessary. The script was tested with Linux Mint 13, Fedora 17 and an updated version of Arch Linux, but it should also work on similar systems (i.e, Ubuntu, Red Hat, etc). If you use something different like Gentoo, you may have to install the dependencies yourself. 

#On a newly installed Fedora 17, I had a couple of problems. First, unlike pretty much any other distro, wget is not installed by default, so you need to either install it (yum install wget) because the script needs it to download the files (alternatively, you can manually download the tarballs from Intel before runnihg the script). Second, you need to set selinux to "permissive" (by default, it is "enforcing), otherwise the install will fail. To do this, edit /etc/selinux/config and reboot the system. After the installation, you can set selinux to "enforcing"again if you want.

#On other distributions, I did not have problems.    

#TO DO: Extend this to other distributions

#The code downloads the files from Intel: http://software.intel.com/en-us/articles/non-commercial-software-download/ but you still need to go there and spend 5 minutes filling some forms so that they can send activation codes to your email. Those are entered by you during the install process.  

#The script should be run as root. If no command-line arguments are given, the script installs both compilers (i.e, the same as with "all"). So you can use just:
#./install-intel.sh  

#You can also use:
#sudo ./install-intel.sh all 
#Use the above if you want to install both compilers. If you just need the C/C++ compilers, use:
#sudo ./install-intel.sh cplusplus 
#If you just need the Fortran compiler, use:
#sudo ./install-intel.sh fortran 

#The code installs the 64 bit only versions of the compilers, not only because the files are shorter, but because otherwise we need to get 32 bit libraries (like gcc-multilib) which, from my experience, are a pain and create all sorts of compatibility issues. Plus, in the future nobody is going to use 32 bit machines, so development for those is not going to be very important. But it should be trivial to patch it so that it installs the multilib versions.

#cksums taken from Intel's website: http://software.intel.com/en-us/articles/intel-composer-xe-2013-checksums/ 
cksumfortran="1140271310 647729243"
cksumcpp="3813715153 1047260116"

#compiler versions
version_fortran="2013.4.183"
version_cpp="2013.4.183"

#sources
source_fortran="http://registrationcenter-download.intel.com/akdlm/irc_nas/3174/l_fcompxe_intel64_$version_fortran.tgz"
source_cpp="http://registrationcenter-download.intel.com/akdlm/irc_nas/3173/l_ccompxe_intel64_$version_cpp.tgz"

echo "Checking dependencies..."
#For Debian systems (Linux Mint, Ubuntu, etc) only, check if the dependencies are installed, otherwise install them
check_debian() 
{
	echo "This system seems to be based on Debian"

	if [ `which java` ]; then
		echo "Java is already installed"
	else
		echo "Installing Java..."
		apt-get -y install icedtea-plugin
	fi

	if [ `which gcc` ]; then
		echo "gcc is already installed"
	else
		echo "Installing gcc..."
		apt-get -y install gcc
	fi

	if [ `which g++` ]; then
		echo "g++ is already installed"
	else
		echo "Installing g++..."
		apt-get -y install g++
	fi

	if [ `which cpio` ]; then
		echo "cpio is already installed"
	else
		echo "Installing cpio..."
		apt-get -y install cpio
	fi

	if [ `dpkg -s libstdc++6 | grep "is not installed"` ]; then
		echo "Installing libstdc++6..."
		apt-get -y install libstdc++6 
	else
		echo "libstdc++6 is already installed"
	fi 

	echo "End of dependencies check"
}

#Check in case its Arch Linux
check_arch() 
{
	echo "Found Arch Linux" 

	if [ `which java` ]; then
		echo "Java is already installed"
	else
		echo "Installing Java..."
		pacman -S jre7-openjdk --noconfirm
	fi

	#In Arch Linux, g++ is included in the gcc package
	if [ `which gcc` ]; then
		echo "gcc is already installed"
	else
		echo "Installing gcc..."
		pacman -S gcc --noconfirm
	fi

	if [ `which cpio` ]; then
		echo "cpio is already installed"
	else
		echo "Installing cpio..."
		pacman -S cpio --noconfirm
	fi

	#wget is no longer installed by default on Arch Linux
	if [ `which wget` ]; then
		echo "wget is already installed"
	else
		echo "Installing wget..."
		pacman -S wget --noconfirm
	fi

	#In Arch the standard repositories still have libstdc++5 (kind of weird, check this later...) 
	if [ "`pacman -Qs libstdc++5`" ]; then
		echo "libstdc++5 is already installed"
	else
		echo "Installing libstdc++5..."
		pacman -S libstdc++5 --noconfirm 
	fi

	echo "End of dependencies check"
}

#Check for rpm based distributions
check_rpm() 
{
	echo "This system seems to use rpm packages" 

	if [ `which java` ]; then
		echo "Java is already installed"
	else
		echo "Installing Java..."
		yum -y install java
	fi

	if [ `which gcc` ]; then
		echo "gcc is already installed"
	else
		echo "Installing gcc..."
		yum -y install gcc
	fi

	if [ `which g++` ]; then
		echo "g++ is already installed"
	else
		echo "Installing g++..."
		yum -y install gcc-c++
	fi

	if [ `which cpio` ]; then
		echo "cpio is already installed"
	else
		echo "Installing cpio..."
		yum -y install cpio
	fi

	if [ `rpm -qa | grep -i libstdc++` ]; then
		echo "libstdc++ is already installed"
	else
		echo "Installing libstdc++..."
		yum -y install libstdc++
	fi

	echo "End of dependencies check"
}

fortran() 
{
	cd $dir0
	#Check if the correct version exists in the current directory. If it does not, download it.
	if [ -f l_fcompxe_intel64_$version_fortran.tgz ]; then
		echo "Found l_fcompxe_intel64_$version_fortran.tgz" 
	else

	#Download the multilib version of the compiler
		wget $source_fortran 
	fi

	#Check the authenticity of the download
	echo "Checking authenticity of the download..."
	echo "$cksumfortran l_fcompxe_intel64_$version_fortran.tgz" > cksumfortran.txt
	if [ "`cksum l_f*.tgz`" = "`cat cksumfortran.txt`" ]; then
		echo "CKSUM TEST PASSED! PROCEEDING WITH THE INSTALLATION OF THE INTEL FORTRAN COMPILER..."
	elif [ "`cksum l_f*.tgz`" != "`cat cksumfortran.txt`" ]; then
		echo "ERROR!! CANNOT VERIFY THE AUTHENTICITY OF THE DOWNLOAD. EXITING NOW..."
		exit 1
	fi

	#Now extract the files, cd to the new directory and run Intel's installation script
	tar -xzvf l_fc*.tgz
	cd l_fc*
	./install.sh 

	#Add the compilers to the PATH (only do it if it was not done already) 
	if [ ! -f /etc/profile.d/intel.sh -o "`cat /etc/profile.d/intel.sh`" != "export PATH=/opt/intel/composer_xe_$version_fortran/bin/intel64:\$PATH" ]; then
		echo "export PATH=/opt/intel/composer_xe_$version_fortran/bin/intel64:\$PATH" > /etc/profile.d/intel.sh 
	fi
}

cplusplus() 
{
	cd $dir0
	if [ -f l_ccompxe_intel64_$version_cpp.tgz ]; then
		echo "Found l_ccompxe_intel64_$version_cpp.tgz"
	else  
	#Download the multilib C/C++ compiler (the 2013 version works with C++!) 
		wget $source_cpp
	fi

	#Check the authenticity of the download
	echo "Checking authenticity of the download..."
	echo "$cksumcpp l_ccompxe_intel64_$version_cpp.tgz" > cksumc++.txt
	if [ "`cksum l_c*.tgz`" = "`cat cksumc++.txt`" ]; then
		echo "CKSUM TEST PASSED! PROCEEDING WITH THE INSTALLATION OF THE INTEL C/C++ COMPILERS..."
	elif [ "`cksum l_c*.tgz`" != "`cat cksumc++.txt`" ]; then
		echo "ERROR!! CANNOT VERIFY THE AUTHENTICITY OF THE DOWNLOAD. EXITING NOW..."
		exit 1
	fi

	#Now extract the files, cd to the new directory and run Intel's installation script
	tar -xzvf l_c*.tgz
	cd l_c*
	./install.sh 

		#Add the compilers to the PATH (only do it if it was not done already) 
	if [ ! -f /etc/profile.d/intel.sh -o "`cat /etc/profile.d/intel.sh`" != "export PATH=/opt/intel/composer_xe_$version_cpp/bin/intel64:\$PATH" ]; then
		echo "export PATH=/opt/intel/composer_xe_$version_cpp/bin/intel64:\$PATH" > /etc/profile.d/intel.sh 
	fi
}

#Call the appropriate checks according to what we see in /var/cache
if [ -d /var/cache/apt ]; then
	check_debian
elif [ -d /var/cache/pacman ]; then
	check_arch
elif [ -d /var/cache/yum ]; then
	check_rpm
fi

#record the current directory in case Intel's script change it
dir0=`pwd`

#Both Fortran and C/C++ are installed if user runs the script with no arguments or with "all" as the first argument. Otherwise, only one of the compilers is installed.
if [ "$1" = "" -o "$1" = "all" ]; then 
	fortran
	cplusplus
elif [ $1 = "fortran" -o $1 = "cplusplus" ]; then
	$1
fi

#clean up
cd $dir0
rm -rf l_fcompxe_intel64_$version_fortran l_ccompxe_intel64_$version_cpp
rm *cksum*.txt

