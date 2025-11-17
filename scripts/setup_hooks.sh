#!/bin/bash

# CitySmart Parking App - Git Hooks Setup
# Sets up pre-commit hooks to prevent deployment issues

echo "🔧 Setting up Git hooks for CitySmart Parking App..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a Git repository. Please run this from the project root."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy our custom pre-commit hook
if [ -f ".githooks/pre-commit" ]; then
    cp .githooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Pre-commit hook source not found at .githooks/pre-commit"
    exit 1
fi

# Test the hook
echo ""
echo "🧪 Testing pre-commit hook..."
if .git/hooks/pre-commit; then
    echo "✅ Pre-commit hook test passed"
else
    echo "❌ Pre-commit hook test failed"
fi

echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "The following checks will now run before each commit:"
echo "  ✅ Navigation pattern validation (no Navigator.pushNamed)"
echo "  ✅ Font usage validation"
echo "  ✅ Build pattern validation (no setState during build)"
echo "  ✅ Code formatting"
echo "  ✅ Static analysis"
echo "  ✅ Debug code detection"
echo ""
echo "To bypass checks temporarily (not recommended):"
echo "  git commit --no-verify"