# Feather installation

داخل Feather اختر Telegram IPA ثم افتح **Tweaks** وأضف الملفات الأربعة التالية من Artifact:

1. `TelegramMultiManager.dylib`
2. `Mx.dylib`
3. `iQTele.dylib`
4. `Lead.dylib`

ثم وقّع التطبيق وثبته.

**مهم:** لا تخلط الملفات الأصلية مع الملفات الخارجة من GitHub Actions. الملفات الناتجة تم تعديل startup initializer metadata فيها حتى تكون تحت تحكم اللوحة.

`iQTele.dylib` مرتبط بـ `@rpath/CydiaSubstrate.framework/CydiaSubstrate`. Feather/ElleKit يجب أن يوفر طبقة التوافق أثناء tweak injection. لا تضف نسخة ثانية عشوائية من CydiaSubstrate إذا Feather أضافها بالفعل.

بعد فتح Telegram:
- 3 أصابع على الشاشة → تفتح اللوحة.
- فعّل/طفّي Mx أو iQTele أو Lead.
- أغلق Telegram بالكامل من App Switcher.
- افتحه مرة ثانية لتطبيق الاختيار.

يمكن تفعيل أكثر من أداة معاً. بما أن Mx وLead يلمسان أجزاء متشابهة من Telegram، التوافق الكامل لكل ميزة مع كل إصدار Telegram لا يمكن ضمانه؛ إذا ظهرت مشكلة اختبر كل واحدة منفردة لتحديد التعارض.
