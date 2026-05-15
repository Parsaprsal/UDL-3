#!/bin/bash

docker stop warp || true
docker rm warp || true
echo "✅ WARP container stopped and removed"