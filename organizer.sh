#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

function recurring_filename {
  dir=$1 # dir is the directory where multiple names are clashing
  recur_name=$2 # recur_name is the recurring filename
  ext=$3 # ext is the extension of recur_name
  local filename=$4
  local file=$recur_name
  if [[ $ext != "" ]]; then
    file=$file"."$ext
  fi

  file_name="find_list"
  n=$(awk -F '#' -v file="${file}" '$1 == file { print $2 }' "$file_name")
  j=$((n+1))

  if [[ $ext == "" ]]; then
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$j # newfilepath is the new name for a repeated filename in the same extdir
    if [ -e "$newfilepath" ]; then
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")
      while [ -e $newfilepath ]; do
        let "j=j+1"
        newfilepath=$desdir"/"$dir"/"$recur_name"_"$j
        if [ ! -e $newfilepath ]; then break; fi
        newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")
      done
    fi
  else
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"."$ext # newfilepath is the new name for a repeated filename in the same extdir
    if [ -e $newfilepath ]; then
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")"."$ext
      while [ -e $newfilepath ]; do
        let "j=j+1"
        newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"."$ext
        if [ ! -e $newfilepath ]; then break; fi
        newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")"."$ext
      done
    fi
  fi
  sed -i "s/${file}#${n}/${file}#${j}/" "$file_name"
  # now we have got the new name for a recurring filepath and echo it
  echo "$newfilepath"
}

# Check if the flag is provided
srcdir=$1  # Source directory
desdir=$2  # Destination directory
flag="ext"  # Sorting flag, default is "ext"
delete_files=false  # Delete files flag, default is false
log_file=false  # Log file flag, depends on -l flag presence
log_name=""  # Name of log file as given by user with -l flag
flag_s=false  # Flag for -s flag usage
flag_e=false  # Flag for -e flag usage
flag_i=false  # Flag for -i flag usage
e_names=""  # Extensions entered through -e

# Validate and process source directory
if [[ -z "$srcdir" ]]; then
  print_message "${RED}" "⚠️ Error: Source directory not provided. Please provide the source directory as the first argument."
  exit 1
fi

if [[ ! -d "$srcdir" ]]; then
  print_message "${RED}" "⚠️ Error: Source directory '$srcdir' does not exist."
  exit 1
fi

if [[ "$desdir" == "-l" || "$desdir" == "-d" || "$desdir" == "-e" || "$desdir" == "-s" || "$desdir" == "" ]]; then
  print_message "${RED}" "⚠️ Error: Provide an destination directory argument."
  exit 1
fi

