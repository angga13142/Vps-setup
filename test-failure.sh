#!/bin/bash
# Intentional ShellCheck error: unquoted variable
VAR=test
echo $VAR  # SC2086: Double quote to prevent globbing
