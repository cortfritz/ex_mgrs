# Git Hooks

This directory contains git hooks for the ex_mgrs project.

## Installation

To install the hooks, run:

```bash
./hooks/install-hooks.sh
```

Or manually:

```bash
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Pre-commit Hook

The pre-commit hook enforces code quality **only on the main branch**. It runs three checks:

1. **Code Formatting**: Ensures code is formatted with `mix format`
2. **Compilation**: Ensures code compiles without warnings
3. **Tests**: Ensures all tests pass

### Bypassing the Hook

In emergency situations, you can bypass the hook with:

```bash
git commit --no-verify
```

**Note**: This should be used sparingly and only when absolutely necessary.

### Behavior on Other Branches

The pre-commit hook only runs quality checks when committing to `main`. On feature branches or other branches, the hook will skip all checks to allow for work-in-progress commits.
