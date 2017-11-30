#!/bin/bash
#!/usr/bin/bash 
## --

# Configuration file
CONFIGURATION_FILE=conf.ini

# DEFAULT_RPRO_PATH=/usr/local/red5pro
# MIN_JAVA_VERSION="1.8"
LOGGING=true
LOG_FILE_NAME=rpro_installer.log
LOG_FILE=$PWD/$LOG_FILE_NAME

OS_TYPE=
OS_DEB="DEBIAN"
OS_RHL="REDHAT"
 
SERVICE_LOCATION_V1=/etc/init.d
SERVICE_NAME_V1=red5pro 


SERVICE_LOCATION_V2=/lib/systemd/system
SERVICE_NAME_V2=red5pro.service


SERVICE_LOCATION=
SERVICE_NAME=


SERVICE_VERSION=1

RED5SH=red5.sh
SERVICE_INSTALLER=/usr/sbin/update-rc.d
IS_64_BIT=0
OS_NAME=
OS_VERSION=
MODE=0

PID=/var/run/red5pro.pid


JAVA_JRE_DOWNLOAD_URL="http://download.oracle.com/otn-pub/java/jdk/8u102-b14/"



JAVA_32_FILENAME="jre-8u102-linux-i586.rpm"
JAVA_64_FILENAME="jre-8u102-linux-x64.rpm"

RED5PRO_DEFAULT_DOWNLOAD_NAME="red5pro_latest.zip"
RED5PRO_DEFAULT_DOWNLOAD_FOLDER_NAME="tmp"
RED5PRO_DEFAULT_DOWNLOAD_FOLDER=

RED5PRO_DOWNLOAD_URL=
RED5PRO_MEMORY_PCT=80

RED5PRO_DEFAULT_MEMORY_PATTERN="-Xmx2g"

######################################################################################

################################## LOGGER ############################################



