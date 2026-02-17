# 🍽️ iCuisine

A modern food delivery application built with Flutter and Firebase. iCuisine connects customers with local food vendors, offering a seamless experience for ordering and managing food deliveries.

## ✨ Features

### For Customers
- 🔐 **Authentication**: Email/Password and Google Sign-in
- 🏪 **Vendor Discovery**: Browse and search local food vendors
- 🍕 **Menu Browsing**: View detailed menus with images and prices
- 🛒 **Shopping Cart**: Add items, manage quantities, and track subtotal
- 📍 **Address Management**: Save multiple delivery addresses with labels
- 💳 **Payment Options**: Cash on Delivery and UPI/QR Code payments
- 📦 **Order Tracking**: Real-time order status updates (Pending → Received → Cooking → Ready → Delivered)
- 📱 **Slide Pagination**: View orders in organized slides (5 per page) instead of endless scrolling
- ⭐ **Favorites**: Save favorite food items for quick reordering
- 🔔 **Notifications**: Stay updated on order status changes

### For Vendors
- 📊 **Dashboard**: Overview of orders and performance metrics
- 🍔 **Menu Management**: Add, edit, and delete menu items with images
- 📸 **Image Upload**: Cloudinary integration for fast image uploads
- 📋 **Order Management**: View and update order statuses
- 👥 **Customer Information**: Access customer details and delivery addresses
- 📈 **Real-time Updates**: Live order notifications and status tracking

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10.7+
- **Language**: Dart
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **State Management**: StatefulWidget
- **Image Storage**: Cloudinary
- **UI**: Google Fonts, Custom Material Design
- **Environment Variables**: flutter_dotenv

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.7 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- A Firebase account ([Create one here](https://firebase.google.com/))
- A Cloudinary account ([Sign up here](https://cloudinary.com/))

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/mukesh-2096/ICuisine.git
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Environment Variables

Create a `.env` file in the root directory by copying the example:

```bash
cp .env.example .env
```

Then edit `.env` and add your credentials:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_UPLOAD_PRESET=your_upload_preset_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 4. Set Up Firebase

Create `lib/firebase_options.dart` by copying the example:

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

Then either:
- **Option A**: Use FlutterFire CLI (Recommended)
  ```bash
  flutterfire configure
  ```
- **Option B**: Manually edit `lib/firebase_options.dart` with your Firebase project credentials

### 5. Add Firebase Configuration Files

- **Android**: Download `google-services.json` from Firebase Console and place it in `android/app/`
- **iOS**: Download `GoogleService-Info.plist` from Firebase Console and place it in `ios/Runner/`

### 6. Run the App

```bash
flutter run
```

For more detailed setup instructions, see [SETUP.md](SETUP.md).

## 📁 Project Structure

```
lib/
├── config/
│   └── api_keys.dart          # API keys configuration (reads from .env)
├── models/                    # Data models
├── screens/
│   ├── customer/              # Customer-facing screens
│   │   ├── cart_page.dart
│   │   ├── customer_dashboard.dart
│   │   ├── my_orders_page.dart
│   │   └── ...
│   └── vendor/                # Vendor-facing screens
│       ├── vendor_dashboard.dart
│       ├── vendor_menu_management.dart
│       └── ...
├── services/
│   ├── auth_service.dart      # Authentication logic
│   ├── cart_service.dart      # Cart operations
│   ├── cloudinary_service.dart # Image uploads
│   └── ...
├── utils/                     # Utility functions
├── widgets/                   # Reusable widgets
├── firebase_options.dart      # Firebase configuration (gitignored)
└── main.dart                  # App entry point
```

## 🔒 Security

**Important**: The following files contain sensitive information and are excluded from version control:

- `.env` - Environment variables (API keys, secrets)
- `lib/firebase_options.dart` - Firebase configuration
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

Never commit these files to a public repository!

## 🎨 UI/UX Highlights

- **Dark Mode Design**: Modern dark theme with orange accents
- **Smooth Animations**: Slide transitions and page animations
- **Responsive Layout**: Works on various screen sizes
- **Intuitive Navigation**: Bottom nav bar with icons
- **Visual Feedback**: Loading states, success dialogs, snackbar notifications

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Contact: [durgasaimukeshvantakula5764@gmail.com]

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Cloudinary for image management
- Google Fonts for typography

---

**Made with ❤️ using Flutter**
