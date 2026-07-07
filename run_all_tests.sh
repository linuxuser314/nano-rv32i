#!/bin/bash

# Define the log file
LOGFILE="master_build.log"

# Initialize the log file
echo "===================================================" > "$LOGFILE"
echo "  NANO-RV32I MASTER BUILD LOG - $(date)" >> "$LOGFILE"
echo "===================================================" >> "$LOGFILE"

echo "Starting automated run. All output is being saved to $LOGFILE..."

# Custom function to run a command, log it, and NEVER exit on error
run_step() {
    local step_name="$1"
    shift # Remove the step name so the rest of the arguments are the command
    
    echo -e "\n\n===================================================" | tee -a "$LOGFILE"
    echo "▶ RUNNING: $step_name" | tee -a "$LOGFILE"
    echo "▶ COMMAND: $@" >> "$LOGFILE"
    echo "===================================================" | tee -a "$LOGFILE"
    
    # Run the command, pipe stdout AND stderr to the log, and print to terminal
    "$@" 2>&1 | tee -a "$LOGFILE"
    
    # Capture the exit code of the actual command (ignoring the 'tee' exit code)
    local status=${PIPESTATUS[0]}
    
    echo "---------------------------------------------------" >> "$LOGFILE"
    if [ $status -ne 0 ]; then
        echo "❌ [$step_name] FAILED with exit code $status. Moving to next step..." | tee -a "$LOGFILE"
    else
        echo "✅ [$step_name] PASSED." | tee -a "$LOGFILE"
    fi
}

# 1. Clean the workspace non-interactively (safely removes ignored build artifacts)
run_step "Clean Workspace" git clean -Xdf

# 2. Build the basic assembly program
run_step "Build ASM (Blinky)" make build-asm SRC=software/blinky.s TARGET_DIR=build/target
# 4. Run the basic simulation
run_step "Run Simulation" make run-sim

# 5. Run the full RISC-V test suite
run_step "Run Test Suite" make run-tests

# 6. Run the Yosys/NextPNR Synthesis pipeline
run_step "Build Synthesis" make build-synth

echo -e "\n===================================================" | tee -a "$LOGFILE"
echo "🎉 ALL STEPS COMPLETED. Please feed $LOGFILE to the AI." | tee -a "$LOGFILE"