write_log()
{
	if [ $# -eq 0 ]; then
		return
	else
		if $LOGGING; then			
			logger -s $1 2>> $LOG_FILE
		fi
	fi
}




lecho()
{
	if [ $# -eq 0 ]; then
		return
	else
		echo $1

		if $LOGGING; then
			logger -s $1 2>> $LOG_FILE
		fi
	fi
}




clear_log()
{
	> $LOG_FILE
}



delete_log()
{
	rm $LOG_FILE
}


######################################################################################

############################ MISC ----- METHODS ######################################


cls()
{
	printf "\033c"
}




refresh()
{
	if [ "$MODE" -eq  1 ]; then
 	show_advance_menu
	else
 	show_simple_menu
	fi
}



pause()
{

	printf "\n"
	read -r -p 'Press any [ Enter ] key to continue...' key


	if [ "$MODE" -eq  1 ]; then
 	show_advance_menu
	else
 	show_simple_menu
	fi
}





pause_license()
{

	printf "\n"
	read -r -p 'Press [ Enter ] key to continue...' key

	show_licence_menu
}



empty_pause()
{
	printf "\n"
	read -r -p 'Press any [ Enter ] key to continue...' key
}


empty_line()
{
	printf "\n"
}



######################################################################################

############################ MISC TOOL INSTALLS ######################################



# Public
check_java()
{
	write_log "Checking java requirements"

	java_check_success=0
	has_min_java_version=0

	for JAVA in "${JAVA_HOME}/bin/java" "${JAVA_HOME}/Home/bin/java" "/usr/bin/java" "/usr/local/bin/java"
		do
			if [ -x "$JAVA" ]
			then
			break
		fi
	done


	if [ ! -x "$JAVA" ]; then
	  	lecho "Unable to locate Java. If you think you do have java installed, please set JAVA_HOME environment variable to point to your JDK / JRE."
	else
		JAVA_VER=$(java -version 2>&1 | sed 's/java version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')

		JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')

		lecho "Current java version is $JAVA_VERSION"

		JAVA_VERSION_MAJOR=`echo "${JAVA_VERSION:0:3}"`

		if (( $(echo "$JAVA_VERSION_MAJOR < $MIN_JAVA_VERSION" |bc -l) )); then
			has_min_java_version=0			
			lecho "You need to install a newer java version of java!"		
		else
			has_min_java_version=1
			lecho "Minimum java version is already installed!"
		fi
	fi

	if [ ! $# -eq 0 ]
	  then
	    pause
	fi

}




# Public
check_unzip()
{
	write_log "Checking for unzip utility"			
	unzip_check_success=0

	if isinstalled unzip; then
	unzip_check_success=1
	write_log "unzip utility was found"		
	else
	unzip_check_success=0
	lecho "unzip utility not found."				
	fi
}




# Public
check_wget()
{
	write_log "Checking for wget utility"	
	wget_check_success=0

	if isinstalled wget; then
	wget_check_success=1
	write_log "wget utility was found"
	else
	wget_check_success=0
	lecho "wget utility not found."
	fi
}


check_bc()
{
	write_log "Checking for bc utility"	
	bc_check_success=0

	if isinstalled bc; then
	bc_check_success=1
	write_log "bc utility was found"
	else
	bc_check_success=0
	lecho "bc utility not found."
	fi
}



check_jsvc()
{
	write_log "Checking for jsvc utility"	
	jsvc_check_success=0

	if isinstalled jsvc; then
	jsvc_check_success=1
	write_log "jsvc utility was found"
	else
	jsvc_check_success=0
	lecho "jsvc utility not found."
	fi
}


# Public
install_java()
{
	write_log "Installing java"	
	java_install_success=0


	if isDebian; then
	install_java_deb	
	else
	install_java_rhl
	fi
	

	# verify
	check_java

	# has_min_java_version=1

	if [ $has_min_java_version -eq 1 ]; then
		local default_jre="$(which java)";
		lecho "Java successfully installed at $default_jre"
		java_install_success=1
	else
		lecho "Could not install required version of java"
	fi
		
}



# Private
install_java_deb()
{
	lecho "Installing Java for Debian";
	apt-get install -y default-jre

	: '
	if repo_has_required_java_deb; then
		write_log "Installing java from repo -> default-jre"
		apt-get update
		apt-get install default-jre
	else
		write_log "Installing java from ppa custom repo -> oracle-java8-installer"		
		add-apt-repository ppa:webupd8team/java
		apt-get update

		apt-get install oracle-java8-installer
	fi
	'
}



# Private
install_java_rhl()
{
	lecho "Installing Java for CentOs";
	yum -y install java	

	: '

	if repo_has_required_java_rhl; then
		write_log "Installing java from repo -> default-jre"
		yum install java-1.8.0-openjdk
	else

		if [ $IS_64_BIT -eq 1 ]; then
			java_url=$JAVA_64_BIT
			java_installer=$JAVA_64_FILENAME
		else
			java_url=$JAVA_32_BIT
			java_installer=$JAVA_32_FILENAME
		fi

		write_log "Installing java from rpm -> oracle-java8-installer -> $java_url"
		cd ~


		# Remove installer if exists
		if [ -f $java_installer ]; then
			rm ~/$java_installer
		fi



		if [[ $java_downloaded -eq 0 ]]; then

			lecho "Downloading $java_url"

			wget --header "Cookie: oraclelicense=accept-securebackup-cookie" $java_url

			# if downloaded
			if [ -f $java_installer ]; then
				java_downloaded=1
				lecho "Downloading successful"
			else
				lecho "Failed to download java installer package"
			fi
		fi



		# install
		if [[ $java_downloaded -eq 1 ]]; then
			lecho "Installing package $java_installer"
			yum localinstall $java_installer
			rm ~/$java_installer
		fi
	fi
	'
}




# Public
install_jsvc()
{
	write_log "Installing jsvc"

	if isDebian; then
	install_jsvc_deb	
	else
	install_jsvc_rhl
	fi		
}



# Private
install_jsvc_deb()
{
	write_log "Installing jsvc on debian"
	apt-get install -y jsvc

	install_jsvc="$(which jsvc)";
	lecho "jsvc installed at $install_jsvc"
}



# Private
install_jsvc_rhl()
{
	write_log "Installing jsvc on rhl"
	yum -y install jsvc

	install_jsvc="$(which jsvc)";
	lecho "jsvc installed at $install_jsvc"
}




# Public
install_unzip()
{
	write_log "Installing unzip"

	if isDebian; then
	install_unzip_deb	
	else
	install_unzip_rhl
	fi		
}



# Private
install_unzip_deb()
{
	write_log "Installing unzip on debian"

	apt-get update
	apt-get install -y unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}



# Private
install_unzip_rhl()
{
	write_log "Installing unzip on rhle"

	# yup update
	yum -y install unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}




# Public
install_wget()
{
	write_log "Installing wget"

	if isDebian; then
	install_wget_deb	
	else
	install_wget_rhl
	fi		
}



install_bc()
{
	write_log "Installing bc"

	if isDebian; then
	install_bc_deb	
	else
	install_bc_rhl
	fi		
}


# Private
install_wget_deb()
{
	write_log "Installing wget on debian"

	apt-get update
	apt-get install -y wget

	install_wget="$(which wget)";
	lecho "wget installed at $install_wget"
}



# Private
install_wget_rhl()
{
	write_log "Installing wget on rhle"

	# yup update
	yum -y install wget

	install_wget="$(which wget)";
	lecho "wget installed at $install_wget"
}




# Private
install_bc_deb()
{
	write_log "Installing bc on debian"

	apt-get install -y bc

	install_bc="$(which bc)";
	lecho "bc installed at $install_bc"
}



# Private
install_bc_rhl()
{
	write_log "Installing bc on rhle"

	# yup update
	yum -y install bc

	install_bc="$(which bc)";
	lecho "bc installed at $install_bc"
}



# Public
add_update_java()
{
	install_java
}





######################################################################################

############################ RED5PRO OPERATIONS ######################################

modify_jvm_memory()
{
	
	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to Red5 Pro installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi


	check_current_rpro 1

	if [[ $rpro_exists -eq 1 ]]; then

		red5_sh_file=$rpro_path/$RED5SH

		if [ ! -f $red5_sh_file ]; then
	  		lecho "CRITICAL ERROR! $red5_sh_file was not found!"
			pause;
		else
			# red5_sh_content=`cat $red5_sh_file`
			lecho "Calculating maximum allocatable memory"
			sleep 1

			# JVM memory allocation
			eval_memory_to_allocate			
			alloc_phymem_string="-Xmx"$alloc_phymem_rounded"g"

			sed -i -e "s/-Xmx2g/$alloc_phymem_string/g" $red5_sh_file # improve this
			lecho "JVM memory size is set to $alloc_phymem_rounded Gb!"
			sleep 1

			if [ ! $# -eq 0 ];  then
				pause
			fi
		fi
	fi
}



# Private
eval_memory_to_allocate()
{
	low_mem_response=

	phymem=$(free -m|awk '/^Mem:/{print $2}') # Value in Mb
	# echo "Total Memory in MB = $phymem"
	alloc_phymem=$(awk "BEGIN { pc=${phymem}*${RED5PRO_MEMORY_PCT}/100; print int(pc);}") # calculate percentage to allocate
	alloc_phymem=$(bc <<< "scale=1;$alloc_phymem/1024") # Mb to Gb
	alloc_phymem_rounded=$(printf "%.0f" $alloc_phymem) # Round off

	if [[ "$alloc_phymem_rounded" -lt 2 ]]; then
		lecho "SEVERE!: System memory is insufficient for running this software.Installation cannot continue !!"
		read -r -p "Press any key to exit  " low_mem_response
		exit
	else 
		if [[ "$alloc_phymem_rounded" -eq 2 ]]; then	

			if [ $# -eq 0 ];  then
				read -r -p "WARNING!: System memory is is barely enough for running this software.Do you wish to continue ? [y/N] " low_mem_response
				case $low_mem_response in
				[yY][eE][sS]|[yY]) 
				;;
				*)
				sleep 1
				exit
				;;
				esac
			fi
			
		fi
	fi

}



# Private
download_latest()
{
	clear
	

	rpro_email_valid=0
	rpro_password_valid=0

	latest_rpro_download_success=0
	rpro_zip=

	lecho "Downloading latest Red5 Pro from red5pro.com"
	
	# create tmp directory
	#dir=`sudo mktemp -d` && cd $dir
	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	# echo $dir
	red5pro_com_login_form	
}



red5pro_com_login_form()
{

	rpro_form_valid=1
	echo "Please enter your 'red5pro.com' login details"
	
	echo "Enter Email : "
	read rpro_email

	echo "Enter Password : "
	# read rpro_passcode
	read -s rpro_passcode

	# simple validate email
	if echo "${rpro_email}" | grep '^[a-zA-Z0-9]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$' >/dev/null; then
		rpro_email_valid=1		
	else
		rpro_form_valid=0
		lecho "Invalid email string!"		
	fi
	
	# simple validate password
	if [ ! -z "$rpro_passcode" -a "$rpro_passcode" != " " ]; then
		rpro_password_valid=1		
	else
		rpro_form_valid=0
		lecho "Invalid password string!"
	fi


	# if all params are valid
	if [ "$rpro_form_valid" -eq "1" ]; then
	
		lecho "Attempting to log in with your credentials"

		# POST to site
		wget --server-response --save-cookies cookies.txt --keep-session-cookies --post-data="email=$rpro_email&password=$rpro_passcode" "https://account.red5pro.com/login" 2>$dir/wsession.txt
		wget_status=$(< $dir/wsession.txt)

		echo "$(cat $LOG_FILE)$wget_status" > $LOG_FILE	

		# Check http code
		wget_status_ok=0
		if [[ $wget_status == *"HTTP/1.1 200"* ]] 
		then
			wget_status_ok=1
		fi
		
		# if 200 then proceed
		if [ "$wget_status_ok" -eq "1" ]; then

			echo "Attempting to download latest Red5 Pro archive file to $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

			wget --load-cookies cookies.txt --content-disposition -p  https://account.red5pro.com/download/red5 -O "$RED5PRO_DEFAULT_DOWNLOAD_NAME"

			rpro_zip="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER/$RED5PRO_DEFAULT_DOWNLOAD_NAME"

			if [ -f $rpro_zip ] ; then
				find . -type f -not \( -name '*zip' \) -delete

				latest_rpro_download_success=1
			else
				lecho "Oops!! Seems like the archive was not downloaded properly to disk."
				pause	
			fi
		else
			lecho "Failed to authenticate with website!"
			read -r -p " -- Retry? [y/N] " try_login_response
			case $try_login_response in
			[yY][eE][sS]|[yY]) 
			download_latest
			;;
			*)
			latest_rpro_download_success=0
			;;
			esac
		fi
		
	else
		lecho "Invalid request parameters"
		read -r -p " -- Retry? [y/N] " try_login_response
		case $try_login_response in
		[yY][eE][sS]|[yY]) 
		download_latest
		;;
		*)
		latest_rpro_download_success=0
		;;
		esac
	fi

}





download_from_url()
{
	clear
	

	latest_rpro_download_success=0
	rpro_zip=
	RED5PRO_DOWNLOAD_URL=

	lecho "Downloading Red5 Pro from url"
	
	# create tmp directory
	#dir=`sudo mktemp -d` && cd $dir
	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	if [ -z "$RED5PRO_DOWNLOAD_URL" ]; then
		echo "Enter the Red5 Pro archive file URL source";
		read RED5PRO_DOWNLOAD_URL
	fi


	lecho "Attempting to download latest Red5 Pro archive file to $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

	wget -O "$RED5PRO_DEFAULT_DOWNLOAD_NAME" "$RED5PRO_DOWNLOAD_URL"

	rpro_zip="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER/$RED5PRO_DEFAULT_DOWNLOAD_NAME"

	if [ -f $rpro_zip ] ; then
		find . -type f -not \( -name '*zip' \) -delete

		latest_rpro_download_success=1
	else
		lecho "Oops!! Seems like the archive was not downloaded properly to disk."
		pause	
	fi

}





