import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/app_database.dart';
import '../reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _load;
  Map<String, int> _summary = {'expenses': 0, 'income': 0, 'balance': 0};
  List<Map<String, Object?>> _recent = [];
  int _budget = 0;
  final NumberFormat _moneyFormat = NumberFormat('#,##0', 'en');

  @override
  void initState() {
    super.initState();
    _load = _refresh();
  }

  String _money(int value) =>
      '${_moneyFormat.format(value)} ${AppConstants.currencySymbol}';

  Future<void> _refresh() async {
    final database = AppDatabase.instance;
    _summary = await database.monthSummary(DateTime.now());
    _recent = await database.recent(limit: 10);
    _budget = await database.getBudget(DateTime.now());
  }

  void _reload() {
    setState(() {
      _load = _refresh();
    });
  }

  Future<void> _openRecord(String kind) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _RecordDialog(kind: kind),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _openInvoice() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _InvoiceDialog(),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _editBudget() async {
    final controller = TextEditingController(
      text: _budget == 0 ? '' : _budget.toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الميزانية الشهرية'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ بالريال اليمني',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, int.tryParse(controller.text)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (value != null && value >= 0) {
      await AppDatabase.instance.setBudget(DateTime.now(), value);
      if (mounted) _reload();
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العملية؟'),
        content: const Text('سيتم حذف هذه العملية من الحسابات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppDatabase.instance.deleteRecord(id);
      if (mounted) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('تعذر فتح قاعدة البيانات: ${snapshot.error}'),
            );
          }

          final spent = _summary['expenses'] ?? 0;
          final income = _summary['income'] ?? 0;
          final balance = _summary['balance'] ?? 0;
          final progress = _budget <= 0
              ? 0.0
              : (spent / _budget).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: () async {
              await _refresh();
              if (mounted) setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'ar').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.forest, AppTheme.forestLight],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المتبقي من دخل الشهر',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _money(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric('الدخل', _money(income)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _Metric('المصروف', _money(spent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'الميزانية الشهرية',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            TextButton(
                              onPressed: _editBudget,
                              child: Text(_budget == 0 ? 'تحديد' : 'تعديل'),
                            ),
                          ],
                        ),
                        Text(
                          _budget == 0
                              ? 'لم تحدد ميزانية هذا الشهر'
                              : 'المصروف ${_money(spent)} من ${_money(_budget)}',
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                        ),
                        if (_budget > 0)
                          Text('المتبقي: ${_money(_budget - spent)}'),
                        if (_budget > 0 && spent >= _budget * 0.8)
                          const Text(
                            'تنبيه: استهلكت 80٪ أو أكثر من الميزانية',
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.6,
                  children: [
                    _ActionTile(
                      'إضافة مصروف',
                      Icons.add_circle,
                      () => _openRecord('expense'),
                    ),
                    _ActionTile(
                      'إضافة دخل',
                      Icons.add_card,
                      () => _openRecord('income'),
                    ),
                    _ActionTile(
                      'فاتورة مشتريات',
                      Icons.receipt_long,
                      _openInvoice,
                    ),
                    _ActionTile(
                      'الميزانية',
                      Icons.savings,
                      _editBudget,
                    ),
                    _ActionTile(
                      'التقارير المالية',
                      Icons.analytics_outlined,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'آخر العمليات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_recent.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'لا توجد عمليات مسجلة بعد',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ..._recent.map((record) {
                  final isIncome = record['kind'] == 'income';
                  final amount = (record['amount'] as num).toInt();
                  final date = DateTime.parse(record['occurred_at'] as String);
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isIncome ? Icons.south_west : Icons.north_east,
                        color: isIncome ? Colors.green : Colors.deepOrange,
                      ),
                      title: Text(record['title'] as String),
                      subtitle: Text(
                        '${record['category']} • ${DateFormat('yyyy/MM/dd').format(date)}',
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${_money(amount)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onLongPress: () =>
                          _deleteRecord((record['id'] as num).toInt()),
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'اضغط مطولاً على العملية لحذفها.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.forest),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.kind});
  final String kind;

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();
  String _category = '';
  String _payment = 'cash';
  bool _saving = false;

  List<String> get _categories => widget.kind == 'income'
      ? ['راتب', 'دخل إضافي', 'أخرى']
      : AppConstants.defaultCategories;

  @override
  void initState() {
    super.initState();
    _category = _categories.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.addRecord(
        kind: widget.kind,
        title: _title.text,
        amount: int.parse(_amount.text),
        category: _category,
        payment: _payment,
        date: DateTime.now(),
        merchant: _merchant.text,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.kind == 'income' ? 'إضافة دخل' : 'إضافة مصروف'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'البيان *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'أدخل البيان'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ بالريال اليمني *',
                  ),
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    return number == null || number <= 0
                        ? 'أدخل مبلغاً صحيحاً أكبر من صفر'
                        : null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: _categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                    DropdownMenuItem(value: 'transfer', child: Text('تحويل')),
                    DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                  ],
                  onChanged: (value) =>
                      setState(() => _payment = value ?? _payment),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _merchant,
                  decoration: const InputDecoration(
                    labelText: 'المتجر / المستفيد (اختياري)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}

class _InvoiceDialog extends StatefulWidget {
  const _InvoiceDialog();

  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  final _merchant = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _note = TextEditingController();
  final List<_InvoiceLineControllers> _lines = [
    _InvoiceLineControllers(),
  ];
  bool _saving = false;

  int get _subtotal => _lines.fold(
        0,
        (sum, line) =>
            sum +
            (int.tryParse(line.quantity.text) ?? 0) *
                (int.tryParse(line.price.text) ?? 0),
      );

  @override
  void dispose() {
    _merchant.dispose();
    _discount.dispose();
    _note.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final items = <InvoiceLineInput>[];
    for (final line in _lines) {
      final quantity = int.tryParse(line.quantity.text);
      final price = int.tryParse(line.price.text);
      if (line.name.text.trim().isEmpty ||
          quantity == null ||
          quantity <= 0 ||
          price == null ||
          price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أكمل اسم الصنف والكمية والسعر بشكل صحيح'),
          ),
        );
        return;
      }
      items.add(
        InvoiceLineInput(
          name: line.name.text,
          quantity: quantity,
          unitPrice: price,
          unit: line.unit.text.trim().isEmpty ? 'حبة' : line.unit.text.trim(),
        ),
      );
    }

    setState(() => _saving = true);
    try {
      await AppDatabase.instance.addInvoice(
        items: items,
        discount: int.tryParse(_discount.text) ?? -1,
        date: DateTime.now(),
        merchant: _merchant.text,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ الفاتورة: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فاتورة مشتريات متعددة الأصناف'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _merchant,
                decoration: const InputDecoration(labelText: 'اسم المتجر'),
              ),
              ...List.generate(_lines.length, (index) {
                final line = _lines[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextField(
                          controller: line.name,
                          decoration: InputDecoration(
                            labelText: 'الصنف رقم ${index + 1}',
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: line.quantity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'الكمية',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: line.unit,
                                decoration: const InputDecoration(
                                  labelText: 'الوحدة',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: line.price,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'سعر الوحدة',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_lines.length > 1)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                final removed = _lines.removeAt(index);
                                removed.dispose();
                              });
                            },
                            child: const Text('حذف الصنف'),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () {
                  setState(() => _lines.add(_InvoiceLineControllers()));
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة صنف'),
              ),
              TextField(
                controller: _discount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الخصم'),
              ),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('الإجمالي قبل الخصم: $_subtotal ر.ي'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الإجمالي النهائي: ${_subtotal - (int.tryParse(_discount.text) ?? 0)} ر.ي',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الفاتورة'),
        ),
      ],
    );
  }
}

class _InvoiceLineControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unit = TextEditingController(text: 'حبة');
  final TextEditingController price = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    price.dispose();
  }
}
