# Echo Payam — اپ کاربران (Flutter)

## راه‌اندازی
```bash
flutter create --org com.echopayam --project-name echo_payam --platforms=android,ios .
# سپس فایل‌های این پوشه (pubspec.yaml, lib/, assets/) جایگزین فایل‌های ساخته‌شده می‌شوند
flutter pub get
flutter run
```
- حداقل نسخه: Flutter 3.27 (Dart 3.6)
- فونت وزیر داخل `assets/fonts` است؛ نیازی به اینترنت نیست.
- ساخت APK: `flutter build apk --release --split-per-abi`
