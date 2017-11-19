#!/bin/bash
#SBATCH -p debug
#SBATCH -N 1 
#SBATCH -C haswell
#SBATCH -t 00:10:00
#SBATCH -o ior_1.txt
#DW jobdw capacity=1289GiB access_mode=striped type=scratch pool=sm_pool

RUNS=(1) # Number of runs
BSIZE=67108864
TSIZE=1048576
OUTDIR=/global/cscratch1/sd/khl7265/FS_64_8M/ior
BBDIR=${DW_JOB_STRIPED}ior
NN=${SLURM_NNODES}
let NP=NN*1
#let NP=NN*32 

echo "mkdir -p ${OUTDIR}"
mkdir -p ${OUTDIR}
echo "mkdir -p ${BBDIR}"
mkdir -p ${BBDIR}

for u in blocking nonblocking
do
    for v in coll indep
    do
        COLL=
        NB=
        if [ "x${v}" = "xcoll" ]; then
            COLL=-c
        fi
        if [ "x${u}" = "xnonblocking" ]; then
            NB=-y
        fi

        # Ncmpi
        if [ "x${v}" = "xcoll" ]; then
            for i in ${RUNS[@]}
            do
                echo "rm -f ${OUTDIR}/*"
                rm -f ${OUTDIR}/*
                
                srun -n ${NP} ./IOR -a NCMPI -b ${BSIZE} -t ${TSIZE} -i 1 -w -o ${OUTDIR}/ior.bin -k ${COLL} ${NB}

                echo "#%$: io_pattern: sequential"
                echo "#%$: io_driver: ncmpi"
                echo "#%$: number_of_nodes: ${NN}"
                echo "#%$: number_of_procs: ${NP}"
                echo "#%$: io_mode: ${u}_${v}"

                echo "ls -lah ${OUTDIR}"
                ls -lah ${OUTDIR}
                
                echo '-----+-----++------------+++++++++--+---'
            done
            echo '--++---+----+++-----++++---+++--+-++--+---'
        fi

        # Bb
        if [ "x${u}" = "xblocking" ] && [ "x${v}" = "xcoll" ]; then
            export PNETCDF_HINTS="nc_bb_driver=enable;nc_bb_del_on_close=disable;nc_bb_overwrite=enable;nc_bb_dirname=${BBDIR}"
            for i in ${RUNS[@]}
            do
                echo "rm -f ${OUTDIR}/*"
                rm -f ${OUTDIR}/*
                echo "rm -f ${BBDIR}/*"
                rm -f ${BBDIR}/*
                
                srun -n ${NP} ./IOR -a NCMPI -b ${BSIZE} -t ${TSIZE} -i 1 -w -o ${OUTDIR}/ior.bin -k ${COLL} ${NB}

                echo "#%$: io_pattern: sequential"
                echo "#%$: io_driver: bb"     
                echo "#%$: number_of_nodes: ${NN}"
                echo "#%$: number_of_procs: ${NP}"
                echo "#%$: io_mode: ${u}_${v}"
                
                echo "ls -lah ${OUTDIR}"
                ls -lah ${OUTDIR}
                if ["${NP}" -lt 33]; then
                    echo "ls -lah ${BBDIR}"
                    ls -lah ${BBDIR}
                fi
                            
                echo '-----+-----++------------+++++++++--+---'
            done
            unset PNETCDF_HINTS
            echo '--++---+----+++-----++++---+++--+-++--+---'
        fi

        # Bb_shared
        if [ "x${u}" = "xblocking" ] && [ "x${v}" = "xcoll" ]; then
            export PNETCDF_HINTS="nc_bb_driver=enable;nc_bb_del_on_close=disable;nc_bb_overwrite=enable;nc_bb_sharedlog=enable;nc_bb_dirname=${BBDIR}"
            for i in ${RUNS[@]}
            do
                echo "rm -f ${OUTDIR}/*"
                rm -f ${OUTDIR}/*
                echo "rm -f ${BBDIR}/*"
                rm -f ${BBDIR}/*
                
                srun -n ${NP} ./IOR -a NCMPI -b ${BSIZE} -t ${TSIZE} -i 1 -w -o ${OUTDIR}/ior.bin -k ${COLL} ${NB}

                echo "#%$: io_pattern: sequential"
                echo "#%$: io_driver: bb_shared"     
                echo "#%$: number_of_nodes: ${NN}"
                echo "#%$: number_of_procs: ${NP}"
                echo "#%$: io_mode: ${u}_${v}"
                
                echo "ls -lah ${OUTDIR}"
                ls -lah ${OUTDIR}
                if ["${NP}" -lt 33]; then
                    echo "ls -lah ${BBDIR}"
                    ls -lah ${BBDIR}
                fi
                            
                echo '-----+-----++------------+++++++++--+---'
            done
            unset PNETCDF_HINTS
            echo '--++---+----+++-----++++---+++--+-++--+---'
        fi

        # Staging
        export stageout_bb_path="${BBDIR}"
        export stageout_pfs_path="${OUTDIR}"
        for i in ${RUNS[@]}
        do
            echo "rm -f ${OUTDIR}/*"
            rm -f ${OUTDIR}/*
            echo "rm -f ${BBDIR}/*"
            rm -f ${BBDIR}/*
            
            srun -n ${NP} ./IOR -a NCMPI -b ${BSIZE} -t ${TSIZE} -i 1 -w -o ${BBDIR}/ior.bin -k ${COLL} ${NB}

            echo "#%$: io_pattern: sequential"
            echo "#%$: io_driver: stage"
            echo "#%$: number_of_nodes: ${NN}"
            echo "#%$: number_of_procs: ${NP}"
            echo "#%$: io_mode: ${u}_${v}"

            echo "ls -lah ${OUTDIR}"
            ls -lah ${OUTDIR}
            echo "ls -lah ${BBDIR}"
            ls -lah ${BBDIR}
            
            echo '-----+-----++------------+++++++++--+---'
        done
        unset stageout_bb_path
        unset stageout_pfs_path
        echo '--++---+----+++-----++++---+++--+-++--+---'
    done
done

echo "BB Info: "
module load dws
sessID=$(dwstat sessions | grep $SLURM_JOBID | awk '{print $1}')
echo "session ID is: "${sessID}
instID=$(dwstat instances | grep $sessID | awk '{print $1}')
echo "instance ID is: "${instID}
echo "fragments list:"
echo "frag state instID capacity gran node"
dwstat fragments | grep ${instID}


