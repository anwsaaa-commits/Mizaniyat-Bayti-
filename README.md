# متجر تونة بلس – TUNA PLUS
تطبيق Flutter عربي RTL لإدارة بيع التونة بالكيلو وحساب العملاء والفواتير.

- SQLite محلية للاستخدام دون إنترنت.
- تسجيل البيع بالجرام وحساب سعر الكيلو تلقائياً.
- نقدي أو آجل مع دفعة أولى.
- تسجيل العملاء وحفظ ملاحظاتهم.
- سجل فواتير مع حذف البيع.
- كشوف العملاء وحساب الرصيد والتحصيلات.
- لوحة مؤشرات وتقارير PDF قابلة للطباعة.
- إعداد اسم المتجر ورقم الهاتف والسعر الافتراضي.

## Build
GitHub Actions builds release APK and uploads it as an artifact.
## PDF note
PDF currently uses its default font; Arabic text needs a bundled Arabic font for proper glyph shaping and display.