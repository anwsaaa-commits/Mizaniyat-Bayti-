import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TunaApp());
}

class TunaApp extends StatelessWidget {
  const TunaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'حسابات بيع وشراء السمك',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087f8c)), useMaterial3: true),
    home: const TunaHome(),
  );
}

class SaleInvoice {
  final String buyer, date, note;
  final double kg, price, paid;
  const SaleInvoice({required this.buyer, required this.date, required this.note, required this.kg, required this.price, required this.paid});
  double get total => kg * price;
  double get balance => total - paid;
  Map<String, dynamic> toJson() => {'buyer': buyer, 'date': date, 'note': note, 'kg': kg, 'price': price, 'paid': paid};
  factory SaleInvoice.fromJson(Map<String, dynamic> json) => SaleInvoice(
    buyer: json['buyer'] as String, date: json['date'] as String, note: (json['note'] ?? '') as String,
    kg: (json['kg'] as num).toDouble(), price: (json['price'] as num).toDouble(), paid: (json['paid'] as num).toDouble(),
  );
}

class TunaHome extends StatefulWidget {
  const TunaHome({super.key});
  @override
  State<TunaHome> createState() => _TunaHomeState();
}

class _TunaHomeState extends State<TunaHome> {
  List<SaleInvoice> invoices = [];
  List<String> buyers = [];
  bool loading = true;
  String get today => DateTime.now().toIso8601String().substring(0, 10);
  double get todaySales => invoices.where((i) => i.date.startsWith(today)).fold(0.0, (sum, i) => sum + i.total);
  double get todayKg => invoices.where((i) => i.date.startsWith(today)).fold(0.0, (sum, i) => sum + i.kg);
  double get totalDebt => invoices.fold(0.0, (sum, i) => sum + i.balance);

  @override
  void initState() { super.initState(); _loadData(); }
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    invoices = (prefs.getStringList('tuna_invoices') ?? []).map((s) => SaleInvoice.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    buyers = prefs.getStringList('tuna_buyer_names') ?? [];
    if (mounted) setState(() => loading = false);
  }
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tuna_invoices', invoices.map((i) => jsonEncode(i.toJson())).toList());
    await prefs.setStringList('tuna_buyer_names', buyers);
  }

  Future<void> _addInvoice() async {
    final buyerCtrl = TextEditingController();
    final kgCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '6500');
    final paidCtrl = TextEditingController(text: '0');
    final noteCtrl = TextEditingController();
    String type = 'آجل';
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('فاتورة بيع تونة'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: buyerCtrl, decoration: const InputDecoration(labelText: 'اسم المشتري')),
        TextField(controller: kgCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الوزن (كيلو)')),
        TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الكيلو (ريال)')),
        TextField(controller: paidCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المدفوع')),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'نوع البيع'),
          items: ['نقد', 'آجل'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => type = v ?? type),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظات')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ الفاتورة')),
      ],
    ));
    if (confirmed != true) return;
    final kg = double.tryParse(kgCtrl.text);
    final price = double.tryParse(priceCtrl.text);
    final paid = double.tryParse(paidCtrl.text.isEmpty ? '0' : paidCtrl.text);
    if (buyerCtrl.text.trim().isEmpty || kg == null || kg <= 0 || price == null || price <= 0 || paid == null || paid < 0 || paid > kg * price || (type == 'نقد' && paid != kg * price)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('راجع البيانات، ويجب دفع الفاتورة النقدية كاملة')));
      return;
    }
    final item = SaleInvoice(buyer: buyerCtrl.text.trim(), date: DateTime.now().toIso8601String(), note: noteCtrl.text.trim(), kg: kg, price: price, paid: paid);
    invoices.insert(0, item);
    if (!buyers.contains(item.buyer)) buyers.add(item.buyer);
    await _saveData();
    if (mounted) setState(() {});
  }

  Future<void> _addBuyer() async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إضافة مشتري'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'اسم المشتري')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
    ));
    final name = ctrl.text.trim();
    if (result == true && name.isNotEmpty && !buyers.contains(name)) { buyers.add(name); await _saveData(); if (mounted) setState(() {}); }
  }

  Future<void> _receive(SaleInvoice item) async {
    if (item.balance <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذه الفاتورة مدفوعة بالكامل'))); return; }
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('تحصيل دفعة - ${item.buyer}'), content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد'))],
    ));
    if (result != true) return;
    final amount = double.tryParse(ctrl.text);
    if (amount == null || amount <= 0 || amount > item.balance) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ غير صحيح'))); return; }
    final idx = invoices.indexOf(item);
    invoices[idx] = SaleInvoice(buyer: item.buyer, date: item.date, note: item.note, kg: item.kg, price: item.price, paid: item.paid + amount);
    await _saveData(); if (mounted) setState(() {});
  }

  Widget _stat(String title, String value, String unit, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon), Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), Text(unit)])));
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('حسابات بيع وشراء السمك'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addInvoice, icon: const Icon(Icons.add), label: const Text('فاتورة بيع')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.5, children: [
          _stat('مبيعات اليوم', todaySales.toStringAsFixed(0), 'ريال', Icons.point_of_sale),
          _stat('كمية اليوم', todayKg.toStringAsFixed(2), 'كيلو', Icons.scale),
          _stat('إجمالي الديون', totalDebt.toStringAsFixed(0), 'ريال', Icons.account_balance_wallet),
          _stat('عدد المشترين', buyers.length.toString(), 'مشتري', Icons.people),
        ]),
        Row(children: [const Expanded(child: Text('الفواتير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: _addBuyer, icon: const Icon(Icons.person_add), tooltip: 'إضافة مشتري')]),
        if (invoices.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('لا توجد فواتير بعد', textAlign: TextAlign.center)),
        ...invoices.map((i) => Card(child: ListTile(title: Text(i.buyer), subtitle: Text('${i.kg} كيلو × ${i.price.toStringAsFixed(0)} ريال\n${i.date.substring(0, 10)}'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(i.total.toStringAsFixed(0)), Text('باقي ${i.balance.toStringAsFixed(0)}')]), onTap: () => _receive(i)))),
        const Padding(padding: EdgeInsets.only(top: 12), child: Text('المشترون', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ...buyers.map((b) => Card(child: ListTile(leading: const Icon(Icons.person), title: Text(b), subtitle: Text('رصيد: ${invoices.where((i) => i.buyer == b).fold(0.0, (sum, i) => sum + i.balance).toStringAsFixed(0)} ريال')))),
      ]),
    ));
  }
}
