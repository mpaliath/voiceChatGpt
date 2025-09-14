#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "Removing corporate CocoaPods repositories..."

# Remove ssaeSCTP repo if it exists
if pod repo list | grep -q 'walmart-ssaesctp-cocoapodspecs'; then
  echo "Removing walmart-ssaesctp-cocoapodspecs..."
  pod repo remove walmart-ssaesctp-cocoapodspecs
else
  echo "walmart-ssaesctp-cocoapodspecs not found, skipping."
fi

# Remove store-systems-associate-tech-platform repo if it exists
if pod repo list | grep -q 'walmart-store-systems-associate-tech-platform-cocoapods-specs'; then
  echo "Removing walmart-store-systems-associate-tech-platform-cocoapods-specs..."
  pod repo remove walmart-store-systems-associate-tech-platform-cocoapods-specs
else
  echo "walmart-store-systems-associate-tech-platform-cocoapods-specs not found, skipping."
fi

echo "Done. Corporate repositories removed."
pod repo list