#!/bin/bash

cd sandbox

# Create a new file off `new_file.md` to test timestamps autoupdate.
cp sample_new_file.md new_file.md

# add some change to `existing_file.md` so it will be picked by the script
echo "Some change" >> existing_file.md

git add .
