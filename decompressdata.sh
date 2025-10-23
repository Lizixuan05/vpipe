#!/bin/bash
#SBATCH -J decompress
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=01:00:00

cd /data/run01/scw6doz/lzx/vpipe
tar -xf bert_pretrain_wikicorpus_tokenized_hdf5_seqlen128.tar

