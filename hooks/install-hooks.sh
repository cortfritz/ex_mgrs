#!/bin/sh
#
# Install git hooks for ex_mgrs
#
# Usage: ./hooks/install-hooks.sh

set -e

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

echo "Installing git hooks..."

# Install pre-commit hook
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
  chmod +x "$GIT_HOOKS_DIR/pre-commit"
  echo "✓ Installed pre-commit hook"
else
  echo "❌ Error: pre-commit hook not found at $HOOKS_DIR/pre-commit"
  exit 1
fi

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will run on commits to the main branch and check:"
echo "  - Code formatting (mix format --check-formatted)"
echo "  - No compilation warnings (mix compile --warnings-as-errors)"
echo "  - All tests passing (mix test)"
echo ""
echo "To bypass the hook in emergency situations, use: git commit --no-verify"
