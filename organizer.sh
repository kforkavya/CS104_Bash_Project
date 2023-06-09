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
  newfilepath=$desdir"/"$dir"/"$filename"#"
  file_name="find_list"
  declare -i n j
  n=$(sed -n "s/^${file}#\([0-9]\+\)$/\1/p" "$file_name")
  if [[ -z "$n" ]]; then
    n=0
  fi
  ((j = n + 1))

  if [[ $ext == "" || $(echo "$filename" | grep -c "\.") == 0 ]]; then
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$j # newfilepath is the new name for a repeated filename in the same extdir
    if [ -e "$newfilepath" ]; then
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")
    fi
  else
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"."$ext # newfilepath is the new name for a repeated filename in the same extdir
    s=$desdir"/"$dir"/"$recur_name"_"$j
    if [ -e "$newfilepath" ]; then
      newfilepath=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")"."$ext
      s=$desdir"/"$dir"/"$recur_name"_"$j"_"$(date +"%Y-%m-%d_%T")
    fi
  fi
  sed -i "s/${file}#${n}/${file}#${j}/" "$file_name"
  if [[ $ext != "" &&  $(cat find_list | grep -c "^${recur_name}\.[^\.]*#") == 0 ]]; then
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$(date +"%Y-%m-%d_%T")"."$ext
    s=$desdir"/"$dir"/"$recur_name"_"$(date +"%Y-%m-%d_%T")
    echo $filename"#0" >> find_list
  elif [[ $(cat find_list | grep -c "^${file}#") == 0 ]]; then
    newfilepath=$desdir"/"$dir"/"$recur_name"_"$(date +"%Y-%m-%d_%T")
    if [[ $ext != "" ]]; then newfilepath=$desdir"/"$dir"/"$recur_name"_"$(date +"%Y-%m-%d_%T")"."$ext; fi
    echo $filename"#0" >> find_list
  fi
  # now we have got the new name for a recurring filepath and echo it
  while [[ -e "$newfilepath" && $ext == "" ]]; do
    newfilepath=$newfilepath"_"$(date +"%Y-%m-%d_%T")
  done
  if [[ $ext != "" ]]; then
    while [[ -e $s"."$ext ]]; do
      s=$s"_"$(date +"%Y-%m-%d_%T")
    done
    newfilepath=$s"."$ext
  fi
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

if [[ "$srcdir" == "-l" || "$srcdir" == "-d" || "$srcdir" == "-e" || "$srcdir" == "-s" || "$srcdir" == "-i" || "$srcdir" == "" ]]; then
  print_message "${RED}" "⚠️ Error: Provide a valid source directory argument."
  exit 1
fi

if [[ "$desdir" == "-l" || "$desdir" == "-d" || "$desdir" == "-e" || "$desdir" == "-s" || "$desdir" == "-i" || "$desdir" == "" ]]; then
  print_message "${RED}" "⚠️ Error: Provide a valid destination directory argument."
  exit 1
fi

if [[ ! -d "$srcdir" ]]; then
  print_message "${RED}" "⚠️ Error: Source directory '$srcdir' does not exist."
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
  elif [[ ${args[i]} == "-s" && ${args[i+1]} == "size" ]]; then
    if [ $flag_s = false ]; then
      flag="size"
      ((i=i+1))
      flag_s=true
    else
      print_message "${RED}" "⚠️Enter -s only 1 time. Entering more than one -s is wrong syntax."
      exit 1
    fi
  elif [[ ${args[i]} == "-s" && ${args[i+1]} != "date" && ${args[i+1]} != "ext" && ${args[i+1]} != "size" ]]; then
    print_message "${RED}" "⚠️No argument with -s, use \"ext\" or \"date\" or \"size\"."
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

touch temp.txt
touch temp_new_folder.txt
touch log.txt #log file for -l flag
touch hash_file #file that contains hash of visited objects
mkdir "Temp_Zip_Folder"
touch find_list

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

flag_e_display=true
if [[ $flag_e == true ]]; then #Asks the user whether he wants to see exclude output messages of -e flag
  echo ""
  echo "Seems you have used my -e custom flag..."
  print_message "${YELLOW}" "Do you want to see the excluded files as per the -e flag ? (yes/no)"
  read ans
  echo ""
  if [[ $ans == "no" ]]; then flag_e_display=false; fi
fi

zip_unzip=false
print_message "${YELLOW}" "Do you want to unzip the zipped files (yes/no) ?"
read ans_zip
if [[ $ans_zip != "no" ]]; then zip_unzip=true; fi
echo ""

