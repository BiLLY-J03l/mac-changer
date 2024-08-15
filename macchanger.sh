#!/usr/bin/bash

#author ==> billy_j03l

#reminders:
  # $# no of args
  # $@ args passed by user
  # $0 name of script
  # $1 first arg by user
  # $? The exit status of the last command executed


#commands:	ifconfig <interface> down
#		ifconfig <interface> hw ether <desired mac>
#		ifconfig <interface> up

#what this script should do?
#
#
#1-check if user is root --> root_check funciton
#2-takes an interface and a mac input(random or specefic)
#3-check if the interface is valid --> interface_check function
#4-check if the input is valid --> mac_check function
#5-make sure that input is different from the current mac --> mac_compare function
#6-apply commands and checking for any errs in the process:
#	a- ifconfig <interface> down --> interface_down function
#	b- ifconfig <interface> hw ether <desired mac> --> mac_assign function
#	c- ifconfig <interface> up --> interface_up function
#
#
#
#
#integers comparison:
#	-eq equal
#	-ne not equal
#	-lt less than
#	-le less than or equal
#	-gt greater than
#	-ge greater than equal




############ FUNCTIONS #############

root_check(){
	if [[ $(whoami) == "root" ]];then
		return 0
	else
		return 1
	fi
}

mac_check(){
	local mac=$1
	printf "[+] checking mac validity..\n"
	printf "$mac" | grep -E "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]" &> /dev/null
	if [[ $? -eq 0 ]];then
		return 0
	else
		return 1
	fi
}

mac_compare(){
	local interface=$2
	local new_mac=$1
	local old_mac=$(ifconfig $interface | grep -Eo "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]")
	old_mac_low=${old_mac,,}
	new_mac_low=${new_mac,,}
	printf "[+] comparing the new and the current mac..\n"
	if [[ $old_mac_low == $new_mac_low ]];then
		return 1
	else
		return 0
	fi
}

random_mac(){
	hexdump -n 6 -ve '1/1 "%.2x "' /dev/random | awk -v a="2,6,a,e" -v r="$RANDOM" 'BEGIN{srand(r);}NR==1{split(a,b,",");r=int(rand()*4+1);printf "%s%s:%s:%s:%s:%s:%s\n",substr($1,0,1),b[r],$2,$3,$4,$5,$6}'
}

interface_check(){
	local iface=$1
	printf "[+] checking for $iface..\n"
	ifconfig $iface &> /dev/null
	if [[ $? -eq 0 ]];then
		return 0
	else
		return 1
	fi
}

interface_down(){
	local iface=$1
	printf "[+] shutting down $iface...\n"
	ifconfig $iface down &> /dev/null
	if [[ $? -eq 0 ]];then
		return 0
	else
		return 1
	fi
}

mac_assign(){
	local iface=$1
	local mac=$2
	printf "[+] assigning $mac to $iface...\n"
	ifconfig $iface hw ether $mac &> /dev/null
	if [[ $? -eq 0 ]]; then
		return 0
	else
		return 1
	fi
}

interface_up(){
	local iface=$1
	printf "[+] starting $iface\n"
	ifconfig $iface up &> /dev/null
	if [[ $? -eq 0 ]];then
		return 0
	else
		return 1
	fi
}


usage_msg(){
	printf "[-] Usage: $0 -i/--interface <interface> -m/--mac <desired MAC>\n"
	printf "[-] Usage(random): $0 -i/--interface <interface> -r/--random\n"
	printf "[-] e.g. -m/--mac XX:XX:XX:XX:XX:XX\n"
}


ok_msg(){
	printf "[+] done.\n"
}

final_msg(){
	printf "\n\n[*] old mac = $old_mac_low\n"	
	printf "[*] current mac = $new_mac_low\n"
}

err_msg(){
	local iface=$2
	local mac=$3
	case $1 in
		1)printf "[x] $iface is not available..\n";exit 1;;
		2)printf "[x] the mac you entered is invalid\n";exit 1;;
		3)printf "[x] the mac you entered is already assigned\n";exit 1;;
		4)printf "[x] err in shutting down $iface..\n";exit 1;;
		5)printf "[x] err in assigning $mac to $iface..\n";printf "[x] restarting $interface and exiting..\n\n";ifconfig $interface up;exit 1;;
		6)printf "[x] err in starting $iface..\n";exit 1;;
		7)printf "[x] err in generating random mac..\n";exit 1;;
	esac
}


######################### START ##############################

figlet MACCHANGER
printf "\n\n\t\t\t\tby Billy_J03l\n\n\n"




