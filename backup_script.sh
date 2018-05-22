#!/bin/bash

#############################################################################################################################
#############################################################################################################################
## script maakt een encrypted tar backup van filesystems/folders
## restoren van een single file gaat met b.v. cat 06032014__backup.tar.gz.enc |  openssl aes-256-cbc -d -salt  -pass pass:"XxxxxX"| tar -xvz home/dhombo/.emacs
#############################################################################################################################
#############################################################################################################################
# password samba change: ( echo oldpass ; echo newpass ; echo newpass  )  | smbpasswd  -s -U username -r dc_ip

bck_script_config="/usr/local/bin/backup_script.config"
# lees de config
. ${bck_script_config}

# zonder cifs mountpouit tart hij hem op de root. willen we niet
if [ -z "${cifs_mountpoint}" ] ; then
  echo "cifs_mountpoint ontbreekt" 
  exit 1
fi

# zonder encryption passphrase doen we ook niets
if [ -z "${encr_pw}" ] ; then
  echo "encr_pw ontbreekt"
  exit 1
fi

cifs_is_mounted=0
cifs_mounted_at_start=0

bck_log_dir="/root/backup/"
bck_dest_dir="${cifs_mountpoint}/$(hostname)/"
log_file="${bck_log_dir}backup.log"
date_stamp=$(date +%d%m%Y%H%M)
# we houden er 6. er komt er 1 bij voor we weggooien
num_backups_to_keep=6

# nagios exit codes
NAGIOS_STATE_OK=0
NAGIOS_STATE_WARNING=1
NAGIOS_STATE_CRITICAL=2
NAGIOS_STATE_UNKNOWN=3
NAGIOS_STATE_DEPENDENT=4



# TODO cifs username password change automatiseren

