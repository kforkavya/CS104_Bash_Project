#!/bin/bash
srcdir=$1 #srcdir is source directory
desdir=$2 #desdir is destination directory
folder_created=0 #track of no. of folders created
touch folder_count.txt #track of folders used
touch output.txt #keeping track of files transferred
touch temp.txt

#Checking if destination doesn't exist, then create new one
if [ ! -d $desdir ]
then
mkdir $desdir
echo "Destination Directory $desdir does not exist. No worries, created one." >> output.txt
fi

#Now extracting files and checking their extensions
for i in `find $srcdir -type f`
do
filename=$(basename $i)
name=$(echo $filename | sed 's/\([^\.]*\)\.[^\.]*/\1/') #name without extension
ext=$(echo $filename | sed 's/[^\.]*\.\([^\.]*\)/\1/') #ext is extension
if [-z $ext]
then
extdir="Extension ."($ext) #extdir is extension directory
else
extdir="No Extension"

#check if extdir exists or not
if [ ! -e $desdir/$extdir ]
then
let "folder_created=folder_created+1"
mkdir $desdir/$extdir #creates new extdir
echo "A new extension folder $extdir is created" >> output.txt
fi

#Keeping track of the times when which folders are used
echo "$extdir" >> temp.txt
#Now checking if same filename already exists
newfilepath=$desdir"/"$extdir"/"$filename
if [ ! -e $newfilepath ]
then
cp $i $desdir/$extdir
echo "Added $filename to $extdir extension folder" >> output.txt
else
#the above expression returns creation time of the file
newname=$name"_"$ctime"."$extdir
cp $i $desdir/$extdir/$newname #this copies the file with a timestamp
echo "$filename already exists, so renamed to $newname and stored in $extdir extension directory" >> output.txt
fi
done


#Now extracting files and checking their creation time
for i in `find $srcdir -type f`
do
filename=$(basename $i)
name=$(echo $filename | sed 's/\([^\.]*\)\.[^\.]*/\1/') #name without extension
extdir=$(echo $filename | sed 's/[^\.]*\.\([^\.]*\)/\1/') #extdir is extension directory
ctime=$(stat $i | sed -n '/Birth/p' |  awk 'BEGIN{FS=" "}{print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') #ctime is creation time

#check if ctime exists or not
if [ ! -e $desdir/$ctime ]
then
let "folder_created=folder_created+1"
mkdir $desdir/$ctime #creates new extdir
echo "A new date folder $ctime is created" >> output.txt
fi

#Keeping track of the times when which folders are used
echo "$ctime" >> temp.txt
#Now checking if same filename already exists
newfilepath=$desdir"/"$ctime"/"$filename
if [ ! -e $newfilepath ]
then
cp $i $desdir/$ctime
echo "Added $filename to $ctime date folder" >> output.txt
else
ctime=$(stat $i | sed -n '/Birth/p' |  awk 'BEGIN{FS=" "}{print $2}' | awk 'BEGIN{FS="-"}{print $3$2$1}') #ctime is creation time
#the above expression returns creation time of the file
newname=$name"_"$ctime"."$extdir
cp $i $desdir/$ctime/$newname #this copies the file with a timestamp
echo "$filename already exists, so renamed to $newname and stored in $ctime date directory" >> output.txt
fi
done


echo "Folders created : "$folder_created
cat output.txt
echo "Number of files in each folder :-"
awk '{Grp[$1]++} END {for (i in Grp) print i":"Grp[i]}' temp.txt #This command prepares a dictionary of extensions as keys and frequencies as values
rm output.txt
rm temp.txt
rm folder_count.txt

