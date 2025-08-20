#!/bin/bash

echo "🔌 Shutting down active SSH tunnels..."

# List of local ports used for SSH tunnels
PORTS=(8006 5240 13389 15986)

for port in "${PORTS[@]}"; do
  PIDS=$(lsof -ti tcp:"$port" -sTCP:LISTEN -c ssh)
  if [ -n "$PIDS" ]; then
    echo "➡️  Killing tunnel on port $port (PID: $PIDS)"
    kill -TERM $PIDS 2>/dev/null || kill -KILL $PIDS
  else
    echo "✔️  No SSH tunnel found on port $port"
  fi
done

echo "✅ All specified tunnels shut down."