###############################################################################################################################################
###############################################################################################################################################
## de hoofdbackup functie 
## geeft 0 terug bij ok, 1 bij warning en 2 bij kritiek
###############################################################################################################################################
###############################################################################################################################################
function do_backup() {

# de boolean warning wordt gebruikt om op het end een warning terug te geven. het script mag niet returnen omdat de index file nog gemaakt moet worden
do_backup_warning=0
# checken of het 1e argument er wel is
if [ -z "$1" ] ; then
  exit_string="argument ontbreekt voor do_backup functie"  
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 2
fi

# checken of er een geldige backup dit opgegeven is
if ! [ -d $1 ] ; then
  exit_string="directory $1 bestaat niet"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 2
fi

# zet de backup root, dit is de map die we gaan backuppen
backup_root=$1


# we hebben een naam zonder slashes nodig voor in de naam van de tar en index file
backup_root_without_slash=$(echo ${backup_root}| tr -d "/")
backup_tar_file="${bck_dest_dir}${backup_root_without_slash}_backup_${date_stamp}_.tar.gz.enc"
index_file="${bck_dest_dir}${backup_root_without_slash}_backup_${date_stamp}_index_file.txt"
error_output_file="${bck_log_dir}${date_stamp}_${backup_root_without_slash}_backup_errors.txt"
openssl_error_file="${bck_log_dir}${date_stamp}_${backup_root_without_slash}_openssl_errors.txt"
nagios_status_file="${nagios_file_dir}_${backup_root_without_slash}_backup_status.txt"
exclude_file="${bck_log_dir}${backup_root_without_slash}_exclude_backup.txt"

# gooi de exclude file weg als hij er is
if [ -f ${exclude_file} ] ; then
  rm ${exclude_file}
fi


# genereer de exclude file
# de exclude file is groter omdat hij ook dirs bevat die niet in de mount staan. maar universeel is overzichtelijker
echo "/proc" > ${exclude_file}
# bij root lost+found echoen zonder / omdat de slash acheraan staat
# zou met dubbele // ook moeten werken, maar is mooier
if [ "-${backup_root}-" == "-/-" ] ; then
  echo "/lost+found" >> ${exclude_file}
else
  echo "${backup_root}/lost+found" >> ${exclude_file}
fi
echo "/mnt" >> ${exclude_file}
echo "/sys"  >> ${exclude_file}
echo "${index_file}"  >> ${exclude_file}
echo "${backup_tar_file}" >> ${exclude_file}
echo "${openssl_error_file}"  >> ${exclude_file}
echo "${error_output_file}"  >> ${exclude_file}
find ${backup_root} -mount -type s 2>/dev/null >> ${exclude_file}
# host specifieke exclude dirs zetten
for exclude_dir in  ${exclude_dirs} ; do
  echo ${exclude_dir} >> ${exclude_file}
done
# exclude mountpoints
# de option --one-file-system zou ook niet moeten descenden in andere mountpoints, maar just in case
for mountpoint in `mount | awk '{print $3}'` ; do
  # als het mountpoint exact de backup_root root is natuurlijk niet excluden
  if ! [ "-${mountpoint}-" == "-${backup_root}-" ] ; then
     # in het geval van een backupfolder die geen mountpoint is:
     # als het mountpoint een dir onder de backup_root is niet excluden, anders wel
     echo ${backup_root} | grep "^${mountpoint}.*" >/dev/null 2>&1
     if [ $? -ne 0 ] ; then
       echo "${mountpoint}" >>  ${exclude_file}
     fi
  fi
done

#  cifs moet gemount zijn ,maar we dubbelchecken het wel. als het niet het geval is trekken we het / fs dicht..
# we check het vlak voor de tar
# kijken of hij al gemount is
# ik heb wel eens gezien dat het mount commando de cifs wel teruggeeft, maar dat hij er niet is in /proc/mounts...
# dit is dus de echte safe check
cifs_is_mounted=0
mountpoint ${cifs_mountpoint} >/dev/null 2>&1
if [ $? -eq 0 ] ; then
  cifs_is_mounted=1
fi 
if [ ${cifs_is_mounted} -ne 1 ] ; then
  exit_string="backup van ${backup_root} is mislukt. cifs is niet gemount"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 2
fi

# dit de plek waar we echt een 100% mount hebben, dus hier maken we de folder aan als hij er niet is
if ! [ -d ${bck_dest_dir} ] ; then
  mkdir ${bck_dest_dir}
fi

# start de backup
echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tstarten met backup van ${backup_root}" >> ${log_file}
tar cpz --ignore-failed-read --one-file-system -X ${exclude_file}  ${backup_root} 2>${error_output_file} | openssl aes-256-cbc  -salt -pass pass:${encr_pw} > ${backup_tar_file} 2>${openssl_error_file}
exitarray=("${PIPESTATUS[@]}")
# check openssl errors
if [ ${exitarray[1]} -ne 0 ] ; then
  exit_string="openssl errorcode ${exitarray[1]} bij backup van ${backup_root}"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 2
fi
# check tar codes. exit 1 is warning (changed files ofzo, 2 is error)
if [ ${exitarray[0]} -eq 1 ] ; then
  # de exit string bevat nu ook max 10 regels uit de tar error log
  exit_string="tar errorcode ${exitarray[0]} bij backup van ${backup_root}. errors: $(cat ${error_output_file} | grep -v "Removing leading" | tail -10)"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  do_backup_warning=1
elif [ ${exitarray[0]} -ne 0 ] ; then
  # nu hebben we de warning gehad en is alles behalve exit 0 van tar een error
  exit_string="tar errorcode ${exitarray[0]} bij backup van ${backup_root}"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 2
fi

echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tklaar met backup ${backup_root}" >> ${log_file}

# generate index
echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tstarten met het maken van de index file van ${backup_root}" >> ${log_file}
cat ${backup_tar_file} | openssl aes-256-cbc -d -salt  -pass pass:${encr_pw} | tar -tvz > ${index_file}
if [ ${PIPESTATUS[0]} -ne 0 -o  ${PIPESTATUS[1]} -ne 0  -o ${PIPESTATUS[2]} -ne 0 ] ; then
  exit_string="genereren index file mislukt van ${backup_root}"
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\t${exit_string}" >> ${log_file}
  return 1
fi
echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tklaar met maken index file van ${backup_root}" >> ${log_file}


# als de backup gelukt is oude backup files opruimen van deze backuproot opruimen
for tst_file in `ls -t ${bck_dest_dir}${backup_root_without_slash}_backup*tar.gz.enc | grep -v "$(ls -t ${bck_dest_dir}${backup_root_without_slash}_backup*tar.gz.enc | head -${num_backups_to_keep})"` ; do
  # dubbelcheck of de bck_dest_dir in de string zit boor we hem gaan removen
  echo ${tst_file} | grep ${bck_dest_dir}  >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "removing $tst_file" >>  ${log_file}  
    rm ${tst_file}
  fi 
done

# en oude index files opruimen
for tst_file in `ls -t ${bck_dest_dir}${backup_root_without_slash}_backup*_index_file.txt | grep -v "$(ls -t ${bck_dest_dir}${backup_root_without_slash}_backup*_index_file.txt | head -${num_backups_to_keep})"` ; do
  # dubbelcheck of de bck_dest_dir in de string zit boor we hem gaan removen
  echo ${tst_file} | grep ${bck_dest_dir}  >/dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "removing $tst_file" >>  ${log_file}
    rm ${tst_file}
  fi
done

# als we hier zijn is de backup gelukt en schrijven we een ok in de nagios stats file
if [ ${do_backup_warning} -eq 1 ] ; then
  #exit_string is boven al gezet. return 1
  return 1
else
  exit_string="backup ${backup_root} geslaagd om `date +%d-%m-%Y-%H:%M:%S`"
  return 0
fi

}

