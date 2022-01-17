#!/bin/bash

#terminate if no argument is provided to the script
if [[ -z "$1" ]]
then
	echo 'Usage ./dataformatter.sh sensorlogdir'
	exit 1
fi

#terminate if the directory name is not valid
if [[ ! -d $1 ]]
then
	echo "Error! $1 is not a valid directory name" >&2
	exit 1
fi

#look for appropriate files under the given directory hierarchy
directory=$1
set $(find $1 -name 'sensordata-*.log')

#loop through each appropriate file and generate the reformatted data
while [[ ! -z "$1" ]]
do	
	#find lines of interest
	lines=$(grep 'sensor readouts' $1)
	
	#reformat the date
	for i in {1,2}
	do
		lines="$(echo "$lines" | sed 's/-/,/')"
	done
	
	#reformat the time
	lines="$(echo "$lines" | sed 's/:/ /g')"

	#PROCESSING SENSOR DATA SET
	echo "Processing sensor data set for $1"
	echo "Year,Month,Hour,Sensor1,Sensor2,Sensor3,Sensor4,Sensor5"
	
	echo "$lines" | awk '
	{date=$1;hour=$2}
	
	#update the temperature per sensor if it was recorded
	{ if ($7 != "ERROR") { Sensor1=$7 } }
	{ if ($8 != "ERROR") { Sensor2=$8 } }
	{ if ($9 != "ERROR") { Sensor3=$9 } }
	{ if ($10 != "ERROR") { Sensor4=$10 } }
	{ if ($11 != "ERROR") { Sensor5=$11 } }
	
	#echo the information
	{OFS=","; print date, hour, Sensor1, Sensor2, Sensor3, Sensor4, Sensor5}
	END {print "===================================="}
	'
	
	#READOUT STATISTICS
	echo 'Readout statistics'
	echo 'Year,Month,Hour,MaxTemp,MaxSensor,MinTemp,MinSensor'
	
	echo "$lines" | awk '
	#determine the min and max temperatures for each hour
	{date=$1;hour=$2;minTemp=101;maxTemp=-101}
	{ for (i=7; i<=11; i++)
	       	if($i != "ERROR") 
			{if($i<minTemp) 
				{ minTemp=$i;minSensor=i-6 } } }
	{ for (i=7; i<=11; i++) 
		if($i != "ERROR") 
			{if( $i > maxTemp) 
				{ maxTemp=$i;maxSensor=i-6 } } } 	
	
	#echo the information
	{OFS=","; print date,hour,maxTemp,"Sensor"maxSensor,minTemp,"Sensor"minSensor}
	END {print "===================================="}
	'
	#update the positional parameters to loop through files of interest
	shift
done

#SENSOR ERROR STATISTICS
echo 'Sensor error statistics'
echo 'Year,Month,Day,Sensor1,Sensor2,Sensor3,Sensor4,Sensor5,Total'

#refind the files of interest
for file in $(find $directory -name 'sensordata-*.log')
do
	#find the lines of interest
	lines=$(grep 'ERROR' $file)

	#reformat the date
	for i in {1,2}
	do
		lines="$(echo "$lines" | sed 's/-/,/')"
	done

	
	#determine the number of errors reported per sensor for a given day
	echo "$lines" | awk '
	#initialize variables to 0 by default
	BEGIN {Sensor1=0;Sensor2=0;Sensor3=0;Sensor4=0;Sensor5=0;Total=0}
	{date=$1}
	
	#update the values of the variables if needed
	{ if ($5 == "ERROR") { Sensor1++ } }	
	{ if ($6 == "ERROR") { Sensor2++ } }	
	{ if ($7 == "ERROR") { Sensor3++ } }	
	{ if ($8 == "ERROR") { Sensor4++ } }	
	{ if ($9 == "ERROR") { Sensor5++ } }
	
	#echo the information
	END {OFS=","; Total=Sensor1+Sensor2+Sensor3+Sensor4+Sensor5
	print date,Sensor1,Sensor2,Sensor3,Sensor4,Sensor5,Total}
	'
done | sort -t"," -nk9,9r -nk1 -nk2 -nk3
echo "===================================="
