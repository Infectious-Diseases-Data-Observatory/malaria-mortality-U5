#!/usr/bin/env bash
# Run the pipeline detached from the terminal (it survives the shell closing), logging to logs/.
#   ./run_detached.sh --all          (any run_pipeline.R options)
# Follow progress with: tail -f logs/detached_*.log   or   Rscript run_pipeline.R --list
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs
log="logs/detached_$(date +%Y%m%dT%H%M%S).log"
perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' Rscript run_pipeline.R "$@" > "$log" 2>&1 < /dev/null &
echo "Started (process $!); log: $log"
