#!/usr/bin/env bash
set -euo pipefail
HOST=$1
SNAPSHOT_NAME=auto-`date +%Y-%m-%d_%H-%M-%S`
VBoxManage snapshot $HOST take $SNAPSHOT_NAME --live
