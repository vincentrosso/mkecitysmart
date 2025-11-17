#!/bin/bash

# CitySmart Parking App - Web Deployment Script
# This script runs pre-deploy checks, builds the web app, and optionally deploys it

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

print_status "Starting CitySmart Parking App deployment process..."

# Step 1: Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Step 2: Run static analysis (allow warnings)
print_status "Running static analysis..."
if ! flutter analyze --no-fatal-infos --no-fatal-warnings; then
    print_error "Critical static analysis errors found. Please fix before deploying."
    exit 1
fi
print_success "Static analysis passed (warnings allowed)!"

# Step 3: Check for deprecated navigation patterns
print_status "Checking for deprecated navigation patterns..."
if grep -r "Navigator\.pushNamed" lib/ 2>/dev/null; then
    print_error "Found Navigator.pushNamed usage. Please use GoRouter context.go() instead."
    exit 1
fi
print_success "Navigation patterns check passed!"

# Step 4: Validate font assets exist
print_status "Validating font assets..."
MISSING_FONTS=()
while IFS= read -r font_path; do
    if [[ "$font_path" == *"asset:"* ]]; then
        # Extract the asset path
        asset_path=$(echo "$font_path" | sed 's/.*asset: *//' | sed 's/ *$//')
        if [ ! -f "$asset_path" ]; then
            MISSING_FONTS+=("$asset_path")
        fi
    fi
done < <(grep -A 10 "fonts:" pubspec.yaml | grep "asset:")

if [ ${#MISSING_FONTS[@]} -ne 0 ]; then
    print_warning "Missing font assets found:"
    for font in "${MISSING_FONTS[@]}"; do
        print_warning "  - $font"
    done
    print_warning "App will use system fallback fonts."
else
    print_success "All font assets validated!"
fi

# Step 5: Run tests
print_status "Running tests..."
if ! flutter test; then
    print_error "Tests failed. Please fix the failing tests before deploying."
    exit 1
fi
print_success "All tests passed!"

# Step 6: Build web release
print_status "Building web release..."
if ! flutter build web --release; then
    print_error "Web build failed. Please check the build output for errors."
    exit 1
fi
print_success "Web build completed successfully!"

# Step 7: Build size analysis
BUILD_SIZE=$(du -sh build/web 2>/dev/null | cut -f1 || echo "Unknown")
print_success "Build output size: $BUILD_SIZE"
print_success "Build artifacts location: build/web/"

# Step 8: Optional deployment
DEPLOY_TARGET=""
while [[ ! "$DEPLOY_TARGET" =~ ^(vercel|firebase|skip)$ ]]; do
    echo ""
    echo "Choose deployment target:"
    echo "1) vercel  - Deploy to Vercel"
    echo "2) firebase - Deploy to Firebase Hosting"
    echo "3) skip    - Skip deployment (just build)"
    echo ""
    read -p "Enter choice (vercel/firebase/skip): " DEPLOY_TARGET
done

case $DEPLOY_TARGET in
    "vercel")
        print_status "Deploying to Vercel..."
        if command -v vercel >/dev/null 2>&1; then
            if vercel --prod build/web; then
                print_success "Successfully deployed to Vercel!"
            else
                print_error "Vercel deployment failed."
                exit 1
            fi
        else
            print_error "Vercel CLI not found. Install with: npm i -g vercel"
            print_status "Manual deployment: Upload contents of build/web/ to Vercel"
        fi
        ;;
    "firebase")
        print_status "Deploying to Firebase Hosting..."
        if command -v firebase >/dev/null 2>&1; then
            if firebase deploy --only hosting; then
                print_success "Successfully deployed to Firebase!"
            else
                print_error "Firebase deployment failed."
                exit 1
            fi
        else
            print_error "Firebase CLI not found. Install with: npm i -g firebase-tools"
            print_status "Manual deployment: Run 'firebase init hosting' and 'firebase deploy'"
        fi
        ;;
    "skip")
        print_status "Skipping deployment as requested."
        ;;
esac

echo ""
print_success "🎉 Deployment process completed!"
print_status "Build artifacts are ready in build/web/"

# Step 9: Generate deployment summary
cat << EOF

📊 DEPLOYMENT SUMMARY
====================
✅ Static analysis: PASSED
✅ Navigation check: PASSED  
✅ Font validation: COMPLETED
✅ Tests: PASSED
✅ Web build: SUCCESS
📦 Build size: $BUILD_SIZE
🎯 Target: $DEPLOY_TARGET

📁 Files ready for deployment:
   build/web/index.html
   build/web/main.dart.js
   build/web/assets/...

🚀 Next steps:
   - Test the deployed app thoroughly
   - Update DNS/domain if needed
   - Monitor performance and errors

EOF

print_success "CitySmart Parking App deployment completed successfully! 🚗✨"