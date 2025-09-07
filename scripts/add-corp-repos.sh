#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "Adding corporate CocoaPods repositories..."

# Add ssaeSCTP repo if it doesn't exist
if ! pod repo list | grep -q 'walmart-ssaesctp-cocoapodspecs'; then
  echo "Adding walmart-ssaesctp-cocoapodspecs..."
  pod repo add walmart-ssaesctp-cocoapodspecs git@gecgithub01.walmart.com:ssaeSCTP/CocoaPodSpecs.git
else
  echo "walmart-ssaesctp-cocoapodspecs already exists, skipping."
fi

# Add store-systems-associate-tech-platform repo if it doesn't exist
if ! pod repo list | grep -q 'walmart-store-systems-associate-tech-platform-cocoapods-specs'; then
  echo "Adding walmart-store-systems-associate-tech-platform-cocoapods-specs..."
  pod repo add walmart-store-systems-associate-tech-platform-cocoapods-specs git@gecgithub01.walmart.com:store-systems-associate-tech-platform/cocoapods-specs.git
else
  echo "walmart-store-systems-associate-tech-platform-cocoapods-specs already exists, skipping."
fi

echo "Done. Corporate repositories added."
pod repo list