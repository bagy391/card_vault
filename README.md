# Card Vault

Card Vault is a secure, elegant Flutter application designed to store your credit and debit card details locally on your device. It combines premium UI design with military-grade security to ensure your data remains safe and accessible only to you.

## 🔒 Security & Privacy

Card Vault is built with a **Security-First** and **Offline-Only** architecture. We believe your financial data should never leave your control.

### How we protect your data:

1.  **Local Storage Only**:
    *   **Zero Cloud Sync**: The app has **NO internet permissions** and does **NO networking**. Your data never leaves your device.
    *   **Offline Access**: All functionality works largely offline.

2.  **Military-Grade Encryption (AES-256)**:
    *   All card sensitive data (Card Number, CVV, Expiry, Holder Name) is encrypted using **AES-256 (Advanced Encryption Standard)** before it is ever written to disk.
    *   We use the `encrypt` package in Flutter to handle these cryptographic operations.

3.  **Secure Key Management**:
    *   The **Encryption Key** used to lock your data is generated securely on your device.
    *   This key is stored in the device's hardware-backed secure storage:
        *   **Android**: Encrypted SharedPreferences / Keystore (via `flutter_secure_storage`).
        *   **iOS**: Keychain (via `flutter_secure_storage`).
    *   This means even if someone extracts the data files from your phone, they are useless encrypted strings without the key safely hidden in the Secure Element.

4.  **Biometric & Device Lock**:
    *   The app is protected by your device's native authentication (Fingerprint, Face ID, or PIN/Pattern).
    *   You must authenticate every time you launch the app to access your vault.

## ✨ Features

*   **Beautiful UI**: A vertically scrolling, stacked "Wallet" interface similar to premium fintech apps.
*   **Smooth Interactions**:
    *   **Tap** to expand a card and view details.
    *   **Long Press** to edit or delete a card.
    *   **Scroll** to automatically collapse the stack.
*   **Smart Details**:
    *   Auto-detects card type (Visa, MasterCard, Amex, etc.) and shows the logo.
    *   One-tap copy for card numbers.
    *   Hidden CVV with toggle visibility.
    *   Visual "Expired" stamps for outdated cards.
*   **Customization**: Auto-generated gradient backgrounds for better visual distinction.

## 🚀 Getting Started

1.  **Prerequisites**:
    *   Flutter SDK (3.0+)
    *   Android Studio / Xcode

2.  **Installation**:
    ```bash
    # Clone the repository
    git clone https://github.com/bagy391/card_vault.git

    # Navigate to directory
    cd card_vault

    # Install dependencies
    flutter pub get

    # Run the app
    flutter run
    ```

## 🛠 Tech Stack

*   **Framework**: Flutter
*   **State Management**: Provider
*   **Storage**: Shared Preferences (Encrypted Content)
*   **Security**: Flutter Secure Storage (Key Management), Local Auth (Biometrics)
*   **Icons**: Font Awesome, Google Fonts

---

**Disclaimer**: This app is a secure storage tool. It is not affiliated with any bank or financial institution. Ensure you keep your device security (PIN/Biometrics) strong, as it is the gateway to this app.
