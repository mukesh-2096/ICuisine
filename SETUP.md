# 📖 iCuisine Setup Guide

This guide will walk you through setting up the iCuisine project from scratch. Follow these steps carefully to get the application running on your machine.

## 📑 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Firebase Configuration](#firebase-configuration)
4. [Cloudinary Setup](#cloudinary-setup)
5. [Environment Variables](#environment-variables)
6. [Running the Application](#running-the-application)
7. [Troubleshooting](#troubleshooting)

---

## 📋 Prerequisites

### Required Software

1. **Flutter SDK** (version 3.10.7 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Dart SDK** (comes with Flutter)
   - Verify: `dart --version`

3. **Git**
   - Download: https://git-scm.com/
   - Verify: `git --version`

4. **Code Editor**
   - [VS Code](https://code.visualstudio.com/) (Recommended) with Flutter extension
   - OR [Android Studio](https://developer.android.com/studio) with Flutter plugin

5. **Platform-Specific Requirements**
   - **Android**: Android Studio, Android SDK, Android Emulator or physical device
   - **iOS**: macOS, Xcode, iOS Simulator or physical device
   - **Web**: Chrome browser
   - **Windows**: Visual Studio 2022 with Desktop development with C++
   - **macOS**: Xcode command line tools

### Required Accounts

1. **Firebase Account** (Free)
   - Sign up: https://firebase.google.com/

2. **Cloudinary Account** (Free tier available)
   - Sign up: https://cloudinary.com/users/register/free

3. **Google Cloud Account** (Optional, for Google Maps)
   - Sign up: https://console.cloud.google.com/

---

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/icuisine.git
cd icuisine
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Setup

```bash
flutter doctor
```

Fix any issues reported by Flutter Doctor before proceeding.

---

## 🔥 Firebase Configuration

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name (e.g., "icuisine-yourname")
4. Disable Google Analytics (optional)
5. Click "Create Project"

### Step 2: Enable Authentication Methods

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:
   - ✅ **Email/Password**
   - ✅ **Google** (Configure OAuth consent screen)

### Step 3: Create Firestore Database

1. Go to **Firestore Database** → **Create Database**
2. Select "Start in test mode" (for development)
3. Choose a location close to your users
4. Click "Enable"

### Step 4: Set Up Firebase Storage

1. Go to **Storage** → **Get Started**
2. Start in test mode
3. Click "Done"

### Step 5: Configure Firebase for Your Platforms

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Configure your project:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Select platforms to support (Android, iOS, Web, etc.)
   - This will automatically create `lib/firebase_options.dart`

#### Option B: Manual Configuration

##### For Android:

1. In Firebase Console, click "Add App" → Android
2. Enter package name: `com.example.icuisine`
3. Download `google-services.json`
4. Place it in `android/app/` directory

##### For iOS:

1. In Firebase Console, click "Add App" → iOS
2. Enter bundle ID: `com.example.icuisine`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

##### For Web:

1. In Firebase Console, click "Add App" → Web
2. Register app with a nickname
3. Copy the configuration

##### Create `lib/firebase_options.dart`:

1. Copy the example file:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```

2. Edit `lib/firebase_options.dart` and replace all placeholder values with your actual Firebase credentials from the Firebase Console.

---

## ☁️ Cloudinary Setup

### Step 1: Create a Cloudinary Account

1. Go to https://cloudinary.com/users/register/free
2. Sign up for a free account
3. Verify your email

### Step 2: Get Your Credentials

1. Login to [Cloudinary Console](https://cloudinary.com/console)
2. On the Dashboard, you'll see:
   - **Cloud Name**
   - **API Key**
   - **API Secret**
3. Keep this tab open; you'll need these values

### Step 3: Create an Upload Preset

1. Go to **Settings** → **Upload**
2. Scroll to **Upload presets**
3. Click "Add upload preset"
4. Configure:
   - **Preset name**: `icuisine_uploads` (or any name you prefer)
   - **Signing mode**: Unsigned
   - **Folder**: `icuisine` (optional, for organization)
5. Click "Save"

---

## 🔐 Environment Variables

### Step 1: Create .env File

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

### Step 2: Fill in Your Credentials

Edit the `.env` file and replace the placeholder values:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name_from_dashboard
CLOUDINARY_UPLOAD_PRESET=icuisine_uploads
CLOUDINARY_API_KEY=your_api_key_from_dashboard
CLOUDINARY_API_SECRET=your_api_secret_from_dashboard

# Google Maps API Key (Optional)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Where to find these values:**

- **CLOUDINARY_CLOUD_NAME**: Cloudinary Dashboard
- **CLOUDINARY_UPLOAD_PRESET**: The preset name you created
- **CLOUDINARY_API_KEY**: Cloudinary Dashboard
- **CLOUDINARY_API_SECRET**: Cloudinary Dashboard (Click "Show" to reveal)
- **GOOGLE_MAPS_API_KEY**: [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials

### ⚠️ Important Security Notes

- ✅ **DO**: Keep `.env` file secure and never commit it to Git
- ✅ **DO**: Use `.env.example` as a template for others
- ❌ **DON'T**: Share your `.env` file or credentials publicly
- ❌ **DON'T**: Commit sensitive files to version control

**Files that are gitignored for security:**
- `.env`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## ▶️ Running the Application

### 1. Connect a Device or Start an Emulator

**Android:**
```bash
flutter emulator --launch <emulator_id>
# OR connect a physical device via USB with USB debugging enabled
```

**iOS (macOS only):**
```bash
open -a Simulator
```

**Web:**
```bash
# No device needed; Chrome will launch automatically
```

### 2. Run the App

```bash
# Default device
flutter run

# Specific device
flutter run -d <device_id>

# Release mode
flutter run --release
```

### 3. View Available Devices

```bash
flutter devices
```

### 4. Hot Reload

While the app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "No Firebase App '[DEFAULT]' has been created"

**Solution:**
- Ensure `lib/firebase_options.dart` exists and is properly configured
- Check that `Firebase.initializeApp()` is called in `main.dart`

#### 2. "Failed to load .env file"

**Solution:**
- Ensure `.env` file exists in the project root
- Check that `.env` is listed under `assets` in `pubspec.yaml`
- Run `flutter clean` and then `flutter pub get`

#### 3. "Cloudinary upload failed"

**Solution:**
- Verify all Cloudinary credentials in `.env` are correct
- Ensure upload preset is set to "Unsigned"
- Check internet connection

#### 4. "Google Sign-In not working"

**Solution:**
- Ensure SHA-1 certificate is added to Firebase (Android)
  ```bash
  cd android
  ./gradlew signingReport
  ```
  Copy SHA-1 and add it to Firebase Console → Project Settings → Your App

#### 5. Build errors after cloning

**Solution:**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # For iOS only
flutter run
```

#### 6. "Execution failed for task ':app:processDebugGoogleServices'"

**Solution:**
- Ensure `google-services.json` is in `android/app/` directory
- Check that package name in `google-services.json` matches `android/app/build.gradle`

### Still Having Issues?

1. Check Flutter version: `flutter --version`
2. Update Flutter: `flutter upgrade`
3. Check for platform-specific issues: `flutter doctor -v`
4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📊 Initial Data Setup

### Create Test Accounts

1. **Customer Account:**
   - Run the app
   - Tap "Sign Up"
   - Fill in details and create account

2. **Vendor Account:**
   - Create another account
   - In Firestore Console, manually change user type:
     - Go to `customers` collection
     - Find the user document
     - Add field: `userType` = `vendor`

### Add Sample Vendors (Optional)

Manually add to Firestore `vendors` collection:

```json
{
  "name": "Pizza Palace",
  "cuisine": "Italian",
  "rating": 4.5,
  "totalOrders": 0,
  "minimumOrder": 100,
  "deliveryTime": "30-45 min",
  "isActive": true,
  "image": "https://via.placeholder.com/300"
}
```

---

## 🎯 Next Steps

After successful setup:

1. ✅ Test customer registration and login
2. ✅ Test vendor menu creation with image upload
3. ✅ Add delivery addresses
4. ✅ Place test orders
5. ✅ Test order status updates

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## 💡 Tips

- Use **Hot Reload** (`r`) during development for faster iterations
- Run `flutter clean` if you encounter build issues
- Check `flutter doctor` regularly to ensure environment is healthy
- Use **VS Code Flutter extension** for better debugging experience
- Keep dependencies updated: `flutter pub outdated`

---

## 🆘 Getting Help

If you encounter issues not covered here:

1. Check existing GitHub issues
2. Create a new issue with:
   - Error message
   - Steps to reproduce
   - Your environment (`flutter doctor -v`)
3. Contact project maintainer

---

**Happy Coding! 🚀**
