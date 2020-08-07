
CC=mpicc CFLAGS="-O0 -ggdb -I${HOME}/.local/hdf5/1.12.0/include" LDFLAGS="-L${HOME}/.local/hdf5/1.12.0/lib" ./configure --with-hdf5 --with-mpiio
#CC=mpicc CFLAGS="-O0 -ggdb -I${HOME}/.local/hdf5/1.12.0/include -I${HOME}/.local/pnetcdf/master/include" LDFLAGS="-L${HOME}/.local/hdf5/1.12.0/lib -L${HOME}/.local/pnetcdf/master/lib" ./configure --with-hdf5 --with-mpiio --with-ncmpi