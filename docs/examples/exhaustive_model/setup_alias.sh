#!/bin/bash
# Setup alias for Vulcan Docker command
# Usage: source setup_alias.sh
# Or add to your ~/.zshrc or ~/.bashrc

alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev vulcan"

echo "Vulcan alias has been set up!"
echo "You can now use: vulcan info, vulcan plan, etc."
echo ""
echo "To make this permanent, add this line to your ~/.zshrc or ~/.bashrc:"
echo "alias vulcan=\"docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev vulcan\""

