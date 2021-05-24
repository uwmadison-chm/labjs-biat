DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

/apps/x86_64_sci7/current/bin/singularity run \
  --bind /study/chad:/study/chad \
  --app R r.sif --nosave

