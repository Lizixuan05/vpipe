#!/bin/bash
#SBATCH -J vpipe-bert
#SBATCH -N 1
#SBATCH --gres=gpu:4
#SBATCH -p gpugpu             # 根据你集群队列调整
#SBATCH --cpus-per-task=8
#SBATCH --time=01:00:00

# ------------------------------
# 环境配置
# ------------------------------
source /etc/profile.d/modules.sh
module load cuda/12.2
module load singularity
export NCCL_DEBUG=INFO
export PYTHONUNBUFFERED=1
# export CUDA_VISIBLE_DEVICES=0,1,2,3  # 注释掉，让SLURM自动分配GPU
export PYTHONPATH=/HOME/scw6doz/lzx/vpipe/runtime:$PYTHONPATH

# 禁用 Singularity 自动挂载 MOFED（InfiniBand）驱动
export SINGULARITYENV_APPEND_PATH=/usr/local/cuda/bin
export SINGULARITY_DISABLE_MOFED=1

# ------------------------------
# 运行 VPipe
# ------------------------------
cd /HOME/scw6doz/lzx/vpipe/runtime

# 只运行 driver.py，它会自行调用 singularity
srun python driver.py --config_file configs/bert_4vpipe.yml