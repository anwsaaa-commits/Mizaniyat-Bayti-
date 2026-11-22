import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async { WidgetsFlutterBinding.ensureInitialized(); runApp(const TunaApp()); }
class TunaApp extends StatelessWidget { const TunaApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(title:'حسابات بيع وشراء السمك',debugShowCheckedModeBanner:false,theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff087f8c)),useMaterial3:true),home:const HomePage()); }

class SaleInvoice {
 final String id,buyer,note,date; final double kg,price,paid;
 SaleInvoice({required this.id,required this.buyer,required this.note,required this.date,required this.kg,required this.price,required this.paid});
 double get total=>kg*price; double get balance=>total-paid;
 Map<String,dynamic> toJson()=>{'id':id,'buyer':buyer,'note':note,'date':date,'kg':kg,'price':price,'paid':paid};
 factory SaleInvoice.fromJson(Map<String,dynamic> j)=>SaleInvoice(id:j['id'],buyer:j['buyer'],note:j['note']??'',date:j['date'],kg:(j['kg'] as num).toDouble(),price:(j['price'] as num).toDouble(),paid:(j['paid'] as num).toDouble());
}
class Buyer { final String name,phone,note; Buyer(this.name,this.phone,this.note); Map<String,dynamic> toJson()=>{'name':name,'phone':phone,'note':note}; factory Buyer.fromJson(Map<String,dynamic> j)=>Buyer(j['name'],j['phone']??'',j['note']??''); }

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
 List<SaleInvoice> invoices=[]; List<Buyer> buyers=[]; bool ready=false;
 @override void initState(){super.initState();_load();}
 Future<void> _load() async { final p=await SharedPreferences.getInstance(); invoices=(p.getStringList('sales')??[]).map((s)=>SaleInvoice.fromJson(jsonDecode(s))).toList(); buyers=(p.getStringList('buyers')??[]).map((s)=>Buyer.fromJson(jsonDecode(s))).toList(); if(mounted)setState(()=>ready=true); }
 Future<void> _save() async {final p=await SharedPreferences.getInstance();await p.setStringList('sales',invoices.map((i)=>jsonEncode(i.toJson())).toList());await p.setStringList('buyers',buyers.map((b)=>jsonEncode(b.toJson())).toList());}
 String get today=>DateTime.now().toIso8601String().substring(0,10);
 double get dailySales=>invoices.where((i)=>i.date.startsWith(today)).fold(0,(s,i)=>s+i.total);
 double get dailyKg=>invoices.where((i)=>i.date.startsWith(today)).fold(0,(s,i)=>s+i.kg);
 double get debt=>invoices.fold(0,(s,i)=>s+i.balance);
 Future<void> _newInvoice() async {
 final name=TextEditingController(),weight=TextEditingController(),unit=TextEditingController(text:'6500'),paid=TextEditingController(text:'0'),note=TextEditingController(); String payment='آجل';
 final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('فاتورة بيع تونة'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
 TextField(controller:name,decoration:const InputDecoration(labelText:'اسم المشتري *')),
 TextField(controller:weight,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'الوزن بالكيلو *')),
 TextField(controller:unit,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'سعر الكيلو (ريال) *')),
 TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المدفوع عند البيع')),
 DropdownButtonFormField<String>(value:payment,decoration:const InputDecoration(labelText:'نوع البيع'),items:['نقد','آجل'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>payment=v??payment),
 TextField(controller:note,decoration:const InputDecoration(labelText:'ملاحظات'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ الفاتورة'))]));
 if(ok!=true)return; final kg=double.tryParse(weight.text),pr=double.tryParse(unit.text),pd=double.tryParse(paid.text.isEmpty?'0':paid.text)??0;
 if(name.text.trim().isEmpty||kg==null||kg<=0||pr==null||pr<=0||pd<0||pd>kg*pr||(payment=='نقد'&&pd!=kg*pr)){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('راجع البيانات: النقد يجب أن يكون مدفوعًا بالكامل')));return;}
 final inv=SaleInvoice(id:DateTime.now().millisecondsSinceEpoch.toString(),buyer:name.text.trim(),note:note.text.trim(),date:DateTime.now().toIso8601String(),kg:kg,price:pr,paid:pd);
 invoices.insert(0,inv); if(!buyers.any((b)=>b.name==inv.buyer))buyers.add(Buyer(inv.buyer,'','')); await _save();if(mounted)setState((){});
 }
 Future<void> _addBuyer() async {final n=TextEditingController(),ph=TextEditingController(),nt=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('مشتري جديد'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:ph,decoration:const InputDecoration(labelText:'رقم الهاتف')),TextField(controller:nt,decoration:const InputDecoration(labelText:'ملاحظات'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))]);if(ok==true&&n.text.trim().isNotEmpty&&!buyers.any((b)=>b.name==n.text.trim())){buyers.add(Buyer(n.text.trim(),ph.text.trim(),nt.text.trim()));await _save();if(mounted)setState((){});}}
 Future<void> _collect(SaleInvoice inv) async {final amount=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text('استلام دفعة: '+inv.buyer),content:TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('تأكيد'))]);if(ok!=true)return;final v=double.tryParse(amount.text);if(v==null||v<=0||v>inv.balance){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('المبلغ أكبر من المتبقي أو غير صالح')));return;}final index=invoices.indexWhere((x)=>x.id==inv.id);invoices[index]=SaleInvoice(id:inv.id,buyer:inv.buyer,note:inv.note,date:inv.date,kg:inv.kg,price:inv.price,paid:inv.paid+v);await _save();if(mounted)setState((){});}
 void _buyerLedger(Buyer b){final rows=invoices.where((i)=>i.buyer==b.name).toList();final total=rows.fold<double>(0,(s,i)=>s+i.total),paid=rows.fold<double>(0,(s,i)=>s+i.paid),remain=total-paid;showDialog(context:context,builder:(c)=>AlertDialog(title:Text('كشف حساب '+b.name),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('الهاتف: '+b.phone),Text('إجمالي الفواتير: ${total.toStringAsFixed(0)} ريال'),Text('المدفوع: ${paid.toStringAsFixed(0)} ريال'),Text('المتبقي: ${remain.toStringAsFixed(0)} ريال'),const Divider(),...rows.map((i)=>ListTile(title:Text('فاتورة ${i.id}'),subtitle:Text('${i.kg} كجم × ${i.price.toStringAsFixed(0)}'),trailing:Text('باقي ${i.balance.toStringAsFixed(0)}')))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))]);}
 Widget stat(String label,String value,String suffix,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:Theme.of(context).colorScheme.primary),Text(label,style:const TextStyle(fontSize:13)),Text(value,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),Text(suffix,style:const TextStyle(fontSize:11))])));
 @override Widget build(BuildContext context){if(!ready)return const Scaffold(body:Center(child:CircularProgressIndicator()));return Scaffold(appBar:AppBar(title:const Text('حسابات بيع وشراء السمك'),centerTitle:true),floatingActionButton:FloatingActionButton.extended(onPressed:_newInvoice,icon:const Icon(Icons.add),label:const Text('فاتورة بيع')),body:ListView(padding:const EdgeInsets.all(12),children:[
 GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.55,children:[stat('مبيعات اليوم',dailySales.toStringAsFixed(0),'ريال',Icons.point_of_sale),stat('كمية اليوم',dailyKg.toStringAsFixed(2),'كيلو',Icons.scale),stat('الديون المتبقية',debt.toStringAsFixed(0),'ريال',Icons.account_balance_wallet),stat('المشترون',buyers.length.toString(),'مشتري',Icons.people)]),
 Row(children:[Expanded(child:Text('الفواتير الأخيرة',style:Theme.of(context).textTheme.titleLarge)),IconButton(onPressed:_addBuyer,icon:const Icon(Icons.person_add_alt_1),tooltip:'إضافة مشتري')]),
 if(invoices.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('ابدأ بإضافة فاتورة بيع',textAlign:TextAlign.center)),
 ...invoices.map((i)=>Card(child:ListTile(title:Text(i.buyer),subtitle:Text('${i.kg} كيلو × ${i.price.toStringAsFixed(0)} ريال\n${i.date.substring(0,10)}'+(i.note.isEmpty?'':' • '+i.note)),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(i.total.toStringAsFixed(0),style:const TextStyle(fontWeight:FontWeight.bold)),Text('باقي ${i.balance.toStringAsFixed(0)}')]),onTap:()=>_collect(i)))),
 const SizedBox(height:10),Text('قائمة المشترين',style:Theme.of(context).textTheme.titleLarge),...buyers.map((b)=>Card(child:ListTile(leading:const Icon(Icons.person_outline),title:Text(b.name),subtitle:Text(b.phone),onTap:()=>_buyerLedger(b)))),
 ]));}
}
