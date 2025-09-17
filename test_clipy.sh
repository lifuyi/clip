#!/bin/bash

echo "Starting Clipy application..."
echo "Current directory: $(pwd)"
echo "Clipy executable: $(file Clipy.app/Contents/MacOS/Clipy)"

# Kill any existing Clipy processes
pkill -f Clipy || true

# Run Clipy in background and capture output
echo "Running Clipy in background..."
./Clipy.app/Contents/MacOS/Clipy > clipy_test_output.log 2>&1 &

# Wait for 10 seconds
echo "Waiting for 10 seconds..."
sleep 10

# Kill the process
echo "Killing Clipy process..."
pkill -f Clipy || true

echo "Clipy test output:"
cat clipy_test_output.log

echo "Process list:"
ps aux | grep Clipy