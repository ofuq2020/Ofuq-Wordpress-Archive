# حالة مشروع مثبت Acelle Mail

الحالة: غير مكتمل؛ لا يوجد ملف EXE مبني ومختبر بنجاح حتى الآن.

## الملفات الموجودة في المستودع
- `AcelleMail-Setup.iss` — تعريف Inno Setup.
- `scripts/Prepare-WindowsRuntime.ps1` — سكربت تجهيز بيئة التشغيل.
- `scripts/Build-WindowsInstaller.ps1` — سكربت التحقق من المتطلبات وبناء المثبت.
- `src/AcelleMailLauncher.ps1` — مشغّل التطبيق المحلي.
- `src/Stop-AcelleMail.ps1` — سكربت إيقاف عمليات هذا التثبيت.
- `.github/workflows/build-windows-installer.yml` — سير عمل البناء على Windows.

## العائق الحالي
حزمة التطبيق الأصلية `AcelleMail_3.0.21_ReviewBuild_v4_EasyInstaller.zip` (34,926,985 بايت) لم تُرفع إلى المستودع بعد. أداة الكتابة المتاحة هنا تنشئ ملفات نصية UTF-8 ولا تتيح نقل ملف ZIP ثنائي بهذا الحجم. لذلك لن ينجح البناء حتى تُضاف الحزمة إلى `payload/`.

## الخطوات المتبقية
1. رفع حزمة التطبيق إلى `payload/AcelleMail_3.0.21_ReviewBuild_v4_EasyInstaller.zip`.
2. التحقق من checksum الرسمي لـ PHP وتوافق إصدارات PHP وMariaDB مع Acelle قبل الاعتماد عليها.
3. تشغيل البناء على Windows x64 مع Inno Setup 6.
4. إصلاح أي أخطاء بناء تظهر، ثم اختبار تثبيت نظيف على Windows 10/11.
5. اختبار التشغيل والإيقاف وحفظ البيانات والسجلات وإلغاء التثبيت.

لا تعتبر المشروع جاهزًا للتوزيع قبل اجتياز الاختبارات الفعلية.