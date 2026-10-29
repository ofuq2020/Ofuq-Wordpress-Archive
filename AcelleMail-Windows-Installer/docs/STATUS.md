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
حزمة التطبيق الأصلية لم تُرفع إلى المستودع بعد. أُضيف الآن سكربت `scripts/Assemble-AcelleMailPayload.ps1` لتجميع الأجزاء التي ترفعها إلى `payload/parts/` والتحقق من أن الناتج ZIP صالح. يقوم سير العمل بإنشاء `payload/AcelleMail.zip` تلقائيًا قبل الاستخراج. لا أستطيع الوصول مباشرةً إلى الملفات الموجودة على جهازك المحلي أو نقلها إلى GitHub من هذه الجلسة؛ لذلك ما زال يلزم رفع جميع ملفات `AcelleMail.part*` يدويًا إلى `payload/parts/` مرة واحدة.

## الخطوات المتبقية
1. رفع جميع الأجزاء `AcelleMail.part01`, `AcelleMail.part02`, ... إلى `payload/parts/`؛ سيجمعها سير العمل تلقائيًا في `payload/AcelleMail.zip`.
2. التحقق من checksum الرسمي لـ PHP وتوافق إصدارات PHP وMariaDB مع Acelle قبل الاعتماد عليها.
3. تشغيل البناء على Windows x64 مع Inno Setup 6.
4. إصلاح أي أخطاء بناء تظهر، ثم اختبار تثبيت نظيف على Windows 10/11.
5. اختبار التشغيل والإيقاف وحفظ البيانات والسجلات وإلغاء التثبيت.

لا تعتبر المشروع جاهزًا للتوزيع قبل اجتياز الاختبارات الفعلية.