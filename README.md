> Build fix: GitHub Actions now cleans the Theos SDK directory before cloning the official SDK repository, preventing the `destination path .../theos/sdks already exists` failure.

# Telegram Multi Manager

لوحة تحكم لتفعيل/تعطيل ثلاثة dylibs داخل Telegram:

- `Mx.dylib`
- `iQTele.dylib`
- `Lead.dylib`

## طريقة فتح اللوحة
المس شاشة Telegram بثلاث أصابع معاً لمدة قصيرة جداً (~0.05 ثانية).

## طريقة العمل
GitHub Actions يبني `TelegramMultiManager.dylib` ويحوّل startup initializer sections في الديلبات الثلاثة إلى managed sections. لذلك Feather يستطيع حقن الملفات الأربعة، لكن Mx/iQTele/Lead لا يشغلون initializers تلقائياً. الـManager يشغل initializers فقط للأدوات المفعّلة في الإعدادات.

كل التغييرات تطبق بعد إغلاق Telegram بالكامل وفتحه من جديد. لا يتم استخدام `dlclose` أو محاولة إزالة hooks من العملية الحالية.

## تعارض Mx + Lead
Mx وLead يعرّفان كلاهما Objective-C classes باسم `LanguageSelector` و`LocationSelector`. الـworkflow يعيد تسمية نسخ Lead إلى أسماء مساوية بالطول قبل إخراج artifact لتجنب duplicate Objective-C class registration عند حقن الاثنين معاً.

## Build
1. ارفع محتويات هذا المجلد إلى GitHub branch `main`.
2. افتح **Actions**.
3. اختر **Build Telegram Multi Manager**.
4. اختر **Run workflow**.
5. نزّل Artifact باسم **TelegramMultiManager-Feather**.

داخل Artifact تحصل على:

```
TelegramMultiManager.dylib
Mx.dylib
iQTele.dylib
Lead.dylib
FEATHER.md
SHA256SUMS.txt
```

استخدم فقط نسخ Mx/iQTele/Lead الخارجة من الـAction، وليس الملفات الأصلية.

## Minimum target
الـManager مبني لـ iOS 15+ arm64.
