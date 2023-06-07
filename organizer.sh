#!/bin/bash

srcdir=$1 # srcdir is the source directory
desdir=$2 # desdir is the destination directory
flag="ext" # sorting flag, default is "ext"
delete_files=false # delete files flag, default is false
log_file=false #log_file flag, depends on -l flag presence
log_name="" #name of log file as given by user with -l flag
flag_s=false #flag for -s flag usage
flag_e=false #flag for -e flag usage
e_names="" #extensions entered through -e

# Check if the flag is provided
args=("$@")
for ((i=2; i<${#args[@]}; i++)); do
  if [[ ${args[i]} == "-d" ]]; then
    if [ "$delete_files" = false ]; then
      delete_files=true
    else
      echo "Enter -d only 1 time. Entering more than one -d is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} == "ext" ]]; then
    if [ $flag_s = false ]; then
      flag="ext"
      ((i=i+1))
      flag_s=true
    else
      echo "Enter -s only 1 time. Entering more than one -s is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} == "date" ]]; then
    if [ $flag_s = false ]; then
      flag="date"
      ((i=i+1))
      flag_s=true
    else
      echo "Enter -s only 1 time. Entering more than one -s is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} != "date" && ${args[i+1]} != "ext" ]]; then
    echo "No argument with -s, use \"ext\" or \"date\"."
    exit 1
  elif [[ ${args[i]} == "-l" ]]; then
    log_file=true
    log_name=${args[i+1]}
    if [[ $log_name == "-d" || $log_name == "-s" || $log_name == "-e" || $log_name == "-l" || $log_name == "" ]]; then
      echo "Put valid filename for log file."
      exit 1
    fi
    ((i=i+1))
  elif [[ ${args[i]} == "-e" ]]; then
    flag_e=true
    e_names=${args[i+1]}
    if [[ $e_names == "-d" || $e_names == "-s" || $e_names == "-e" || $e_names == "-l" || $e_names == "" ]]; then
      echo "Put valid extensions for -e flag."
      exit 1
    fi
    IFS=',' read -ra array <<< "$e_names"
    ((i=i+1))
  else
    echo "Invalid flag. Please try filling correct flags: -d, -s, -l, -e"
    exit 1
  fi
done

# Rest of the script remains the same

touch output.txt # keeping track of files transferred
touch temp.txt
touch log.txt #log file for -l flag
touch hash_file #file that contains hash of visited objects
mkdir "Temp_Zip_Folder"
touch find_list

# Checking if the destination directory doesn't exist, then create a new one
if [ ! -d "$desdir" ]; then
  mkdir -p "$desdir"
  echo "Destination Directory $desdir does not exist. No worries, created one." >> output.txt
else
  echo "Destination Directory $desdir exists." >> output.txt
fi

function recurring_filename {
  dir=$1 # dir is the directory where multiple names are clashing
  recur_name=$2 # recur_name is the recurring filename
  ext=$3 # ext is the extension of recur_name
  j=1
  if [[ $ext == "" ]]; then
    newfilepath=$desdir"/"$dir"/"$recur_name # newfilepath is the new name for a repeated filename in the same extdir
    while [ -e "$newfilepath" ]; do
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j
      let "j=j+1"
    done
  else
    newfilepath=$desdir"/"$dir"/"$recur_name"."$ext # newfilepath is the new name for a repeated filename in the same extdir
    while [ -e "$newfilepath" ]; do
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"."$ext
      let "j=j+1"
    done
  fi
  # now we have got the new name for a recurring filepath and echo it
  echo "$newfilepath"
}

# Now extracting files and checking their extensions and creation time
function main {
 find $1 -type f -printf '%p\n' | while read -r i; do
  flag_search_e=false
  filename=$(basename "$i")
  src_location="${i%/*}" #source location of file, found using formatted string
  name=$(echo "$filename" | sed 's/\(.*\)\.[^\.]*/\1/') # name without extension
  ext=$(echo "$filename" | sed 's/.*\.\([^\.]*\)/\1/') # ext is extension
  
  if [ $flag_e = true ]; then
    for element in ${array[@]}; do
      if [ $ext = $element ]; then
        flag_search_e=true
      fi
    done
  fi
  if [ $flag_search_e = true ]; then
    continue
  fi
  if [ "$flag" == "ext" ]; then
    if [ $(echo $filename | grep -c '^\.') -gt 0 ]; then #that means it is hidden file
      extdir="Hidden_Files"
    elif [ $(echo $filename | grep -c "\.") -ne 0 ]; then # -n ensures that the string returned is non-empty
      extdir="Extension_.$ext" # extdir is the extension directory
    else
      extdir="No_Extension"
      ext=""
    fi
  elif [ "$flag" == "date" ]; then
    ctime=$(stat "$i" | awk '/Birth/ {print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') # ctime is creation time
    extdir="$ctime" # extdir is the date directory
  else
    echo "Invalid flag. Please use -s ext or -s date."
    exit 1
  fi

  # check if extdir exists or not
  if [ ! -e "$desdir/$extdir" ]; then
    mkdir "$desdir/$extdir" # create a new extdir
    echo "A new $flag folder $extdir is created" >> output.txt
  fi

  # Keeping track of the times when which folders are used
  echo "$extdir" >> temp.txt
  #Updating log file
  echo "Added $filename from $src_location to $desdir/$extdir folder at `date +"%Y-%m-%d %T"`" >> log.txt
  # Now checking if the same filename already exists
  newfilepath="$desdir/$extdir/$filename"
  if [ ! -e "$newfilepath" ]; then
    cp "$i" "$desdir/$extdir"
    echo "Added $filename to $extdir folder" >> output.txt
  else
    new_newfilepath=$(recurring_filename "$extdir" "$name" "$ext")
    newname=$(basename "$new_newfilepath")
    cp "$i" "$new_newfilepath" # this copies the recurring file with the correct name
    echo "$filename already exists, so renamed to $newname and stored in $extdir directory" >> output.txt
  fi
  
  #############################################################
  if [[ $ext == "zip" ]]; then
    unzip $i -d "Temp_Zip_Folder"
    main "Temp_Zip_Folder/"$name"/"
    echo "Unzipping $filename" >> output.txt
    echo "Unzipped $filename at `date +"%Y-%m-%d %T"`" >> log.txt
  fi
  #############################################################
  
  # Delete the original file if the -d flag is specified
  if [ "$delete_files" = true ]; then
    rm "$i"
    echo "Deleted original file: $i" >> output.txt
    echo "Deleted file: $i at `date +"%Y-%m-%d %T"`" >> log.txt
  fi
done
}

main $srcdir

###############################################################
#Hash Deleting Files
flag_hash=false
find $desdir -type f -printf '%p\n' | while read -r i; do
  filename=$(basename $i)
  flag_hash=false
  hash=$(sha256sum "$i")
  for j in $(cat hash_file); do
    if [[ $hash == $j ]]; then
      flag_hash=true
      break
    fi
  done
  if [ $flag_hash = true ]; then
    rm $i
  else
    echo $hash >> hash_file
  fi
done
###############################################################

echo "Folders created: $(sort temp.txt | uniq | wc -l)"
if [ $log_file = true ]; then
  echo "Log file created and saved as $log_name"
  mv log.txt $log_name
else
  rm log.txt
  cat output.txt
  rm output.txt
fi
echo "Number of files in each folder:-"
awk '{Grp[$1]++} END {for (i in Grp) print i":"Grp[i]}' temp.txt # This command prepares a dictionary of extensions/creation dates as keys and frequencies as values
rm temp.txt
rm hash_file
rm -r "Temp_Zip_Folder"
rm find_list