# Public
auto_install_rpro()
{
	write_log "Starting Red5 Pro auto-installer"

	red5_zip_install_success=0

	# Install prerequisites
	prerequisites

	


	# Download red5 zip from red5pro.com
	echo "Preparing to install Red5 Pro from 'red5pro.com'"
	sleep 2
	download_latest

	if [ "$latest_rpro_download_success" -eq 0 ]; then
		echo "Failed to download latest Red5 Pro distribution from 'red5pro.com'. Please contact support!"
		pause
	fi


	if [ -z "$rpro_zip" ]; then
		echo "Downloaded file could not be found or is invalid. Exiting now!"
		pause
	fi


	# Installing red5 from zip downloaded  from red5pro.com

	lecho "Installing Red5 Pro from $rpro_zip"
	sleep 2
	install_rpro_zip $rpro_zip

	if [ "$red5_zip_install_success" -eq 0 ]; then		
		lecho "Failed to install Red5 Pro distribution. Something went wrong!! Try again or contact support!"
	fi

	
	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}




auto_install_rpro_url()
{
	write_log "Starting Red5 Pro auto-installer"

	red5_zip_install_success=0

	# Install prerequisites
	prerequisites	


	# Download red5 zip from url
	echo "Preparing to install Red5 Pro from $RED5PRO_DOWNLOAD_URL"
	sleep 2
	download_from_url

	if [ "$latest_rpro_download_success" -eq 0 ]; then
		echo "Failed to download Red5 Pro distribution from $RED5PRO_DOWNLOAD_URL. Please contact support!"
		pause
	fi


	if [ -z "$rpro_zip" ]; then
		echo "Downloaded file could not be found or is invalid. Exiting now!"
		pause
	fi


	# Installing red5 from zip downloaded  from red5pro.com

	lecho "Installing Red5 Pro from $rpro_zip"
	sleep 2
	install_rpro_zip $rpro_zip $RED5PRO_DOWNLOAD_URL

	if [ "$red5_zip_install_success" -eq 0 ]; then		
		lecho "Failed to install Red5 Pro distribution. Something went wrong!! Try again or contact support!"
	fi

	
	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}




# Public
register_rpro_as_service()
{
	check_current_rpro 1

	if [ "$rpro_exists" -eq 1 ]; then

		write_log "Registering service for Red5 Pro"

		if [ -f "$SERVICE_LOCATION/$SERVICE_NAME" ]; then
		lecho "Service already exists. Do you wish to re-install ?" 
		read -r -p "Are you sure? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 
		register_rpro_service
		;;
		*)
		lecho "Service installation cancelled"
		;;
		esac

		else
		register_rpro_service
		fi
	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}




