# Echo Payam — پنل ادمین (Flutter)

```bash
flutter create --org com.echopayam --project-name echo_payam_admin --platforms=android,ios,web,windows .
# فایل‌های pubspec.yaml / lib / assets این پوشه را جایگزین کنید
flutter pub get
flutter run -d chrome     # یا windows / android
```
- حداقل نسخه: Flutter 3.27 (Dart 3.6)
- طرح ریسپانسیو: دسکتاپ با سایدبار ثابت، موبایل با Drawer.
- داده‌ها نمونه (mock) هستند؛ برای اتصال به بک‌اند، متدهای `AdminState` در `lib/state.dart` را به API وصل کنید.
