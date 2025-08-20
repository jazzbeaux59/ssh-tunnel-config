#!/bin/bash
for port in 8006 5240 13389 15986; do
  fuser -k ${port}/tcp 2>/dev/null && echo "Killed tunnel on port $port"
done