# Public
unregister_rpro_as_service()
{
	check_current_rpro 0

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$SERVICE_LOCATION/$SERVICE_NAME" ]; then
			lecho "Service does not exists. Nothing to remove" 
		else
			unregister_rpro_service
		fi

	fi

	if [ $# -eq 0 ]
	  then
	    pause
	fi
}





# Public
install_rpro_zip()
{
	red5_zip_install_success=0

	# Install prerequisites
	# prerequisites [ extra not needed ]
			
	clear
	lecho "Installing Red5 Pro from zip"
	

	if [ $# -eq 0 ]; then
		echo "Enter the full path to Red5 Pro distribution archive"
		read rpro_zip_path
	else 
		rpro_zip_path=$1
	fi

	write_log "Installing Red5 Pro from zip $rpro_zip_path"
	

	if [ ! -f "$rpro_zip_path" ]; then
		lecho "Invalid archive file path $rpro_zip_path"
		pause;
	fi


	filename=$(basename "$rpro_zip_path")
	extension="${filename##*.}"
	filename="${filename%.*}"
	filesize=$(stat -c%s "$rpro_zip_path")


	if [ "$filesize" -lt 30000 ]; then
		lecho "Invalid archive file size detected for $rpro_zip_path. Probable corrupt file!"
		pause;
	fi


	case "$extension" in 
	zip|tar|gz*) 
	    # All ok
	    ;;	
	*)
	    lecho "Invalid archive type $extension"
	    pause
	    ;;
	esac
	


	lecho "Attempting to install Red5 Pro from zip"

	dir="$RED5PRO_DEFAULT_DOWNLOAD_FOLDER"
	cd $dir

	unzip_dest="$dir/$filename"


	check_current_rpro 1
	
	if [ "$rpro_exists" -eq 1 ]; then

		lecho "An existing Red5 Pro installation was found at install destination.If you continue this will be replaced. The old installation will be backed up to $RPRO_BACKUP_HOME"

		sleep 1
		echo "Warning! All file(s) and folder(s) at $DEFAULT_RPRO_PATH will be removed permanently"
		read -r -p "Do you wish to continue? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY])

		# backup Red5 Pro
		backup_rpro

		if [ $rpro_backup_success -eq 0 ]; then
			# proceed to install new Red5 Pro
			lecho "Failed to create a backup of your existing Red5 Pro installation"
			pause
		fi	

		# remove rpro service
		unregister_rpro_service

		# check remove folder
		rm -rf $DEFAULT_RPRO_PATH

		;;
		*)
		lecho "Uninstall cancelled"
		pause
		;;
		esac	
	fi


	lecho "Unpacking archive to install location..."
	
	
	if ! unzip $rpro_zip_path -d $unzip_dest; then
		lecho "Failed to extract zip. Possible invalid archive"
		pause;
	fi


	if [ ! -d "$unzip_dest" ]; then
		lecho "Could not create output directory."
		pause;
	fi


	# Move to actual install location 
	rpro_loc=$DEFAULT_RPRO_PATH

	
	lecho "Moving files to install location : $rpro_loc"


	if [[ $# -gt 1 ]]; then

		if [ ! -d "$rpro_loc" ]; then
		  mkdir -p $rpro_loc
		fi

		mv -v $unzip_dest/* $rpro_loc
	else
		# Move to actual install location 
		rpro_loc=$DEFAULT_RPRO_PATH
		mv -v $unzip_dest/* $rpro_loc
	fi



	# DEFAULT_RPRO_PATH=/usr/local/red5pro

	lecho "Setting permissions ..."

	sleep 1

	chmod -R 755 $rpro_loc	

	chmod -R ugo+w $rpro_loc

	chmod +x $rpro_loc/*.sh


	# set path
	lecho "Setting RED5_HOME"
	sleep 1
	export RED5_HOME=$rpro
 

	# clear tmp directories - IMPORTANT
	lecho "cleaning up ..."
	sleep 1

	#rm -rf $dir
	rm -rf $unzip_dest

	sleep 1	

	if [ ! -d "$rpro_loc" ]; then
		lecho "Could not install Red5 Pro at $rpro_loc"
		pause
	else
		echo "All done! ..."
		lecho "Red5 Pro installed at  $rpro_loc"
		red5_zip_install_success=1
	fi


	# Install additional libraries
	postrequisites

	# JVM memory update
	modify_jvm_memory


	# Installing red5 service
	echo "For Red5 Pro to autostart with operating system, it needs to be registered as a service"
	read -r -p "Do you want to register Red5 Pro service now? [y/N] " response

	case $response in
	[yY][eE][sS]|[yY]) 
		
		lecho "Registering Red5 Pro as a service"

		sleep 2
		register_rpro_service
		
		if [ "$rpro_service_install_success" -eq 0 ]; then
		lecho "Failed to register Red5 Pro service. Something went wrong!! Try again or contact support!"
		pause
		fi
	;;
	*)
	;;
	esac

	
	# All Done
	lecho "Red5 Pro service is now installed on your system. You can start / stop it with from the menu".

	# Moving to home directory	
	cd ~

	if [ $# -eq 0 ]
	  then
	    pause
	fi
	
}





# Public
register_rpro_service()
{
	if [ "$SERVICE_VERSION" -eq "1" ]; then
	   register_rpro_service_v1
	else
	   register_rpro_service_v2
	fi	
}



# Public
unregister_rpro_service()
{
	
	if [ "$SERVICE_VERSION" -eq "1" ]; then
	   unregister_rpro_service_v1
	else
	   unregister_rpro_service_v2
	fi	
}






######################### V1 #########################


# Private
register_rpro_service_v1()
{

	rpro_service_install_success=0

	lecho "Preparing to install service..."
	sleep 2



service_script="#!/bin/sh
### BEGIN INIT INFO
# chkconfig: 2345 85 85
# description: Red5 Pro streaming server
# Provides:          Red5 Pro
# Required-Start:    \$local_fs \$network
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Red5 Pro
# processname: red5
### END INIT INFO

PROG=red5
RED5_HOME=$DEFAULT_RPRO_PATH
DAEMON=\$RED5_HOME/\$PROG.sh
PID=$PID

start() {
  # check to see if the server is already running
  if netstat -an | grep ':5080' > /dev/null 2>&1 ; then
    while netstat -an | grep ':5080' > /dev/null 2>&1 ; do
      # wait 5 seconds and test again
      sleep 5
    done
  fi
  cd \${RED5_HOME} && ./red5.sh > /dev/null 2>&1 &
}

stop() {
  cd \${RED5_HOME} && ./red5-shutdown.sh force > /dev/null 2>&1 &
}


case \"\$1\" in
  start)
    start
    exit 1
  ;;
  stop)
    stop
    exit 1
  ;;
  **)
    echo \"Usage: \$0 {start|stop}\" 1>&2
    exit 1
  ;;

esac"



	lecho "Writing service script"
	sleep 1

	touch /etc/init.d/red5pro

	# write script to file
	echo "$service_script" > /etc/init.d/red5pro

	sleep 1


	# make service file executable
	chmod 777 /etc/init.d/red5pro

	if isDebian; then
	register_rpro_service_deb	
	else
	register_rpro_service_rhl
	fi	


	lecho "Red5 Pro service installed successfully!"
	rpro_service_install_success=1
}





# Private
register_rpro_service_deb()
{
	lecho "Registering service \"$SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d red5pro defaults

	lecho "Enabling service \"$SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d red5pro enable
}



# Private
register_rpro_service_rhl()
{
	lecho "Registering service \"$SERVICE_NAME\""
	sleep 1

	systemctl daemon-reload
	

	lecho "Enabling service \"$SERVICE_NAME\""
	sleep 1

	systemctl enable red5pro.service
}





# Private
unregister_rpro_service_v1()
{
	rpro_service_remove_success=0
	
	prog="red5"

	lecho "Preparing to remove service..."
	sleep 2


	if [ -f /etc/init.d/red5pro ];	then
	

		# 1. Terminate service if running

		# 2. check PID file and check pid
		

		if isDebian; then
		unregister_rpro_service_deb	
		else
		unregister_rpro_service_rhl
		fi

		rm -rf /etc/init.d/red5pro

		lecho "Service removed successfully"
		rpro_service_remove_success=0
	
	else
		lecho "Red5 Pro service was not found"
	fi
}




# Private
unregister_rpro_service_deb()
{
	lecho "Disabling service \"$SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $SERVICE_NAME disable

	lecho "Removing service \"$SERVICE_NAME\""
	sleep 1

	/usr/sbin/update-rc.d $SERVICE_NAME remove
}




# Private
unregister_rpro_service_rhl()
{
	lecho "Disabling service \"$SERVICE_NAME\""
	sleep 1

	systemctl disable red5pro.service


	lecho "Removing service \"$SERVICE_NAME\""
	sleep 1
}


# Private
start_red5pro_service_v1()
{
	/etc/init.d/red5pro start /dev/null 2>&1 &
	sleep 15
}



# Private
stop_red5pro_service_v1()
{
	/etc/init.d/red5pro stop /dev/null 2>&1 &
}


# Private
restart_red5pro_service_v1()
{
	lecho "This feature is not supported in V1 service installer!"
}



####################### V2 #############################


# Private
register_rpro_service_v2()
{
	rpro_service_install_success=0


	lecho "Preparing to install service..."
	sleep 2


	# JVM memory allocation
	eval_memory_to_allocate 1
	JVM_MEMORY_ALLOC="-Xmx"$alloc_phymem_rounded"g"


	# Installing service manager
	prerequisites_jsvc


	if isDebian; then
	JAVA_ENV=/usr/lib/jvm/java-8-openjdk-amd64	
	else
	JAVA_ENV=/usr/lib/jvm/jre-1.8.0-openjdk
	fi



#######################################################



service_script="[Unit]
Description=Red5 Pro
After=syslog.target network.target

[Service]
Type=forking
Environment=PID=$PID
Environment=JAVA_HOME=$JAVA_ENV
Environment=RED5_HOME=$DEFAULT_RPRO_PATH
WorkingDirectory=$DEFAULT_RPRO_PATH
ExecStart=/usr/bin/jsvc -debug \
    -home \${JAVA_HOME} \
    -cwd \${RED5_HOME} \
    -cp \${RED5_HOME}/commons-daemon-1.0.15.jar:\${RED5_HOME}/red5-service.jar:\${RED5_HOME}/conf \
    -Dred5.root=\${RED5_HOME} \
    -Djava.library.path=\${RED5_HOME}/lib/amd64-Linux-gpp/jni \
    -Djava.security.debug=failure -Djava.security.egd=file:/dev/./urandom \
    -Dcatalina.home=\${RED5_HOME} -Dcatalina.useNaming=true \
    -Dorg.terracotta.quartz.skipUpdateCheck=true \
    -Xms256m $JVM_MEMORY_ALLOC -Xverify:none \
    -XX:+TieredCompilation -XX:+UseBiasedLocking \
    -XX:MaxMetaspaceSize=128m -XX:+UseParNewGC -XX:+UseConcMarkSweepGC \
    -XX:InitialCodeCacheSize=8m -XX:ReservedCodeCacheSize=32m \
    -outfile \${RED5_HOME}/log/jsvc-service.log -errfile \${RED5_HOME}/log/jsvc-error.log \
    -wait 60 \
    -umask 011 \
    -pidfile \${PID} org.red5.daemon.EngineLauncher 9999

ExecStop=/usr/bin/jsvc -stop -pidfile \${PID} org.red5.daemon.EngineLauncher 9999

[Install]
WantedBy=multi-user.target
"

#######################################################



	lecho "Writing service script"
	sleep 1

	touch /lib/systemd/system/red5pro.service

	# write script to file
	echo "$service_script" > /lib/systemd/system/red5pro.service

	# make service file executable
	chmod 644 /lib/systemd/system/red5pro.service

	register_rpro_service_generic_v2

	lecho "Red5 Pro service installed successfully!"
	rpro_service_install_success=1	
}







# Private
register_rpro_service_generic_v2()
{

	lecho "Registering service \"$SERVICE_NAME\""
	sleep 1	

	# Reload daemon 
	systemctl daemon-reload

	lecho "Enabling service \"$SERVICE_NAME\""

	# enable service
	systemctl enable red5pro.service
}



# Private
unregister_rpro_service_generic_v2()
{
	lecho "Unregistering service \"$SERVICE_NAME\""
	sleep 1	

	# Reload daemon 
	systemctl daemon-reload

	lecho "Disabling service \"$SERVICE_NAME\""

	# disaable service
	systemctl disable red5pro.service

	
}



# Private
unregister_rpro_service_v2()
{
	rpro_service_remove_success=0
	
	prog="red5"

	lecho "Preparing to remove service..."
	sleep 2


	if [ -f /lib/systemd/system/red5pro.service ];	then
	
		unregister_rpro_service_generic_v2

		# remove service
		rm -f /lib/systemd/system/red5pro.service

		lecho "Service removed successfully"
		rpro_service_remove_success=0
	
	else
		lecho "Red5 Pro service was not found"
	fi
}



# Private
start_red5pro_service_v2()
{
	systemctl start red5pro
}



# Private
stop_red5pro_service_v2()
{
	systemctl stop red5pro
}


# Private
restart_red5pro_service_v2()
{
	systemctl restart red5pro
}





############################################################



start_red5pro_service()
{
	cd ~

	check_current_rpro 1 1

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$SERVICE_LOCATION/$SERVICE_NAME" ];	then
			lecho "It seems Red5 Pro service was not installed. Please register Red5 Pro service from the menu for best results."
			lecho " Attempting to start Red5 Pro using \"red5.sh\""
		
			cd $DEFAULT_RPRO_PATH && exec $DEFAULT_RPRO_PATH/red5.sh > /dev/null 2>&1 &

		else
			lecho "Red5 Pro service was found at $SERVICE_LOCATION/$SERVICE_NAME"
			lecho " Attempting to start service"

			if [ "$SERVICE_VERSION" -eq "1" ]; then
				
				if !(is_running_red5pro_service 1); then
					start_red5pro_service_v1
				else
					lecho "Server is already running!" 
				fi
			else		

				if !(is_running_red5pro_service 1); then
					start_red5pro_service_v2
				else
					lecho "Server is already running!" 
				fi

			fi
		
		fi
	fi



	if [ $# -eq 0 ]
	  then
	    pause
	fi
}





stop_red5pro_service()
{
	cd ~

	check_current_rpro 1 1

	if [ "$rpro_exists" -eq 1 ]; then	


		if [ ! -f "$SERVICE_LOCATION/$SERVICE_NAME" ];	then
			lecho "It seems Red5 Pro service was not installed. Please register Red5 Pro service from the menu for best results."
			lecho " Attempting to stop using \"red5-shutdown.sh\""

			cd $DEFAULT_RPRO_PATH && exec $DEFAULT_RPRO_PATH/red5-shutdown.sh force > /dev/null 2>&1 &	
		else
			lecho "Red5 Pro service was found at $SERVICE_LOCATION/$SERVICE_NAME."
			lecho "Attempting to stop Red5 Pro service"

			if [ "$SERVICE_VERSION" -eq "1" ]; then	

				if is_running_red5pro_service 1; then
					stop_red5pro_service_v1
				else
					lecho "Server is not running!" 
				fi
				
			else
				if is_running_red5pro_service 1; then
					stop_red5pro_service_v2
				else
					lecho "Server is not running!" 
				fi
			fi
		fi
	fi


	if [ $# -eq 0 ]
	  then
	    pause
	fi
}





restart_red5pro_service()
{
	cd ~
	
	check_current_rpro 1 1

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$SERVICE_LOCATION/$SERVICE_NAME" ];	then
			lecho "It seems Red5 Pro service was not installed. Please register Red5 Pro service from the menu for to activate this feature."
		else
			lecho "Red5 Pro service was found at $SERVICE_LOCATION/$SERVICE_NAME."
			lecho "Attempting to restart Red5 Pro service"

			if [ "$SERVICE_VERSION" -eq "1" ]; then
				restart_red5pro_service_v1
			else
				restart_red5pro_service_v2
			fi
		fi
	fi


	if [ $# -eq 0 ]
	  then
	    pause
	fi
}


is_running_red5pro_service_v2()
{
	systemctl status red5pro | grep 'active (running)' &> /dev/null
	if [ $? == 0 ]; then
	   true
	else
	   false	
	fi
}




is_running_red5pro_service_v1()
{
	red5_grep=$(ps aux | grep red5)	
	echo "$red5_grep" | grep 'org.red5.server.Bootstrap' &> /dev/null

	if [ $? == 0 ]; then
	   true
	else
	   false	
	fi
}



is_running_red5pro_service()
{
	cd ~
	
	rpro_running=0
	check_current_rpro 1 1

	if [ "$rpro_exists" -eq 1 ]; then

		if [ ! -f "$SERVICE_LOCATION/$SERVICE_NAME" ];	then
			lecho "It seems Red5 Pro service was not installed. Please register Red5 Pro service from the menu for to activate this feature."
		else			

			if [ "$SERVICE_VERSION" -eq "1" ]; then
				if is_running_red5pro_service_v1; then
					rpro_running=1
				fi

			else
				if is_running_red5pro_service_v2; then
					rpro_running=1
				fi				
			fi
		fi
	fi


	if [ $# -eq 0 ]; then
	    pause
	else
	    if [ "$rpro_running" -eq 1 ]; then
		true
	    else
		false
	    fi
	fi
}



remove_rpro_installation()
{
	lecho "Looking for Red5 Pro at default location..."
	sleep 2

	if [ ! -d $DEFAULT_RPRO_PATH ]; then
  		lecho "No Red5 Pro installation found at default location : $DEFAULT_RPRO_PATH"
	else
		red5pro_ini="$DEFAULT_RPRO_PATH/conf/red5.ini" 

		if [ ! -f $red5pro_ini ]; then
		lecho "There were files found at default location : $DEFAULT_RPRO_PATH, but the installation might be broken !. I could not locate version information"
		else
		echo "Red5 Pro installation found at default location : $DEFAULT_RPRO_PATH"
		echo "Warning! All file(s) and folder(s) at $DEFAULT_RPRO_PATH will be removed permanently"
		read -r -p "Are you sure? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 
		# remove rpro service
		unregister_rpro_service
		# check remove folder
		rm -rf $DEFAULT_RPRO_PATH
		unset RED5_HOME
		if [ ! -d "$DEFAULT_RPRO_PATH" ]; then
			lecho "Red5 installation was removed"
		fi
		;;
		*)
		lecho "Uninstall cancelled"
		;;
		esac
		fi
	fi


	if [ $# -eq 0 ]; then
		pause		
	fi

	
}




check_current_rpro()
{
	rpro_exists=0
	check_silent=0

	# IF second param is set then turn on silent mode quick check
	if [ $# -eq 2 ]; then
		check_silent=1		
	fi


	if [ ! "$check_silent" -eq 1 ] ; then
		lecho "Looking for Red5 Pro at default install location..."
		sleep 2
	fi


	if [ ! -d $DEFAULT_RPRO_PATH ]; then
  		lecho "No Red5 Pro installation found at default location : $DEFAULT_RPRO_PATH"
	else
		red5pro_ini="$DEFAULT_RPRO_PATH/conf/red5.ini" 

		if [ ! -f $red5pro_ini ]; then
		lecho "There were files found at default location : $DEFAULT_RPRO_PATH, but the installation might be broken !. I could not locate version information"
		rpro_exists=1
		else
		rpro_exists=1

		if [ ! "$check_silent" -eq 1 ] ; then
		lecho "Red5 Pro installation found at default location : $DEFAULT_RPRO_PATH"
		fi

		pattern='server.version*'
		replace=""
		while IFS= read line
		do
			case "$line" in			
			$pattern) 
				if [ ! "$check_silent" -eq 1 ] ; then					
					red5pro_server_version=$(echo $line | sed -e "s/server.version=/${replace}/g")
					lecho "Red5 Pro build info : $red5pro_server_version" 
					break
				fi
			;;
			*) continue ;;
			esac
		
		done <"$red5pro_ini"

		fi
	fi



	if [ $# -eq 0 ]; then
		pause		
	fi
}



######################################################################################

####################### RED5PRO UPGRADE OPERATION MENU ###############################


## PRIVATE ###
restore_rpro()
{
	cls

	rpro_backup_restore_wizard=0

	RPRO_BACKUP_FOLDER=$1

	lecho "Initializing restore procedure..."

	echo "##########################################################################"
	echo "This interactive wizard will help you with some basic backup restore steps."
	echo "If you wish to skip a step you can always restore it manually later. Please" 
	echo "note that the restore actions cannot be undone!!"
	echo "##########################################################################"

	empty_pause
	
	empty_line
	
	lecho "Attempting to restore from $RPRO_BACKUP_FOLDER into $DEFAULT_RPRO_PATH. Please follow on-screen instructions carefully"

	sleep 2

	
	##################################################################################################
	################################### RESTORE LICENSE ##############################################
	empty_line
	echo "----------- STEP - 1 - LICENSE RESTORE -----------"
	empty_line
	read -r -p "Did you have a active Red5 Pro license in your backup that you wish to restore ? [y/N] " response
	LICENCE_KEY_FILE=$RPRO_BACKUP_FOLDER/LICENSE.KEY
	LICENCE_KEY_DEST_FILE=$DEFAULT_RPRO_PATH/LICENSE.KEY
	case $response in
	[yY][eE][sS]|[yY]) 

	if [ -f $LICENCE_KEY_FILE ]; then
		cp -rf $LICENCE_KEY_FILE $LICENCE_KEY_DEST_FILE
		if [ -f $LICENCE_KEY_DEST_FILE ]; then
			lecho "License file restored!"
		fi
	else
		lecho "No license file found to restore!"
	fi

	;;
	*)
	lecho "Skipping..."
	sleep 1
	;;
	esac




	##################################################################################################
	################################### RESTORE CLUSTERING ###########################################
	empty_line
	echo "----------- STEP - 2 - CLUSTERING CONFIGURATION RESTORE -----------"
	empty_line
	read -r -p "Did you have active clustering configuration (in red5-default.xml) that you wish to restore ? [y/N] " response
	CLUSTER_CONF_FILE=$RPRO_BACKUP_FOLDER/webapps/red5-default.xml
	CLUSTER_CONF_DEST_FILE=$DEFAULT_RPRO_PATH/webapps/red5-default.xml
	case $response in
	[yY][eE][sS]|[yY]) 

	if [ -f $CLUSTER_CONF_FILE ]; then
		cp -rf $CLUSTER_CONF_FILE $CLUSTER_CONF_DEST_FILE
		if [ -f $CLUSTER_CONF_DEST_FILE ]; then
			lecho "Cluster configuration restored!"
		fi
	else
		lecho "No Cluster configuration file found to restore!"
	fi

	;;
	*)
	lecho "Skipping..."
	sleep 1
	;;
	esac


	##################################################################################################
	################################### RESTORE APPLICATIONS #########################################
	empty_line
	echo "----------- STEP - 3 - WEBAPPS RESTORE -----------"
	empty_line
	read -r -p "Do you wish to restore applications ? [y/N] " response
	BACKUP_WEBAPPS_FOLDER="$RPRO_BACKUP_FOLDER/webapps"
	case $response in
	[yY][eE][sS]|[yY]) 

		lecho "Scanning for applications in backup...."
		apps_to_restore=0
		for i in $(ls -d "$BACKUP_WEBAPPS_FOLDER/"*/); 
			do 
				webapp=${i%%/}
				webapp="$(basename $webapp)"
				echo "Found $webapp"
				apps_to_restore=$((apps_to_restore+1))
			done

		echo "Total applications found = $apps_to_restore"
		sleep 2


	#################################################################################################
	
		apps_to_restore=0
		for i in $(ls -d "$BACKUP_WEBAPPS_FOLDER/"*/); 
		do 
			WEBAPP_PATH=${i}
			webapp=${i%%/}
			webapp="$(basename $webapp)"
			
			read -r -p "Do you wish to restore application $webapp : ? [y/N] " response
			case $response in
			[yY][eE][sS]|[yY]) 

			# Eval path
			DEST_WEBAPP_PATH="$DEFAULT_RPRO_PATH/webapps/$webapp"

			# Remove old
			lecho "Clearing target.. $DEST_WEBAPP_PATH"
			rm -rf $DEST_WEBAPP_PATH

			# Restore backup
			lecho "Copying files from $WEBAPP_PATH to $DEST_WEBAPP_PATH"
			cp -R $WEBAPP_PATH $DEST_WEBAPP_PATH
			chmod -R ugo+w $DEST_WEBAPP_PATH
			;;
			*)
			lecho "Skipping..."
			sleep 1
			;;
			esac
			
		done

	;;
	*)
	lecho "Skipping..."
	sleep 1
	;;
	esac


	#################################################################################################
	empty_line
	rpro_backup_restore_wizard=1	
	lecho "Restore wizard steps completed! IF your Red5 Pro installation does not work as expected please try restoring manually instead. - Thank you";
	empty_pause
	
}



