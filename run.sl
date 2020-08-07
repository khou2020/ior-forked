#!/bin/bash
#SBATCH -p debug
#SBATCH -N 1
#SBATCH -C haswell
#SBATCH -t 00:01:00
#SBATCH -o ior_1_%j.txt
#SBATCH -e ior_1_%j.err
#SBATCH -L SCRATCH
#SBATCH -A m2956

NN=${SLURM_NNODES}
#let NP=NN*1
let NP=NN*32

export LD_LIBRARY_PATH=/global/homes/k/khl7265/.local/hdf5/1.12.0/lib:${HOME}/.local/log_io_vol/master/lib:${LD_LIBRARY_PATH}

RUNS=(1 2) # Number of runs

OUTDIR=/global/cscratch1/sd/khl7265/FS_64_1M/IOR/

APP=src/ior
#APP=src/ior_profiling
BSIZE=1048576
XSIZE=1048576
NB=32
APIS=(pnc hdf5 logvol)
OPS=(write)
TL=3

ulimit -c unlimited

TSTARTTIME=`date +%s.%N`

for i in ${RUNS[@]}
do
    echo "rm -f ${OUTDIR}/*"
    #rm -f ${OUTDIR}/*

    for OP in ${OPS[@]}
    do
        for API in ${APIS[@]}
        do
            FILEPATH=${OUTDIR}/IOR.${API}

            if [ "${API}" = "logvol" ] ; then
                export HDF5_VOL_CONNECTOR="LOG under_vol=0;under_info={}"
                export HDF5_PLUGIN_PATH=${HOME}/.local/log_io_vol/master/lib
                IORAPI="hdf5"
            else
                unset HDF5_VOL_CONNECTOR
                unset HDF5_PLUGIN_PATH
                IORAPI=${API}
            fi

            echo "========================== IOR ${API} ${OP} =========================="
            >&2 echo "========================== IOR ${API} ${OP}=========================="
            
            echo "#%$: exp: IOR"
            echo "#%$: app: ${APP}"
            echo "#%$: api: ${API}"
            echo "#%$: operation: ${OP}"
            echo "#%$: filepath: ${FILEPATH}"
            echo "#%$: block_size: ${BSIZE}"
            echo "#%$: xfer_size: ${XSIZE}"
            echo "#%$: nblocks: ${NB}"
            echo "#%$: number_of_nodes: ${NN}"
            echo "#%$: number_of_proc: ${NP}"

            STARTTIME=`date +%s.%N`

            if [ "$OP" = "write" ] ; then
                echo "srun -n ${NP} -t ${TL} ./${APP} -a ${IORAPI} -w -o ${FILEPATH} -c -b ${BSIZE} -t ${XSIZE} -s ${NB}"
                #srun -n ${NP} -t ${TL} ./${APP} -a ${IORAPI} -w -o ${FILEPATH} -c -b ${BSIZE} -t ${XSIZE} -s ${NB}
            else 
                echo "srun -n ${NP} -t ${TL} ./${APP} -a ${IORAPI} -r -o ${FILEPATH} -c -b ${BSIZE} -t ${XSIZE} -s ${NB}"
                srun -n ${NP} -t ${TL} ./${APP} -a ${IORAPI} -r -o ${FILEPATH} -c -b ${BSIZE} -t ${XSIZE} -s ${NB}
            fi

            ENDTIME=`date +%s.%N`
            TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

            echo "#%$: exe_time: $TIMEDIFF"

            echo "ls -lah ${OUTDIR}"
            ls -lah ${OUTDIR}
            echo "lfs getstripe ${OUTDIR}"
            lfs getstripe ${OUTDIR}

            echo '-----+-----++------------+++++++++--+---'
        done
    done
done

ENDTIME=`date +%s.%N`
TIMEDIFF=`echo "$ENDTIME - $TSTARTTIME" | bc | awk -F"." '{print $1"."$2}'`
echo "-------------------------------------------------------------"
echo "total_exe_time: $TIMEDIFF"
echo "-------------------------------------------------------------"