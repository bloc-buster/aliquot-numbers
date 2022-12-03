#!/bin/bash

#SBATCH -p hpc5 
#SBATCH -n 1
#SBATCH -c 20
#SBATCH --mem 32G

if [[ "$#" -ne 5 ]]
then
	echo "error, only $# args in intermediate.sh"
	exit 1
fi
let xstart=$1
let xstop=$2
let ystart=$3
let ystop=$4
let granularity=$5
if [[ $granularity -le 1 ]]
then
	srun python3 sequential.py $xstart $xstop $ystart $ystop $granularity
else
	srun python3 mproc.py $xstart $xstop $ystart $ystop $granularity
fi


