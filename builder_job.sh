#!/bin/bash
#SBATCH --job-name=builder
#SBATCH --cpus-per-task 20
#SBATCH --mem 63940M
#SBATCH --partition fast
#SBATCH --nodes 1
#SBATCH --dependency=singleton
#SBATCH --time=05:00:00

JOB_PERIOD=$((7 * 24 * 3600))
JOB_OFFSET=$((2 * 3600))

function _requeue() {
  local now timespec
  now="$(date '+%s')"
  timespec="$(date --date="@$(((now / JOB_PERIOD + 1) * JOB_PERIOD + JOB_OFFSET))" '+%Y-%m-%dT%H:%M:%S')"

  echo "$(date): requeing job $SLURM_JOB_ID ($SLURM_JOB_NAME) to run at $timespec"

  scontrol requeue "$SLURM_JOB_ID"
  scontrol update JobId="$SLURM_JOB_ID" StartTime="$timespec"
}
trap '_requeue' EXIT HUP INT TERM ERR

unset XDG_RUNTIME_DIR

podman unshare rm -rf /scratch/$USER/builder

mkdir -p /scratch/$USER/builder
cp builder.sh /scratch/$USER/builder
podman run --rm --network=host -v /scratch/$USER/builder:/root public.ecr.aws/ubuntu/ubuntu:latest /root/builder.sh

cd /scratch/$USER/builder/android/pe/out/target/product/walleye
shopt -s nullglob
zip_file="$(echo PixelExperience_*.zip)"
if [[ -f "$zip_file" ]]; then
    build_id="$(basename "$zip_file" .zip)"
    mkdir -p ~/builds/"$build_id"
    cp PixelExperience_* ~/builds/"$build_id"
    cp boot.img ~/builds/"$build_id"
    cd

    podman unshare rm -rf /scratch/$USER/builder
fi