## PRIVATE ###
backup_rpro()
{
	rpro_backup_success=0


	if [ ! -d "$RPRO_BACKUP_HOME" ]; then
	  mkdir -p $RPRO_BACKUP_HOME
	  chmod ugo+w $RPRO_BACKUP_HOME
	fi

	
	if [ -d "$RPRO_BACKUP_HOME" ]; then
	  
		lecho "Starting backup procedure..."
		sleep 2

		# echo "Stopping Red5 Pro if it was running..."
		stop_red5pro_service 1
		sleep 10

		lecho "Backing up... "
		sleep 5

		# Create backup folder
		t_now=`date +%Y-%m-%d-%H-%M-%S`
		RPRO_BACKUP_FOLDER="$RPRO_BACKUP_HOME/$t_now"

		# Copy all files to backup folder
		cp -R $DEFAULT_RPRO_PATH $RPRO_BACKUP_FOLDER
		sleep 2

		# Show notice to user that back up was saved
		if [ -d "$RPRO_BACKUP_FOLDER" ]; then
			if [ -f $red5pro_ini ]; then
				lecho "Your active Red5 Pro installation was backed up successfully to $RPRO_BACKUP_FOLDER"
				echo "You can restore any necessary file(s) later from the backup manually."
				chmod -R ugo+w $RPRO_BACKUP_FOLDER
				rpro_backup_success=1
			else
				lecho "Something went wrong!! Perhaps files were not copied properly"
			fi
		else
			lecho "WARNING! Could not create backup destination directory"
		fi

		empty_pause

	else
		lecho "Failed to create backup directory. Backup will be skipped..."

	fi

	
}





