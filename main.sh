#!/bin/bash

if [[ "$#" -lt 2 ]]
then
	echo "usage: main.sh granularity1 granularity2 [lower_bound upper_bound] [outputfolder]"
	echo "-p compute total processes or total jobs"
	echo "-t T P total time with time for 1 comparison T and processors per node P"
	exit 1
fi
computeN="false"
if [[ $1 == "-p" ]]
then
	computeN="true"
	shift
fi
computeTime="false"
if [[ $1 == "-t" ]]
then
	computeTime="true"
	shift
	timePerComputation=$1
	shift
	processorsPerNode=$1
	shift
fi
if [[ $computeN == "true" && $computeTime == "true" ]]
then
	echo "error - cannot use both -n and -t"
	exit 1
fi
let granularity1=$1
let granularity2=$2
# 220 284, 1184 1210, 2620 2924, 5020 5564, 6232 6368, 10744 10856, 12285 14595, 19296 18416, 63020 76084, 66928 66992 
let lower=200
let upper=300
if [[ "$#" -ge 4 ]]
then
	let lower=$3
	let upper=$4
fi
outputfolder="results"
if [[ "$#" -ge 5 ]]
then
	outputfolder=$5
fi
command mkdir $outputfolder
let range=$(( upper - lower + 1 ))
let step=$(( range / granularity1 ))
if [[ $step -lt 1 ]]
then
	let step=1
fi
echo "g1 $granularity1 g2 $granularity2 lower $lower upper $upper range $range step $step"
if [[ $computeN == "true" ]]
then
	let m=$granularity1
	let n=$granularity2
	if [[ $n -le 1 ]]
	then
		# total jobs
		let N=$(( (m * (m + 1)) / 2 )) 
		# total computations
		let N2=$(( (range * (range + 1)) / 2 ))
		# computations per job
		let N3=$(( $N2 / $N ))
		echo "total jobs $N total comparisons $N2 average comparisons per job $N3"
	else
		# total jobs
		let N1=$(( (m * (m + 1)) / 2 )) 
		# total processes
		let N2=$(( ((m * n) * (m * n + 1)) / 2 ))
		# average processes per job
		let N3=$(( (n * (m * n + 1)) / (m + 1) ))
		# total computations
		let N4=$(( (range * (range + 1)) / 2 ))
		# average computations per process
		let N5=$(( N4 / N2 ))
		echo "jobs $N1 total processes $N2 average processes per job $N3 total comparisons $N4 average comparisons per process $N5"
	fi
	exit 0
fi
if [[ $computeTime == "true" ]]
then
	let m=$granularity1
	let n=$granularity2
	if [[ $n -le 1 ]]
	then
		# total comparisons
		let N=$(( (range * (range + 1)) / 2 ))
		# sequential time
		T=$( echo "$N * $timePerComputation" | bc -l )
		# total jobs
		let J=$(( (m * (m + 1)) / 2 )) 
		# total time with multiprocessing
		t=$( echo "($N / $J) * $timePerComputation" | bc -l )
		echo "total time sequentially $T s"
		echo "total time with multiprocessing $t s"
	else
		# total comparisons
		let N=$(( (range * (range + 1)) / 2 ))
		# sequential time
		T=$( echo "$timePerComputation * $N" | bc -l )
		# total jobs
		let J=$(( (m * (m + 1)) / 2 )) 
		# total processes
		let P=$(( ((m * n) * (m * n + 1)) / 2 ))
		# average processes per job
		let p=$(( (n * (m * n + 1)) / (m + 1) ))
		# effective processes rounded up
		#let E=$(($p%$processorsPerNode?$p/$processorsPerNode+1:$p/$processorsPerNode))
		# effective processes as float >= 1
		E=$( echo "$p / $processorsPerNode" | bc -l )
		if [[ $p -lt $processorsPerNode ]]
		then
			echo "error - effective processes $E"
			let E=1
		fi
		echo "effective processes $E"
		# average computations per process
		c=$( echo "$N / $P" | bc -l )
		echo "comps per process $c"
		# total multiprocessing time
		t=$( echo "$E * $c * $timePerComputation" | bc -l )
		# average time per process
		#t=$( echo "$c * $timePerComputation" | bc -l )
		# total time with multiprocessing
		#t=$( echo "$E * $t" | bc -l )
		#T=$( echo "$E * $timePerComputation * $c" | bc -l )
		echo "total time sequentially $T s"
		echo "total time with multiprocessing $t s"
	fi
	exit 0
fi
let count=1
xstart=()
xstop=()
ystart=()
ystop=()
for (( x = 1; x <= $granularity1; x += 1 ))
do
	for (( y = 1; y <= $granularity1; y += 1 ))
	do
		if [[ $x -gt $y ]]
		then
			continue
		fi
		if [[ $x -eq $(( granularity1 )) ]]
		then
			xstart+=( $(( (x-1) * $step + lower)) )
			xstop+=( $upper )
		else
			xstart+=( $(( (x-1) * $step + lower)) )
			xstop+=( $(( x * $step + lower - 1)) )
		fi
		if [[ $y -eq $(( granularity1 )) ]]
		then
			ystart+=( $(( (y-1) * $step + lower)) )
			ystop+=( $upper )
		else
			ystart+=( $(( (y-1) * $step + lower)) )
			ystop+=( $(( y * $step + lower - 1)) )
		fi
	done
done
#for (( x = 0; x < ${#xstart[@]}; x += 1 ))
#do
#	echo "xstart ${xstart[$x]} xstop ${xstop[$x]} ystart ${ystart[$x]} ystop ${ystop[$x]} "
#done
#exit 1
for (( x = 0; x < ${#xstart[@]}; x += 1 ))
do
	echo "running command intermediate.sh ${xstart[$x]} ${xstop[$x]} ${ystart[$x]} ${ystop[$x]} $granularity2"
	command sbatch --output="$outputfolder/batch-%j.out" intermediate.sh ${xstart[$x]} ${xstop[$x]} ${ystart[$x]} ${ystop[$x]} $granularity2
done

