#!/bin/bash

git restore --staged sandbox/*.md

rm -rf sandbox/new_file.md

git restore sandbox/*.md