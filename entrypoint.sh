#!/bin/bash --login
# The --login ensures the bash configuration is loaded,
# enabling Conda.

export PATH="/home/stablediff/bin/miniconda/bin:$PATH"

cat ~/.bashrc

# Enable strict mode.
set -euo pipefail
# ... Run whatever commands ...

# Temporarily disable strict mode and activate conda:
set +euo pipefail
#conda env update -f environment.yaml
pip install -e .
conda activate ldm

# Re-enable strict mode:
set -euo pipefail

# exec the final command:
exec python3 scripts/dream.py
