# 🚀 CitySmart Parking App - Deployment Guide

This guide covers deployment processes, CI/CD setup, and issue prevention for the CitySmart Parking App.

## 📋 Quick Deploy

### Local Development Deploy
```bash
# Run the automated deployment script
./scripts/deploy_web.sh

# Or manual steps:
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

### Git Hooks Setup (Recommended)
```bash
# Install pre-commit hooks to prevent issues
./scripts/setup_hooks.sh
```

## 🔧 CI/CD Configuration

### Codemagic (Recommended for Mobile)
The project includes a comprehensive `codemagic.yaml` with workflows for:

- **web-deployment**: Builds and deploys web app on every push to main
- **android-google-play**: Builds and publishes Android on tags
- **ios-testflight**: Builds and publishes iOS on tags

#### Required Environment Variables:
```bash
# Vercel
VERCEL_TOKEN=your_vercel_token

# Firebase
FIREBASE_TOKEN=your_firebase_token

# Android
GOOGLE_PLAY_SERVICE_ACCOUNT=service_account_json

# iOS
APP_STORE_CONNECT_API_KEY=your_api_key
APP_STORE_CONNECT_KEY_ID=your_key_id
APP_STORE_CONNECT_ISSUER_ID=your_issuer_id
```

### GitHub Actions (Alternative)
The project includes `.github/workflows/ci-cd.yml` with:

- **quality-checks**: Runs on all PRs and pushes
- **web-deploy**: Deploys to production on main branch
- **android-build**: Builds Android on releases
- **ios-build**: Builds iOS on releases

#### Required Secrets:
```bash
# Vercel
VERCEL_TOKEN=your_vercel_token
VERCEL_PROJECT_ID=your_project_id
VERCEL_ORG_ID=your_org_id

# Firebase
FIREBASE_TOKEN=your_firebase_token
```

## 🛡️ Issue Prevention

### Automated Checks
Both CI systems run these validation steps:

1. **Static Analysis**: `flutter analyze`
2. **Navigation Validation**: Prevents `Navigator.pushNamed` usage
3. **Font Asset Validation**: Checks for missing font files
4. **Code Formatting**: Ensures consistent formatting
5. **Tests**: Runs all unit and widget tests

### Pre-commit Hooks
Install with `./scripts/setup_hooks.sh` to prevent issues locally:

- Navigation pattern validation
- Font usage validation
- Build pattern validation (setState during build)
- Code formatting checks
- Static analysis
- Debug code detection

### Linting Rules
Enhanced `analysis_options.yaml` includes:

- Strict type checking
- Performance optimizations
- Accessibility guidelines
- Code organization rules

## 📱 Platform-Specific Deployment

### Web Deployment

#### Vercel (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Build and deploy
flutter build web --release
vercel --prod build/web
```

#### Firebase Hosting
```bash
# Install Firebase CLI
npm i -g firebase-tools

# Initialize (first time only)
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Manual/Static Hosting
```bash
# Build web app
flutter build web --release

# Upload contents of build/web/ to your hosting provider
```

### Mobile Deployment

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build iOS (requires macOS and Xcode)
flutter build ipa --release
```

## 🔍 Common Issues & Solutions

### Font Loading Issues
**Problem**: "Failed to load font Inter at assets/assets/fonts/"

**Solution**: The app now uses Roboto fallback. To add custom fonts:
1. Add font files to `assets/fonts/`
2. Update `pubspec.yaml` with correct paths
3. Update theme in `lib/citysmart/theme.dart`

### Navigation Errors
**Problem**: "Navigator.onGenerateRoute was null"

**Solution**: Use GoRouter instead:
```dart
// ❌ Wrong
Navigator.pushNamed(context, '/route');

// ✅ Correct
context.go('/route');
context.push('/route');
```

### Build Context Errors
**Problem**: "setState() called during build"

**Solution**: Use post-frame callback:
```dart
// ❌ Wrong
void initState() {
  super.initState();
  someAsyncOperation();
}

// ✅ Correct
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    someAsyncOperation();
  });
}
```

## 📊 Build Optimization

### Web Performance
The build includes optimizations:
- Canvas Kit renderer for better performance
- Tree shaking for smaller bundles
- Asset optimization

### Bundle Size Monitoring
Both CI systems report build sizes:
```bash
# Check current build size
du -sh build/web
```

## 🚨 Emergency Rollback

### Vercel
```bash
# List deployments
vercel --scope your-team

# Rollback to previous version
vercel rollback [deployment-url] --scope your-team
```

### Firebase
```bash
# View release history
firebase hosting:releases

# Rollback to previous version
firebase hosting:rollback
```

## 📞 Support

For deployment issues:
1. Check CI/CD logs in Codemagic or GitHub Actions
2. Run `./scripts/deploy_web.sh` locally to reproduce
3. Verify all environment variables are set
4. Check the Issues Prevention section above

## 🔄 Release Process

### Development
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and commit (pre-commit hooks run automatically)
3. Push and create PR
4. CI runs quality checks
5. Merge to main after approval

### Production Release
1. Create release tag: `git tag v1.0.0`
2. Push tag: `git push origin v1.0.0`
3. CI builds and deploys to production
4. Monitor deployment and perform smoke tests

### Hotfix Process
1. Create hotfix branch from main
2. Make minimal fix
3. Create PR and get fast-track approval
4. Deploy immediately upon merge

---

**Last Updated**: November 16, 2025
**Version**: 1.0.0