upgrade()
{
	upgrade_rpro_success=0

	# Determine upgrade type
	upgrade_from_zip=0


	if [ $# -eq 1 ]; then
		upgrade_from_zip=1
	else
		upgrade_from_zip=0		
	fi


	# Start process
	lecho "Initializing upgrade process..."
	sleep 2

	check_current_rpro 1

	if [ "$rpro_exists" -eq "1" ]; then
		upgrade_mode=1
		# echo "It is recommended that you make a backup of your old server files. "
		lecho "An existing Red5 Pro installation was found at install destination.If you continue this will be replaced. The old installation will be backed up to $RPRO_BACKUP_HOME"
		read -r -p "Do you wish to continue ? [y/N] " response

		case $response in
		[yY][eE][sS]|[yY]) 
		
		# backup Red5 Pro
		backup_rpro

		if [ $rpro_backup_success -eq 1 ]; then
			lecho "Preparing to install Red5 Pro"
			# proceed to install new Red5 Pro 
			if [ $upgrade_from_zip -eq 1 ]; then
			install_rpro_zip
			else
			auto_install_rpro 1
			fi
		else
			lecho "Failed to create a backup of your existing Red5 Pro installation"
			upgrade_clean $upgrade_from_zip
			# check install state here
			pause
		fi
		;;
		*)
		lecho "Upgrade cancelled"
		;;
		esac
	else
		upgrade_mode=0
		lecho "This option is invalid since there is no Red5 Pro installation to upgrade. You can upgrade only after a clean install!"
		# upgrade_clean $upgrade_from_zip
		# check install state here
	fi


	# If install is successful try restore....
	if [[ $red5_zip_install_success -eq 1 ]]; then

		if [[ $upgrade_mode -eq 1 ]]; then
			
			lecho "Congratulations!! You have successfully installed a new version of Red5 Pro" 
			read -r -p "Do you need any help with restoring your previous settings? [y/N] " response

			case $response in
			[yY][eE][sS]|[yY]) 		
				# start restore wizard
				if [ -d $RPRO_BACKUP_FOLDER ]; then
				restore_rpro $RPRO_BACKUP_FOLDER
				fi
			;;
			*)
			;;
			esac

		fi
	fi


	pause

}





