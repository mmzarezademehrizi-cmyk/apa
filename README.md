# پیام (Echo Payam)

پیام‌رسان فارسی — اپ کاربران + پنل ادمین. هر دو وب‌اپ قابل نصب (PWA) هستند و روی Cloudflare Pages اجرا می‌شوند. سورس Flutter هم برای ساخت اپ اندروید/iOS داخل `flutter/` است.

```
user/            ← اپ کاربران (PWA)      → https://PREFIX.pages.dev
admin/           ← پنل ادمین (PWA)       → https://PREFIX-admin.pages.dev
flutter/user_app, flutter/admin_app      ← پروژه‌های Flutter
deploy-cloudflare.bat                    ← دیپلوی خودکار (ویندوز)
```

## ۱) آپلود روی GitHub
مخزن جدید بسازید (مثلاً `echo-payam`) و یکی از این دو راه:
- **وب:** Add file ▸ Upload files ▸ محتوای پوشهٔ استخراج‌شده را بکشید و رها کنید ▸ Commit.
- **ترمینال:**
  ```bash
  git init && git add . && git commit -m "init"
  git branch -M main
  git remote add origin https://github.com/USER/echo-payam.git
  git push -u origin main
  ```

## ۲) توکن Cloudflare
dash.cloudflare.com ▸ My Profile ▸ API Tokens ▸ Create Token ▸ **Create Custom Token**
- Permissions: `Account` ▸ `Cloudflare Pages` ▸ `Edit`
- Account Resources: Include ▸ حساب خودتان
- (اختیاری) Account ID: Workers & Pages ▸ ستون سمت راست

## ۳) اجرا
فایل `deploy-cloudflare.bat` را دابل‌کلیک کنید و به ترتیب وارد کنید: توکن ▸ (Account ID اختیاری) ▸ لینک مخزن GitHub ▸ پیشوند نام پروژه.
اسکریپت مخزن را می‌گیرد و دو پروژهٔ Pages می‌سازد و آپلود می‌کند. پیش‌نیاز: Node.js 20+ و Git (اگر نبود، دستور نصبش را نشان می‌دهد).
هر بار تغییر دادید، دوباره همین فایل را اجرا کنید.

### روش جایگزین بدون bat (اتصال مستقیم Git)
Cloudflare ▸ Workers & Pages ▸ Create ▸ Pages ▸ Connect to Git ▸ مخزن را انتخاب کنید ▸ Build command خالی ▸ Output directory: `user` (و یک پروژهٔ دوم با `admin`). از این به بعد هر push خودکار دیپلوی می‌شود.

## ⚠️ امنیت پنل ادمین
پنل ادمین فعلاً لاگین ندارد و داده‌هایش نمونه است. قبل از اتصال به داده‌های واقعی آن را پشت **Cloudflare Access** (Zero Trust ▸ Access ▸ Applications ▸ Self-hosted؛ رایگان تا ۵۰ کاربر) بگذارید.
