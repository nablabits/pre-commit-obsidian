---
created_at: 2025-09-27
updated_at: 2025-09-27
domain: domain1
co-domains:
  - domain2
tags:
  - tag1
  - tag2
main_link: 
revisions: 1
status: express
version: "3.5"
aliases:
  - test_created_at
---

# Test created_at for Existing Files

This file is an existing file to test the `created_at`, when running the script,
its date should be updated to the date it appears in the first commit
(2025-11-16). Its `updated_at` should be updated to the current date.

Then, I added some other content so as to have a commit on a different date.
