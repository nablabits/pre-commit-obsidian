# pre-commit Script for Obsidian

Design a pre-commit script that will normalise md files mainly for Obsidian.

## Checks Performed by the Script

- If the file does not have frontmatter, it will add one with the following
  fields: `created_at`, `updated_at`, `domain` & `revisions`.
- It will update the following fields: `created_at`, `updated_at`, `revisions`
  automatically depending on the git history of the file. There are some trade
  offs around this which depend on some threshold, check `RENAME_SENSITIVITY`
  in the script.
- If the flag `CHECK_DOMAIN` is set to true, it will check that the `domain`
  field is defined in the file.
- If the array `STATUSES` is not empty, it will check that the `status` field
  is defined in the file. In the future it will check whether the such value
  matches the set of values in the array.

You can display some additional debug messages via the `--test` flag:

```bash
./pre-commit-obsidian.sh --test
```

## How to Run It in your Obsidian Installation

Dump the content of `pre-commit-obsidian.sh` into a `pre-commit` file inside
your `.git/hooks` directory.

```bash
cp pre-commit-obsidian.sh /path/to/your/obisidian/.git/hooks/pre-commit
```

Make sure to make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## How to Test It

I have created a few files that will serve as a quick test, you can run them
via these commands:

```bash
make test
```

To start over, just run:

```bash
make clean
```