root_check
if [[ $? -eq 0 ]]
then
	if [[ $# -eq 4 ]] || [[ $# -eq 3 ]]
	then
		if [[ $1 == "--interface" ]] || [[ $1 == "-i" ]];then		#$1 --> i/interface  $3 --> m/mac OR r/random
			interface=$2
			if [[ $3 == "--mac" ]] || [[ $3 == "-m" ]];then	
				mac=$4
				interface_check $interface
				if [[ $? -eq 0 ]];then
					ok_msg
					mac_check $mac
					if [[ $? -eq 0 ]];then
						ok_msg
						mac_compare $mac $interface
						if [[ $? -eq 0 ]];then
							ok_msg							
							interface_down $interface
							if [[ $? -eq 0 ]];then
								ok_msg
								mac_assign $interface $mac
								if [[ $? -eq 0 ]];then
									ok_msg
									interface_up $interface
									if [[ $? -eq 0 ]];then
										ok_msg
										final_msg
										exit 0
									else
										err_msg 6 $interface
										#printf "[x] error in starting $interface"
									fi
								else
									err_msg 5 $interface $mac
									#printf "[x] error in assigning the new mac to $interface"
								fi
							else
								err_msg 4 $interface
								#printf "[x] error in shutting down $interface"				
							fi					
						else
							err_msg 3
							#printf "[x] the mac you entered is the same as your current mac..\n"
							
						fi
						
					else
						err_msg 2
						#printf "[x] the mac you entered is invalid.."
					fi

				else
					err_msg 1 $interface
					#printf "[x] $interface is not found.."
				fi
			elif [[ $3 == "--random" ]] || [[ $3 == "-r" ]];then
				interface_check $interface
				if [[ $? -eq 0 ]];then
					ok_msg
					mac=$(random_mac)
					mac_check $mac
					while [[ $? -ne 0 ]]
					do
						mac=$(random_mac)
						mac_check $mac
					done
					ok_msg
					mac_compare $mac $interface
					if [[ $? -eq 0 ]];then
						ok_msg
						interface_down $interface
						if [[ $? -eq 0 ]];then
							ok_msg
							mac_assign $interface $mac
							if [[ $? -eq 0 ]];then
								ok_msg
								interface_up $interface
								if [[ $? -eq 0 ]];then
									ok_msg
									final_msg
									exit 0	
								else
									err_msg 6 $interface
								fi
							else
								err_msg 5 $interface $mac
							fi
						else
							err_msg 4 $interface
						fi
					else
						err_msg 3 $interface $mac
					fi
				else
					err_msg 1 $interface
				fi
			else
				printf "[x] Argument Error..\n"
				usage_msg
				exit 1
			fi

		elif [[ $1 == "--mac" ]] || [[ $1 == "-m" ]];then		#$1 --> m/mac  $3 --> i/interface
			mac=$2
			if [[ $3 == "--interface" ]] || [[ $3 == "-i" ]];then
				interface=$4
				interface_check $interface
				if [[ $? -eq 0 ]];then
					ok_msg
					mac_check $mac
					if [[ $? -eq 0 ]];then
						ok_msg
						mac_compare $mac $interface
						if [[ $? -eq 0 ]];then
							ok_msg
							interface_down $interface
							if [[ $? -eq 0 ]];then
								ok_msg
								mac_assign $interface $mac
								if [[ $? -eq 0 ]];then
									ok_msg
									interface_up $interface
									if [[ $? -eq 0 ]];then
										ok_msg
										final_msg
										exit 0
									else
										err_msg 6 $interface
									fi
								else
									err_msg 5 $interface $mac
								fi
							else
								err_msg 4 $interface
							fi

						else
							err_msg 3
						fi
					else
						err_msg 2
					fi		

				else
					err_msg 1 $interface
				fi
			else
				printf "[x] Argument Error..\n"
				usage_msg
				exit 1
			fi
	

		elif [[ $1 == "--random" ]] || [[ $1 == "-r" ]];then		#$1 --> r/random  $3 --> i/interface
			if [[ $2 == "--interface" ]] || [[ $2 == "-i" ]];then
				interface=$3
				mac=$(random_mac)
				interface_check $interface
				if [[ $? -eq 0 ]];then
					ok_msg
					mac_check $mac
					while [[ $? -ne 0 ]];do
						mac=$(random_mac)
						mac_check $mac
					done
					ok_msg
					mac_compare $mac $interface
					if [[ $? -eq 0 ]];then
						ok_msg
						interface_down $interface
						if [[ $? -eq 0 ]];then
							ok_msg
							mac_assign $interface $mac
							if [[ $? -eq 0 ]];then
								ok_msg
								interface_up $interface
								if [[ $? -eq 0 ]];then
									ok_msg
									final_msg
									exit 0
								else
									err_msg 6 $interface
								fi
							else
								err_msg 5 $interface $mac
							fi
						else
							err_msg 4 $interface
						fi
					else	
						err_msg 3
					fi
				else
					err_msg 1 $interface
				fi
			else
				printf "[x] Argument Error..\n"
				usage_msg
				exit 1
			fi
		
		else
			printf "[x] Argument Error..\n"
			usage_msg
			exit 1
		fi
	else
		if [[ $# -eq 0 ]]
		then
			printf "[x] no arguments are given..\n"
			usage_msg
			exit 1
		else
			printf "[x] error in arguments given..\n"
			usage_msg
			exit 1
		fi
	fi
else
	printf "[x] please run this script as root..\n"
	exit 1

fi





