# Check if the flag is provided
args=("$@")
args=("$@")
for ((i=2; i<${#args[@]}; i++)); do
  if [[ ${args[i]} == "-d" ]]; then
    if [ "$delete_files" = false ]; then
      delete_files=true
    else
      print_message "${RED}" "⚠️Enter -d only 1 time. Entering more than one -d is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} == "ext" ]]; then
    if [ $flag_s = false ]; then
      flag="ext"
      ((i=i+1))
      flag_s=true
    else
      print_message "${RED}" "⚠️Enter -s only 1 time. Entering more than one -s is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} == "date" ]]; then
    if [ $flag_s = false ]; then
      flag="date"
      ((i=i+1))
      flag_s=true
    else
      print_message "${RED}" "⚠️Enter -s only 1 time. Entering more than one -s is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} != "date" && ${args[i+1]} != "ext" ]]; then
    print_message "${RED}" "⚠️No argument with -s, use \"ext\" or \"date\"."
    exit 1
  elif [[ ${args[i]} == "-l" ]]; then
    if [ $log_file = true ]; then print_message "${RED}" "⚠️Enter -l only 1 time. Entering more than one -s is wrong syntax."; exit 1; fi
    log_file=true
    log_name=${args[i+1]}
    if [[ $log_name == "-d" || $log_name == "-s" || $log_name == "-e" || $log_name == "-l" || $log_name == "-i" || $log_name == "" ]]; then
      print_message "${RED}" "⚠️Put valid filename for log file."
      exit 1
    fi
    ((i=i+1))
  elif [[ ${args[i]} == "-e" ]]; then
    if [ $flag_e = true ]; then print_message "${RED}" "⚠️Enter -e only 1 time. Entering more than one -e is wrong syntax."; exit 1; fi
    flag_e=true
    e_names=${args[i+1]}
    if [[ $e_names == "-d" || $e_names == "-s" || $e_names == "-e" || $e_names == "-l" || $e_names == "-i" || $e_names == "" ]]; then
      print_message "${RED}" "⚠️Put valid extensions for -e flag."
      exit 1
    fi
    IFS=',' read -ra array <<< "$e_names"
    ((i=i+1))
  elif [[ ${args[i]} == "-i" ]]; then
    if [ $flag_i = true ]; then print_message "${RED}" "⚠️Enter -i only 1 time. Entering more than one -i is wrong syntax."; exit 1; fi
    flag_i=true
    i_names=${args[i+1]}
    if [[ $i_names == "-d" || $i_names == "-s" || $i_names == "-e" || $i_names == "-l" || $i_names == "-i" || $i_names == "" ]]; then
      print_message "${RED}" "⚠️Put valid extensions for -i flag."
      exit 1
    fi
    IFS=',' read -ra array <<< "$i_names"
    ((i=i+1))
  else
    print_message "${RED}" "⚠️Invalid flag. Please try filling correct flags: -d, -s, -l, -e, -i"
    exit 1
  fi
  if [[ $flag_e == true && $flag_i == true ]]; then print_message "${RED}" "⚠️Enter -i or -e only 1 time. Entering both -i and -e is wrong syntax."; exit 1; fi
done

touch output.txt # keeping track of files transferred
touch temp.txt
touch log.txt #log file for -l flag
touch hash_file #file that contains hash of visited objects
mkdir "Temp_Zip_Folder"
touch find_list

# Validate and process destination directory
if [[ -z "$desdir" ]]; then
  print_message "${RED}" "⚠️ Error: Destination directory not provided. Please provide the destination directory as the second argument."
  exit 1
fi

# Welcome message
echo -e "${BLUE}==============================================="
echo -e "          Welcome to the Amazing Script         "
echo -e "===============================================${NC}"
echo -e "${GREEN}"
echo -e "   __    _  _______  _______  _______ "
echo -e "  |  \  | ||       ||   _   ||       |"
echo -e "  |   \ | ||    ___||  |_|  ||_     _|"
echo -e "  |    \| ||   |___ |       |  |   |  "
echo -e "  |  |\   ||    ___||       |  |   |  "
echo -e "  |  | \  ||   |___ |   _   |  |   |  "
echo -e "  |__|  \_||_______||__| |__|  |___|  "
echo -e "${NC}"


if [[ ! -d "$desdir" ]]; then
  print_message "${RED}" "⚠️ Error: Destination directory '$desdir' does not exist."
  print_message "${GREEN}" "Don't worry creating one..."
  mkdir -p $desdir
fi

# Now extracting files and checking their extensions and creation time
function main {
 find $1 -type f -printf '%p\n' | while read -r i; do
  flag_search_e=false
  flag_search_i=false
  filename=$(basename "$i")
  src_location="${i%/*}" #source location of file, found using formatted string
  name=$(echo "$filename" | sed 's/\(.*\)\.[^\.]*/\1/') # name without extension
  ext=$(echo "$filename" | sed 's/.*\.\([^\.]*\)/\1/') # ext is extension
  
  if [ $flag_e = true ]; then
    for element in ${array[@]}; do
      if [[ $ext == $element ]]; then
        flag_search_e=true
      fi
    done
  fi
  if [ $flag_search_e = true ]; then
    continue
  fi
  if [ $flag_i = true ]; then
    for element in ${array[@]}; do
      if [[ $ext == $element ]]; then
        flag_search_i=true
      fi
    done
  fi
  if [[ $flag_search_i == false && $flag_i == true ]]; then
    continue
  fi
  if [ "$flag" == "ext" ]; then
    if [[ $(echo $filename | grep -c '^\.') > 0 ]]; then #that means it is hidden file
      extdir="Hidden_Files"
    elif [[ $(echo $filename | grep -c '\.$') > 0 ]]; then
      extdir="No_Extension"
    elif [ $(echo $filename | grep -c "\.") -ne 0 ]; then # -n ensures that the string returned is non-empty
      extdir="Extension_.$ext" # extdir is the extension directory
    else
      extdir="No_Extension"
      ext=""
    fi
  elif [ 
    "$flag" == "date" ]; then
    ctime=$(stat "$i" | awk '/Birth/ {print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') # ctime is creation time
    extdir="$ctime" # extdir is the date directory
  else
    echo -e "${RED}Invalid flag. Please use -s ext or -s date.${NC}"
    exit 1
  fi

  # check if extdir exists or not
  if [ ! -e "$desdir/$extdir" ]; then
    mkdir "$desdir/$extdir" # create a new extdir
    echo -e "${GREEN}A new $flag folder $extdir is created${NC}"
  fi

  # Keeping track of the times when which folders are used
  echo "$extdir" >> temp.txt
  #Updating log file
  echo "$(printf 'Added %-20s from %-25s to folder %-30s at %s\n' "$filename" "$src_location" "$desdir/$extdir" "$(date +"%Y-%m-%d %T")")" >> log.txt
  # Now checking if the same filename already exists
  newfilepath="$desdir/$extdir/$filename"
  if [ ! -e "$newfilepath" ]; then
    cp "$i" "$desdir/$extdir"
    echo -e "${GREEN}Added $filename to $extdir folder${NC}"
    echo $filename"#0" >> find_list
  else
    new_newfilepath=$(recurring_filename "$extdir" "$name" "$ext" "$filename")
    newname=$(basename "$new_newfilepath")
    if [[ $(echo $filename | grep -c '\.$') > 0 ]]; then
      new_newfilepath=$new_newfilepath"."
    fi
    cp "$i" "$new_newfilepath" # this copies the recurring file with the correct name
    echo "$filename already exists, so renamed to $newname and stored in $extdir directory"
  fi
  
  #############################################################
  if [[ $ext == "zip" ]]; then
    unzip $i -d "Temp_Zip_Folder"
    main "Temp_Zip_Folder/"$name"/"
    echo -e "${GREEN}Unzipping $filename${NC}"
    echo "Unzipped $filename at $(date +"%Y-%m-%d %T")" >> log.txt
  fi
  #############################################################

  # Delete the original file if the -d flag is specified
  if [[ "$delete_files" == true && $(echo $1 | grep -c "Temp_Zip_Folder") == 0 ]]; then
    rm "$i"
    echo -e "${YELLOW}Deleted original file: $i${NC}" >> output.txt
    echo "$(printf 'Deleted file: %-25s at %s\n' "$i" "$(date +"%Y-%m-%d %T")")" >> log.txt
  fi
done
}

main $srcdir

###############################################################
#Hash Deleting Files
echo ""
echo "Do you want to calculate the hash deletion? (yes/no)"
read answer

if [[ "$answer" != "no" ]]; then
    # Perform the hash deletion calculation
    print_message "$YELLOW" "Performing hash deletion..."
    flag_hash=false
    find $desdir -type f -printf '%p\n' | while read -r i; do
      filename=$(basename $i)
      flag_hash=false
      hash=$(sha256sum "$i" | cut -d ' ' -f 1)
      for j in $(cat hash_file); do
        if [[ $hash == $j ]]; then
          flag_hash=true
          break
        fi
      done
      if [ $flag_hash = true ]; then
        rm "$i"
      else
        echo $hash >> hash_file
      fi
    done
    # Your code for hash deletion goes here
else
    print_message "$YELLOW" "Skipping hash deletion."
fi
###############################################################
echo ""
echo -e "${BLUE}=============================================================="
echo -e "                       Some Statistics      "
echo -e "==============================================================${NC}"
echo -e "Folders created: $(sort temp.txt | uniq | wc -l)"
echo -e "Files transferred : $(cat temp.txt | wc -l)"
if [ $log_file = true ]; then
  echo -e "${GREEN}Log file created and saved as $log_name${NC}"
  mv log.txt $log_name
else
  rm log.txt
fi
echo ""
print_message "$YELLOW" "Number of files in each folder:-"
for i in `sort temp.txt | uniq`; do
  printf "%-20s | %-20s\n" $i $(find $desdir"/"$i -type f | wc -l)
done
rm temp.txt
rm hash_file
rm find_list
rm -r "Temp_Zip_Folder"

# Goodbye message
echo -e "${BLUE}=============================================================="
echo -e "           Script Execution Completed Successfully!      "
echo -e "==============================================================${NC}"
echo -e "${YELLOW}"
echo -e "███████╗██╗  ██╗ █████╗ ████████╗██╗  ██╗██╗████████╗"
echo -e "██╔════╝██║  ██║██╔══██╗╚══██╔══╝██║  ██║██║╚══██╔══╝"
echo -e "███████╗███████║███████║   ██║   ███████║██║   ██║   "
echo -e "╚════██║██╔══██║██╔══██║   ██║   ██╔══██║██║   ██║   "
echo -e "███████║██║  ██║██║  ██║   ██║   ██║  ██║██║   ██║   "
echo -e "╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝   "
echo -e "${NC}"