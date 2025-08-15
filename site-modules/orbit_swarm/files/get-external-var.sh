#!/bin/bash
# Simple script to get external variables for use in Puppet manifests
# Usage: get-external-var.sh "key.subkey" [default_value]

set -euo pipefail

KEY="$1"
DEFAULT="${2:-}"
VARIABLES_CACHE="/var/cache/puppet/orbit-puppet.yaml"

if [[ ! -f "$VARIABLES_CACHE" ]]; then
    echo "$DEFAULT"
    exit 0
fi

# Use Python to parse YAML if available
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import yaml
import sys
try:
    with open('$VARIABLES_CACHE', 'r') as f:
        data = yaml.safe_load(f) or {}

    keys = '$KEY'.split('.')
    result = data
    for k in keys:
        if isinstance(result, dict) and k in result:
            result = result[k]
        else:
            print('$DEFAULT')
            sys.exit(0)
    print(result)
except:
    print('$DEFAULT')
"
else
    echo "$DEFAULT"
fi
