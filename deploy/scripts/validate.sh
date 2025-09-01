#!/bin/bash
set -euxo pipefail
curl -fsS http://localhost/health | grep -q "OK"