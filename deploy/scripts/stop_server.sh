#!/bin/bash
set -euxo pipefail
if systemctl is-active --quiet joget-app; then
  systemctl stop joget-app
fi