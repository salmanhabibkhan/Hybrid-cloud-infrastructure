#!/bin/bash
set -euxo pipefail

# Prefer curl if present; fallback to checking file directly
if command -v curl >/dev/null 2>&1; then
  curl -fsS http://localhost/health | grep -q "OK"
else
  grep -q "OK" /var/www/html/health
fi