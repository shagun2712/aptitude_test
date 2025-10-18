Below is a shortened version of the `README.md` file for the AptiGenius Flutter app, maintaining essential information for setup and execution while keeping it concise. The structure is still well-organized for GitHub.

```markdown
# AptiGenius - Aptitude Test App

## Introduction
AptiGenius is a Flutter app for practicing aptitude skills with daily and subject-wise quizzes (Quantitative Aptitude, Verbal Reasoning, Logical Reasoning). It uses Firebase for user authentication and Firestore for score tracking, with a local question bank for offline quizzes.

## Prerequisites
- **Flutter SDK**: Version 3.0.0+ ([Install](https://flutter.dev/docs/get-started/install)).
- **Dart**: Included with Flutter (2.18.0+ recommended).
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA with Flutter/Dart plugins.
- **Emulator/Device**: Android emulator/physical device or iOS simulator (Xcode, macOS only).
- **Firebase Account**: For Authentication and Firestore.
- **Firebase CLI**: Optional, install via `npm install -g firebase-tools`.
- **Git**: For cloning the repository.

## Setup and Execution Steps

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/aptigenius.git
cd aptigenius
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Set Up Firebase
1. **Create Firebase Project**:
    - In [Firebase Console](https://console.firebase.google.com/), create a project (e.g., `AptiGenius`).
    - Enable **Email/Password Authentication** under **Build > Authentication**.

2. **Add App**:
    - Add Android/iOS app in Firebase Console.
    - Android: Place `google-services.json` in `android/app/`.
    - iOS: Place `GoogleService-Info.plist` in `ios/Runner/`.

3. **Generate `firebase_options.dart`**:
   ```bash
   flutterfire configure
   ```
    - Select your Firebase project and platforms.

4. **Enable Firestore**:
    - In **Build > Firestore Database**, create a database in test mode.
    - Set Firestore rules:
      ```plaintext
      rules_version = '2';
      service cloud.firestore {
        match /databases/{database}/documents {
          match /scores/{document=**} {
            allow read, write: if request.auth != null;
          }
        }
      }
      ```

### 4. Configure Build Settings
- **Android**:
    - In `android/app/build.gradle`, set `minSdkVersion 21` and `multiDexEnabled true`.
    - In `android/build.gradle`, add:
      ```gradle
      classpath 'com.google.gms:google-services:4.4.2'
      ```
    - In `android/app/build.gradle`, add:
      ```gradle
      apply plugin: 'com.google.gms.google-services'
      ```

- **iOS**:
    - Run:
      ```bash
      cd ios
      pod install
      ```
    - Ensure `GoogleService-Info.plist` is added in Xcode.

### 5. Run the App
```bash
flutter run
```

### 6. Test the App
- **Authentication**: Register/login with email and password.
- **Quizzes**: Take daily (10 questions) or subject-wise tests.
- **Score History**: View past quiz results.

### 7. Troubleshooting
- **Firebase Errors**: Verify `google-services.json`/`GoogleService-Info.plist` and `firebase_options.dart`.
- **Firestore**: Check security rules or create composite indexes if needed.
- **Build Issues**: Run `flutter clean` and `flutter pub get`.

## Project Structure
- `lib/main.dart`: Contains all app logic (Auth, Home, Quiz, Score History).
- `lib/firebase_options.dart`: Firebase configuration.

## Notes
- Expand the question bank in `QuizPage` `_quizData` (currently ~40 questions).
- For production, secure Firestore rules and consider a backend API.

For issues or contributions, open a GitHub issue or pull request!
```

### Instructions for Use
1. Copy the above code into a file named `README.md` in your project’s root directory.
2. Replace `<your-username>` with your GitHub username or repository URL.
3. Ensure `pubspec.yaml` includes:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     firebase_core: ^3.6.0
     firebase_auth: ^5.3.1
     cloud_firestore: ^5.4.4
   ```
4. Commit and push to GitHub:
   ```bash
   git add README.md
   git commit -m "Add concise README for AptiGenius"
   git push origin main
   ```

