#!/bin/bash

# Setup Git Hooks for CitySmart Parking App
# This script installs pre-commit hooks to prevent common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Setting up Git hooks for CitySmart Parking App..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# CitySmart Parking App Pre-commit Hook
# Prevents commits with known problematic patterns

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}[COMMIT BLOCKED]${NC} $1"; }
print_success() { echo -e "${GREEN}[COMMIT OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(dart)$' || true)

if [ -z "$STAGED_FILES" ]; then
    print_success "No Dart files to check"
    exit 0
fi

print_warning "Checking ${#STAGED_FILES[@]} staged Dart files..."

BLOCK_COMMIT=false

# Check for Navigator.pushNamed usage
if git diff --cached | grep -q "Navigator\.pushNamed\|Navigator\.pushReplacementNamed"; then
    print_error "Deprecated navigation detected!"
    echo "  Found Navigator.pushNamed or pushReplacementNamed"
    echo "  Use context.go() or context.push() from go_router instead"
    BLOCK_COMMIT=true
fi

# Check for font family issues
if git diff --cached | grep -q "fontFamily:.*['\"]Inter['\"]"; then
    print_error "Inter font detected!"
    echo "  Using Inter font family"
    echo "  Use 'SF Pro Text', 'SF Pro Display', or system fonts"
    BLOCK_COMMIT=true
fi

# Check for setState during build
if git diff --cached | grep -q "setState.*build"; then
    print_warning "Potential setState during build detected!"
    echo "  Review setState calls in build methods"
fi

# Check for missing key parameters
if git diff --cached | grep -q "class.*Widget.*{" && ! git diff --cached | grep -q "Key.*key"; then
    print_warning "Widget without key parameter detected!"
    echo "  Consider adding key parameter to custom widgets"
fi

if [ "$BLOCK_COMMIT" = true ]; then
    echo
    print_error "Commit blocked due to problematic patterns"
    echo "Fix the issues above and try again"
    exit 1
fi

print_success "Pre-commit checks passed!"
exit 0
EOF

# Make pre-commit hook executable
chmod +x .git/hooks/pre-commit

# Create commit-msg hook for message validation
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash
# CitySmart Parking App Commit Message Hook
# Validates commit message format

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}[COMMIT MSG ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[COMMIT MSG OK]${NC} $1"; }

# Skip merge commits
if echo "$COMMIT_MSG" | grep -q "^Merge"; then
    exit 0
fi

# Check minimum length
if [ ${#COMMIT_MSG} -lt 10 ]; then
    print_error "Commit message too short (minimum 10 characters)"
    echo "Current: ${#COMMIT_MSG} characters"
    echo "Message: $COMMIT_MSG"
    exit 1
fi

# Check for conventional commit format (optional but recommended)
if echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: "; then
    print_success "Conventional commit format detected"
elif echo "$COMMIT_MSG" | grep -qE "^(Add|Update|Fix|Remove|Refactor|Improve)"; then
    print_success "Good commit message format"
else
    echo -e "${YELLOW}[SUGGESTION]${NC} Consider using conventional commit format:"
    echo "  feat: add new feature"
    echo "  fix: bug fix"
    echo "  docs: documentation update"
    echo "  style: formatting changes"
    echo "  refactor: code restructuring"
    echo "  test: add or update tests"
    echo "  chore: maintenance tasks"
fi

exit 0
EOF

# Make commit-msg hook executable
chmod +x .git/hooks/commit-msg

print_success "Git hooks installed successfully!"
print_status "Hooks installed:"
print_status "  - pre-commit: Validates code patterns and prevents problematic commits"
print_status "  - commit-msg: Validates commit message format"

echo
print_status "Testing git hooks..."

# Test if hooks are working
if [ -x .git/hooks/pre-commit ]; then
    print_success "Pre-commit hook is executable"
else
    print_error "Pre-commit hook installation failed"
    exit 1
fi

if [ -x .git/hooks/commit-msg ]; then
    print_success "Commit-msg hook is executable"
else
    print_error "Commit-msg hook installation failed"
    exit 1
fi

print_success "🎉 Git hooks setup completed!"
echo
print_status "Your repository now has:"
print_status "  ✅ Pre-commit validation for navigation patterns"
print_status "  ✅ Pre-commit validation for font usage"  
print_status "  ✅ Pre-commit validation for setState issues"
print_status "  ✅ Commit message format validation"