# Now extracting files and checking their extensions and creation time
function main {
 find $1 -type f -printf '%p\n' | while read -r i; do
  flag_search_e=false
  flag_search_i=false
  filename=$(basename "$i")
  if [[ $filename == "..." ]]; then continue; fi
  src_location="${i%/*}" #source location of file, found using formatted string
  name=$(echo "$filename" | sed 's/\(.*\)\.[^\.]*/\1/') # name without extension
  ext=$(echo "$filename" | sed 's/.*\.\([^\.]*\)/\1/') # ext is extension
  ext2=""

  if [[ $(echo $filename | grep -c '^\.') == 0 ]]; then
    if [[ $(echo $filename | grep -c '\.$') > 0 || $(echo $filename | grep -c '\.') == 0 ]]; then #No Extension Files
      ext2="noext"
      ext=""
      name=$filename
      if [[ $(echo $filename | grep -c '\.$') > 0 ]]; then
        name=$(echo $filename | sed 's/\([^\.]*\)\./\1/')
      fi
    fi
  fi

  if [ $flag_e = true ]; then
    for element in ${array[@]}; do
      if [[ $ext == $element || $ext2 == $element ]]; then
        flag_search_e=true
      fi
    done
  fi
  if [[ $flag_search_e == true ]]; then
    if [[ $flag_e_display == true ]]; then print_message "${RED}" "Excluding $i as per -e flag."; fi
    continue
  fi
  if [ $flag_i = true ]; then
    for element in ${array[@]}; do
      if [[ $ext == $element || $ext2 == $element ]]; then
        flag_search_i=true
      fi
    done
  fi
  if [[ $flag_search_i == false && $flag_i == true ]]; then
    continue
  fi
  if [[ "$flag" == "ext" ]]; then
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
  elif [[ "$flag" == "date" ]]; then
    ctime=$(stat "$i" | awk '/Birth/ {print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') # ctime is creation time
    extdir="$ctime" # extdir is the date directory
  elif [[ "$flag" == "size" ]]; then
    file_size_kB=$(stat -c "%s" "$i")
    floor=$(awk -v num="$file_size_kB" 'BEGIN { printf "%.0f", num }')
    if [[ $floor < 10 ]]; then extdir="0-10kBs"
    elif [[ $floor < 20 ]]; then extdir="10-20kBs"
    elif [[ $floor < 30 ]]; then extdir="20-30kBs"
    elif [[ $floor < 40 ]]; then extdir="30-40kBs"
    elif [[ $floor < 50 ]]; then extdir="40-50kBs"
    else extdir="Gt50kBs"
    fi
  else
    echo -e "${RED}Invalid flag. Please use -s ext or -s date or -s size.${NC}"
    exit 1
  fi

  # check if extdir exists or not
  if [ ! -e "$desdir/$extdir" ]; then
    mkdir "$desdir/$extdir" # create a new extdir
    if [[ $delete_files == false ]]; then
      print_message "${YELLOW}" "A new $flag folder $extdir is created."
    else
      echo "A new $flag folder $extdir is created."
    fi
    echo "$extdir" >> temp_new_folder.txt
  else
    flag_2=false
    for j in `cat temp.txt`; do
      if [[ $j == $extdir ]]; then flag_2=true; fi
    done
    if [[ $flag_2 == false ]]; then print_message "${RED}" "\"$extdir\" folder already existed so not creating a new one ..."; fi
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
    print_message "${BLUE}" "$filename already exists, so renamed to $newname and stored in $extdir directory"
    echo "$i already exists, so renamed to $newname and stored in $extdir directory" >> log.txt
  fi

  #############################################################
  if [[ $ext == "zip" && $zip_unzip == true ]]; then
    echo -e "Unzipping $filename"
    mkdir -p $src_location"/Temp_Zip_Folder/"$name"/"
    unzip -o -q "$i" -d "$src_location/Temp_Zip_Folder"
    main $src_location"/Temp_Zip_Folder/"$name"/"
    echo "Unzipped $filename at $(date +"%Y-%m-%d %T")" >> log.txt
    rm -r $src_location"/Temp_Zip_Folder/"
  fi
  #############################################################

  # Delete the original file if the -d flag is specified
  if [[ "$delete_files" == true && $(echo $1 | grep -c "Temp_Zip_Folder") == 0 ]]; then
    rm "$i"
    echo -e "${YELLOW}Deleted original file: $i${NC}"
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
echo -e "Folders created: $(cat temp_new_folder.txt | wc -l)"
echo -e "Files transferred : $(cat temp.txt | wc -l)"
if [[ $answer != "no" ]]; then echo -e "Files left after hash-check : $(cat hash_file | wc -l)"; fi
if [[ "$log_file" == true ]]; then
  echo -e "${GREEN}Log file created and saved as $log_name${NC}"
  mv log.txt "$log_name"
else
  rm log.txt
fi
echo ""
print_message "$YELLOW" "Number of files in each folder:-"
for i in `sort temp.txt | uniq`; do
  printf "%-20s | %-20s\n" $i $(find $desdir"/"$i -type f | wc -l)
done
rm temp.txt
rm temp_new_folder.txt
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