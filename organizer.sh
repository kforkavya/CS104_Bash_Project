#!/bin/bash
srcdir=$1 # srcdir is the source directory
desdir=$2 # desdir is the destination directory
folder_created=0 # track the number of folders created
touch folder_count.txt # track of folders used
touch output.txt # keeping track of files transferred
touch temp.txt

# Checking if the destination directory doesn't exist, then create a new one
if [ ! -d $desdir ]; then
  mkdir $desdir
  echo "Destination Directory $desdir does not exist. No worries, created one." >> output.txt
fi

# Now extracting files and checking their extensions
for i in $(find $srcdir -type f); do
  filename=$(basename $i)
  name=$(echo $filename | sed 's/\([^\.]*\)\.[^\.]*/\1/') # name without extension
  ext=$(echo $filename | sed 's/[^\.]*\.\([^\.]*\)/\1/') # ext is extension
  if [ -n $ext ]; then # -n ensures that the string returned is non-empty
    extdir="Extension_."$ext # extdir is the extension directory
  else
    extdir="No_Extension"
  fi

  # check if extdir exists or not
  if [ ! -e $desdir/$extdir ]; then
    let "folder_created=folder_created+1"
    mkdir $desdir/$extdir # create a new extdir
    echo "A new extension folder $extdir is created" >> output.txt
  fi

  # Keeping track of the times when which folders are used
  echo "$extdir" >> temp.txt
  # Now checking if the same filename already exists
  newfilepath=$desdir"/"$extdir"/"$filename
  if [ ! -e $newfilepath ]; then
    cp $i $desdir/$extdir
    echo "Added $filename to $extdir folder" >> output.txt
  else
    j=1
    new_newfilepath=$newfilepath # new_newfilepath is the new name for a repeated filename in the same extdir
    while [ -e $new_newfilepath ]; do
      new_newfilepath=$desdir"/"$extdir"/"$name"_"$j"."$ext
      let "j=j+1"
    done
    # now we have got the new name for a recurring filename
    cp $i $new_newfilepath # this copies the recurring file with the correct name
    newname=$(basename $new_newfilepath)
    echo "$filename already exists, so renamed to $newname and stored in $extdir directory" >> output.txt
  fi
done

# Now extracting files and checking their creation time
for i in $(find $srcdir -type f); do
  filename=$(basename $i)
  name=$(echo $filename | sed 's/\([^\.]*\)\.[^\.]*/\1/') # name without extension
  extdir=$(echo $filename | sed 's/[^\.]*\.\([^\.]*\)/\1/') # extdir is the extension directory
  ctime=$(stat $i | sed -n '/Birth/p' |  awk 'BEGIN{FS=" "}{print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') # ctime is creation time

  # check if ctime exists or not
  if [ ! -e $desdir/$ctime ]; then
    let "folder_created=folder_created+1"
    mkdir $desdir/$ctime # create a new extdir
    echo "A new date folder $ctime is created" >> output.txt
  fi

  # Keeping track of the times when which folders are used
  echo "$ctime" >> temp.txt
  # Now checking if the same filename already exists
  newfilepath=$desdir"/"$ctime"/"$filename
  if [ ! -e $newfilepath ]; then
    cp $i $desdir/$ctime
    echo "Added $filename to $ctime date folder" >> output.txt
  else
    ctime=$(stat $i | sed -n '/Birth/p' |  awk 'BEGIN{FS=" "}{print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') # ctime is creation time
    # the above expression returns the creation time of the file
    newname=$name"_"$ctime"."$extdir
    cp $i $desdir/$ctime/$newname # this copies the file with a timestamp
    echo "$filename already exists, so renamed to $newname and stored in $ctime date directory" >> output.txt
  fi
done

echo "Folders created: "$folder_created
cat output.txt
echo "Number of files in each folder:-"
awk '{Grp[$1]++} END {for (i in Grp) print i":"Grp[i]}' temp.txt # This command prepares a dictionary of extensions as keys and frequencies as values
rm output.txt
rm temp.txt
rm folder_count.txt