## PRIVATE ###
upgrade_clean()
{
	# Determine upgrade type
	upgrade_from_zip=0

	if [ $# -eq 1 ]; then
		upgrade_from_zip=1
	else
		upgrade_from_zip=0		
	fi

	write_log "Initiating clean upgrade"
	read -r -p "Do you wish to proceed with a clean installation? [y/N] " response

	case $response in
	[yY][eE][sS]|[yY]) 
	if [ $upgrade_from_zip -eq 1 ]; then
	install_rpro_zip
	else
	auto_install_rpro
	fi
	;;
	*)
	lecho "Upgrade cancelled"
	;;
	esac
}



######################################################################################

############################ LICENSE OPERATIONS ######################################




check_license()
{
	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to Red5 Pro installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi


	check_current_rpro 1
	if [[ $rpro_exists -eq 1 ]]; then

		lic_file=$rpro_path/LICENSE.KEY

		write_log "Checking license"

		if [ ! -f $lic_file ]; then
	  		lecho "No license file found!. Please install a license."
		else
			value=`cat $lic_file`
			echo "Current license : $value"
			write_log "license found!"
		fi
	fi
	
	pause_license;	
}




set_update_license()
{

	if [[ $1 -eq 1 ]]; then
		echo "Enter the full path to Red5 Pro installation"
		read rpro_path
	else
		rpro_path=$DEFAULT_RPRO_PATH
	fi
	

	check_current_rpro 1
	if [[ $rpro_exists -eq 1 ]]; then

		lic_file="$rpro_path/LICENSE.KEY"
		lic_new=1

		if [ ! -f $lic_file ]; then
	  		echo "Installing license code : Please enter new license code and press [ Enter ]."
			read license_code
			write_log "Installing license code"
			if [ ! -f "$lic_file" ] ; then
		 		# if not create the file
				write_log "Creating license file $lic_file"
		 		touch "$lic_file"
		     	fi
		else
			lic_new=0
			cat $lic_file | while read line
			do
			echo "a line: $line"
			done
			echo "Updating license : Please enter new license code and press [ Enter ]."
			read license_code			
		fi

		

		license_code=$(echo $license_code | tr '[a-z]' '[A-Z]')
		write_log "Writing license code to file $license_code"
		printf $license_code > $lic_file;

		if [ $lic_new -eq 1 ]; then
		lecho "License installed"
		else
		lecho "License updated"
		fi
	fi
	

	pause_license;	
}






######################################################################################

############################ LICENSE MENU ############################################




show_licence_menu()
{
	licence_menu
	license_menu_read_options
}



licence_menu()
{

	cls

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " ----------- MANAGE LICENSE ------------- "
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. ADD / UPDATE LICENSE"
	echo "2. VIEW LICENSE"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "3. BACK TO MAIN MENU"
	echo "			  "   
}





license_menu_read_options(){


	local choice
	read -p "Enter choice [ 1 - 3] " choice
	case $choice in
		1) set_update_license 0 ;;
		2) check_license 0 ;;
		3) 
		if [ $MODE -eq  1]; then 
		show_advance_menu 
		else 
		show_simple_menu 
		fi 
		;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}




######################################################################################

############################ ADVANCE OPERATION MENU ################################



show_advance_menu()
{
	advance_menu
	advance_menu_read_options
}


advance_menu()
{

	cls

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " RED5 PRO INSTALLER - ADVANCE MODE         	"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. CHECK EXISTING RED5 PRO INSTALLATION"
	echo "2. WHICH JAVA AM I USING ?"
	echo "3. INSTALL RED5 PRO SERVICE"
	echo "4. UNINSTALL RED5 PRO SERVICE"
#	echo "5. UPGRADE RED5 PRO FROM LATEST"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "5. BACK TO MODE SELECTION"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "0. Exit"
	echo "                             "

}





advance_menu_read_options(){


	local choice
	read -p "Enter choice [ 1 - 5 | 0 to exit]] " choice
	case $choice in
		1) check_current_rpro ;;
		2) check_java 1 ;;
		3) register_rpro_as_service ;;
		4) unregister_rpro_as_service ;;
		# 4) upgrade ;;
		5) main ;;
		0) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2 && exit 0
	esac
}







######################################################################################

############################ SIMPLE OPERATION MENU ################################





show_simple_menu()
{
	simple_menu
	simple_menu_read_options
}





simple_menu()
{

	cls

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " RED5 PRO INSTALLER - BASIC MODE         	"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1. INSTALL LATEST RED5 PRO"
	echo "2. INSTALL RED5 PRO FROM URL"
	echo "3. REMOVE RED5 PRO INSTALLATION"
	echo "4. ADD / UPDATE RED5 PRO LICENSE"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "------ RED5 PRO SERVICE OPTIONS -----------"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "5. --- START RED5 PRO"
	echo "6. --- STOP RED5 PRO"
	echo "7. --- RESTART RED5 PRO"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "8. BACK TO MODE SELECTION"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "0. Exit"
	echo "                             "

}








simple_menu_read_options(){


	local choice
	read -p "Enter choice [ 1 - 7 | 0 to exit] " choice
	case $choice in
		# 1) check_current_rpro ;;
		1) auto_install_rpro ;;
		2) auto_install_rpro_url ;;
		3) remove_rpro_installation ;;
		4) show_licence_menu ;;
		5) start_red5pro_service ;;
		6) stop_red5pro_service ;;
		7) restart_red5pro_service ;;
		8) main ;;
		0) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2 && exit 0
	esac
}






######################################################################################

################################ INIT FUNCTIONS ######################################


load_configuration()
{

	if [ ! -f $CONFIGURATION_FILE ]; then
		echo "CRITICAL ERROR!! - Configuration file not found!"
		echo "Exiting..."
		exit 0
	fi


	# Load config values
	source "$CONFIGURATION_FILE"


	JAVA_32_BIT="$JAVA_JRE_DOWNLOAD_URL/$JAVA_32_FILENAME"
	JAVA_64_BIT="$JAVA_JRE_DOWNLOAD_URL/$JAVA_64_FILENAME"


	# Set install location if not set

	CURRENT_DIRECTORY=$PWD
	

	if [ -z ${DEFAULT_RPRO_INSTALL_LOCATION+x} ]; then 
		DEFAULT_RPRO_PATH="$CURRENT_DIRECTORY/$DEFAULT_RPRO_FOLDER_NAME"
	else
		DEFAULT_RPRO_PATH="$DEFAULT_RPRO_INSTALL_LOCATION/$DEFAULT_RPRO_FOLDER_NAME"			
	fi


	RED5PRO_DEFAULT_DOWNLOAD_FOLDER="$CURRENT_DIRECTORY/$RED5PRO_DEFAULT_DOWNLOAD_FOLDER_NAME"
	[ ! -d foo ] && mkdir -p $RED5PRO_DEFAULT_DOWNLOAD_FOLDER && chmod ugo+w $RED5PRO_DEFAULT_DOWNLOAD_FOLDER	
}