###############################################################################################################################################
###############################################################################################################################################
## begin script
###############################################################################################################################################
###############################################################################################################################################


if ! [ -d ${nagios_file_dir} ] ; then
  mkdir -p ${nagios_file_dir}
  chown nagios. ${nagios_file_dir}
fi

if ! [ -d ${cifs_mountpoint} ] ; then
  mkdir ${cifs_mountpoint}
fi

if ! [ -d ${bck_log_dir} ] ; then
  mkdir ${bck_log_dir}
fi

echo -e "##################################################################" >>  ${log_file}
echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tbackupscript gestart" >> ${log_file}
echo -e "##################################################################" >>  ${log_file}

# kijken of cifs al gemount is
for mountpoint in `mount | awk '{print $3}'` ; do
  if [ "-${mountpoint}-" == "-${cifs_mountpoint}-" ] ; then
    cifs_mounted_at_start=1
    cifs_is_mounted=1
  fi
done


# de cifs share is gecommuniceerd als \\PVHCORP.COM\EUROPE\COMMON\HotItemBackup
# dit is een dfs share die te mounten is via //amsdf01.pvhcorp.com/EUROPE/Common/HotItemBackup/ en //amsdf02.pvhcorp.com/EUROPE/Common/HotItemBackup/
# via debugging omdat deze mountsi soms  terugkwamen met error 11 kwam ik op deze share: "//amsfs001.pvhcorp.com/hotitembackup\$/HotItemBackup"

# debugging voor cifs is aan te zetten via: echo 7 > /proc/fs/cifs/cifsFYI . uit is echo 0 > /proc/fs/cifs/cifsFYI
# de debug is dan te lezen via dmesg
if [ ${cifs_is_mounted} -eq 0 ] ; then
  mount -t cifs -o username=${cifs_username},domain=pvhcorp.com,sec=ntlm,password="${cifs_password}" ${cifs_share}  ${cifs_mountpoint}
  if [ $? -eq 0 ] ; then
    cifs_is_mounted=1
  fi

fi

# kijken of hij gemount is
if [ ${cifs_is_mounted} -ne 1 ] ; then
  echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tmounten cifs share niet gelukt.." >> ${log_file}
  exit 1
fi

###############################################################################################################################################



# geef de dirs op zonder / aan het eind!!!

#do_backup /boot
#do_backup /
#do_backup /u01
#for backup_dir in `cat ${bck_script_config} | grep -v "^#" | awk '{print $1}' | xargs` ; do
for backup_dir in ${backup_dirs} ; do
  exit_string=""
  do_backup ${backup_dir}
  exit_code_backup=$?
  if [ ${exit_code_backup} -eq 2 ] ; then
    echo -e "${NAGIOS_STATE_CRITICAL}\n${exit_string}" > ${nagios_status_file}
    chown nagios.nagios  ${nagios_status_file}
    echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tde backup van ${backup_dir} is mislukt met error ${exit_code_backup}" >> ${log_file}
  elif [ ${exit_code_backup} -eq 1 ] ; then
    echo -e "${NAGIOS_STATE_OK}\n${exit_string}" > ${nagios_status_file}
    chown nagios.nagios  ${nagios_status_file}
    echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tde backup van ${backup_dir} geeft warning ${exit_code_backup}" >> ${log_file}
  elif [ ${exit_code_backup} -eq 0 ] ; then
    echo -e "${NAGIOS_STATE_OK}\n${exit_string}" > ${nagios_status_file}
    chown nagios.nagios  ${nagios_status_file}
    echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tde backup van ${backup_dir} is gelukt" >> ${log_file}
  else
    echo -e "${NAGIOS_STATE_UNKNOWN}\n${exit_string}" > ${nagios_status_file}
    chown nagios.nagios  ${nagios_status_file}
    echo -e  "`date +%d-%m-%Y-%H:%M:%S`\tde backup van ${backup_dir} is unknown" >> ${log_file}
  fi
done

# umount de share als wij hem in het script gemount hebben. anders niet
if [ ${cifs_mounted_at_start} -eq 0 ] ; then
  umount ${cifs_mountpoint}
fi
