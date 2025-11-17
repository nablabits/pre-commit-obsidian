#!/bin/bash

cd sandbox

# Create a new file off `new_file.md` to test timestamps autoupdate.
cp sample_new_file.md new_file.md

# add some change to `existing_file.md` so it will be picked by the script
# TODO: this probably will need an iterator over files.
echo "Some change" >> existing_file.md
echo "Some change" >> no_front_matter_file.md
echo "Some change" >> file_without_time_stamp.md

git add *.md