detect_system()
{

	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	if [ -f /etc/lsb-release ]; then
	    . /etc/lsb-release
	    OS_NAME=$DISTRIB_ID
	    OS_VERSION=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
	    OS_NAME=Debian  # XXX or Ubuntu??
	    OS_VERSION=$(cat /etc/debian_version)
	elif [ -f /etc/redhat-release ]; then
	    # TODO add code for Red Hat and CentOS here
	    OS_VERSION=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
	    OS_NAME=$(rpm -q --qf "%{RELEASE}" $(rpm -q --whatprovides redhat-release))
	else
	    OS_NAME=$(uname -s)
	    OS_VERSION=$(uname -r)
	fi

	case $(uname -m) in
	x86_64)
	    ARCH=x64  # AMD64 or Intel64 or whatever
	    IS_64_BIT=1
	    os_bits="64 Bit"
	    ;;
	i*86)
	    ARCH=x86  # IA32 or Intel32 or whatever
	    IS_64_BIT=0
	    os_bits="32 Bit"
	    ;;
	*)
	    # leave ARCH as-is
	    ;;
	esac

	echo -e "* Distribution: \e[36m$OS_NAME\e[m"
	write_log "Distribution: $OS_NAME"

	echo -e "* Version: \e[36m$OS_VERSION\e[m"
	write_log "Version: $OS_VERSION"

	echo -e "* Kernel: \e[36m$os_bits\e[m"
	write_log "Kernel: $os_bits"


	empty_line

	USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
	echo -e "* Home directory: \e[36m$USER_HOME\e[m"
	write_log "Home directory: $USER_HOME"

	RPRO_BACKUP_HOME="$USER_HOME/$DEFAULT_BACKUP_FOLDER"
	echo -e "* BackUp directory: \e[36m$RPRO_BACKUP_HOME\e[m"
	write_log "BackUp directory: $RPRO_BACKUP_HOME"

	
	echo -e "* Install directory: \e[36m$DEFAULT_RPRO_PATH\e[m"
	write_log "Install directory: $DEFAULT_RPRO_PATH"

	
	# echo -e "* Downloads directory: \e[36m$RED5PRO_DEFAULT_DOWNLOAD_FOLDER\e[m"
	write_log "Downloads directory: $RED5PRO_DEFAULT_DOWNLOAD_FOLDER"

	
	if [[ $OS_NAME == *"Ubuntu"* ]]; then
	OS_TYPE=$OS_DEB
	else
	OS_TYPE=$OS_RHL
	fi


	# Service installer mode selection
	if [ "$SERVICE_VERSION" -eq "1" ]; then
	SERVICE_LOCATION=$SERVICE_LOCATION_V1
	SERVICE_NAME=$SERVICE_NAME_V1
	echo -e "* Service Deployment : \e[36mClassic\e[m"
	else
	SERVICE_LOCATION=$SERVICE_LOCATION_V2
	SERVICE_NAME=$SERVICE_NAME_V2
	echo -e "* Service Deployment : \e[36mModern\e[m"
	fi


	write_log "OS TYPE $OS_TYPE"

}



simple_usage_mode()
{
	write_log "Basic mode selected"

	MODE=0

	simple_menu
	simple_menu_read_options
}




advance_usage_mode()
{
	write_log "Advance mode selected"

	MODE=1
	
	advance_menu
	advance_menu_read_options
}



welcome_menu()
{	
	cls


	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
	echo " RED5 PRO INSTALLER - W E L C O M E   M E N U"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

	detect_system

	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

	echo "                             "
	echo "1. BASIC MODE (Recommended)"
	echo "                             "
	echo "2. ADVANCE MODE"
	echo "                             "
	echo "0. Exit"
	echo "                             "
}




read_welcome_menu_options()
{
	
	local choice
	read -p "Enter choice [ 1 - 2 | 0 to exit] " choice
	case $choice in
		1) simple_usage_mode ;;
		2) advance_usage_mode ;;
		0) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}



main()
{
	welcome_menu
	read_welcome_menu_options
}




######################################################################################

############################ prerequisites FUNCTION ##################################

prerequisites()
{
	lecho "Checking installation prerequisites..."
	sleep 2

	prerequisites_update

	prerequisites_java
	prerequisites_unzip
	prerequisites_wget
	prerequisites_bc
}



prerequisites_java()
{

	# Checking java
	lecho "Checking java requirements"
	sleep 2
	check_java

	
	if [ "$has_min_java_version" -eq 0 ]; then
		echo "Installing latest java runtime environment..."
		sleep 2

		install_java
	fi 
}



prerequisites_update()
{

	if isDebian; then
	prerequisites_update_deb
	else
	prerequisites_update_rhl
	fi
}


prerequisites_update_deb()
{
	apt-get update
}



prerequisites_update_rhl()
{
	yum -y update
}




prerequisites_unzip()
{	
	check_unzip


	if [[ $unzip_check_success -eq 0 ]]; then
		echo "Installing unzip..."
		sleep 2

		install_unzip
	fi 
}




prerequisites_wget()
{
	
	check_wget


	if [[ $wget_check_success -eq 0 ]]; then
		echo "Installing wget..."
		sleep 2

		install_wget
	fi 
}




prerequisites_bc()
{
	
	check_bc


	if [[ $bc_check_success -eq 0 ]]; then
		echo "Installing bc..."
		sleep 2

		install_bc
	fi 
}



prerequisites_jsvc()
{
	check_jsvc


	if [[ $jsvc_check_success -eq 0 ]]; then
		echo "Installing jsvc..."
		sleep 2

		install_jsvc
	fi 
}






######################################################################################

########################### postrequisites FUNCTION ##################################



postrequisites()
{
	lecho "Resolving and installing additional dependencies.."
	sleep 2

	if isDebian; then
	postrequisites_deb
	else
	postrequisites_rhl
	fi	
}




postrequisites_rhl()
{
	write_log "Installing additional dependencies for RHLE"

	rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms
	rpm -ivh http://dl.atrpms.net/all/atrpms-repo-6-7.el6.x86_64.rpm
	yum -y update --skip-broken
	yum -y --enablerepo=atrpms install libva libvdpau1
}




postrequisites_deb()
{
	write_log "Installing additional dependencies for DEBIAN"

	apt-get install -y libva1 libva-drm1 libva-x11-1 libvdpau1
}



######################################################################################

############################## isinstalled FUNCTION ##################################


isinstalled()
{
	if isDebian; then
	isinstalled_deb $1 
	else
	isinstalled_rhl $1
	fi
}



isinstalled_rhl()
{
	if yum list installed "$@" >/dev/null 2>&1; then
	true
	else
	false
	fi
}


isinstalled_deb()
{
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1|grep "install ok installed")

	if [ -z "$PKG_OK" ]; then
	false
	else
	true
	fi
}


# Public
isDebian()
{
	if [ "$OS_TYPE" == "$OS_DEB" ]; then
	true
	else
	false
	fi
}




#################################################################################################

############################## repo_has_required_java FUNCTION ##################################




repo_has_required_java()
{
	if isDebian; then
	repo_has_required_java_deb
	else
	repo_has_required_java_rhl
	fi
}


repo_has_required_java_deb()
{
	local JAVA_REPO_VERSION=$(apt-cache policy default-jre | grep "Candidate:" | cut -d ":" -f3) 
	local REPO_VERSION=`echo $JAVA_REPO_VERSION | cut -f1 -d "-"`

	#echo $MIN_JAVA_VERSION
	#echo $REPO_VERSION

	if (( $(echo "$REPO_VERSION < $MIN_JAVA_VERSION" |bc -l) )); then		
		false		
	else
		true
	fi
}


repo_has_required_java_rhl()
{
	true
}




#################################################################################################



# Load configuration
load_configuration


# Start application
write_log "====================================="
write_log "	NEW INSTALLER SESSION	"
main
