import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/app_database.dart';

class HomeScreen extends StatefulWidget {const HomeScreen({super.key});@override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
  late Future<void> _load;Map<String,int> _summary={'expenses':0,'income':0,'balance':0};List<Map<String,Object?>> _recent=[];int _budget=0;
  final _fmt=NumberFormat('#,##0','en');
  @override void initState(){super.initState();_load=refresh();}
  String money(int n)=>'${_fmt.format(n)} ${AppConstants.currencySymbol}';
  Future<void> refresh()async{final d=AppDatabase.instance;_summary=await d.monthSummary(DateTime.now());_recent=await d.recent(limit:10);_budget=await d.getBudget(DateTime.now());}
  void reload(){setState(()=>_load=refresh());}
  Future<void> add(String kind)async{final ok=await showDialog<bool>(context:context,builder:(_)=>_RecordDialog(kind:kind));if(ok==true)reload();}
  Future<void> budget()async{final c=TextEditingController(text:_budget==0?'':_budget.toString());final v=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(title:const Text('الميزانية الشهرية'),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ بالريال اليمني')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,int.tryParse(c.text)),child:const Text('حفظ'))]));c.dispose();if(v!=null&&v>=0){await AppDatabase.instance.setBudget(DateTime.now(),v);reload();}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text(AppConstants.appName),actions:[IconButton(onPressed:reload,icon:const Icon(Icons.refresh))]),body:FutureBuilder<void>(future:_load,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('خطأ في قاعدة البيانات: ${s.error}'));final spent=_summary['expenses']??0;final income=_summary['income']??0;final balance=_summary['balance']??0;final progress=_budget==0?0.0:(spent/_budget).clamp(0.0,1.0);return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text(DateFormat('MMMM yyyy','ar').format(DateTime.now()),style:Theme.of(context).textTheme.titleMedium),
    const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppTheme.forest,AppTheme.forestLight]),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('المتبقي من دخل الشهر',style:TextStyle(color:Colors.white70)),const SizedBox(height:8),Text(money(balance),style:const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:18),Row(children:[Expanded(child:_Metric('الدخل',money(income))),const SizedBox(width:14),Expanded(child:_Metric('المصروف',money(spent)))]) ])),
    const SizedBox(height:12),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Expanded(child:Text('الميزانية الشهرية',style:TextStyle(fontWeight:FontWeight.bold))),TextButton(onPressed:budget,child:Text(_budget==0?'تحديد':'تعديل'))]),Text(_budget==0?'لم تحدد ميزانية هذا الشهر':'المصروف ${money(spent)} من ${money(_budget)}'),const SizedBox(height:10),LinearProgressIndicator(value:progress,minHeight:9),if(_budget>0)Text('المتبقي: ${money(_budget-spent)}'),if(_budget>0&&spent>=_budget*.8)const Text('تنبيه: استهلكت 80٪ أو أكثر من الميزانية',style:TextStyle(color:Colors.deepOrange))]))),
    const SizedBox(height:12),
    GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:2.6,children:[_Action('إضافة مصروف',Icons.add_circle,()=>add('expense')),_Action('إضافة دخل',Icons.add_card,()=>add('income')),_Action('فاتورة مشتريات',Icons.receipt_long,()=>showDialog<bool>(context:context,builder:(_)=>const _InvoiceDialog()).then((v){if(v==true)reload();})),_Action('الميزانية',Icons.savings,budget)]),
    const SizedBox(height:16),const Text('آخر العمليات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    if(_recent.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد عمليات مسجلة بعد',textAlign:TextAlign.center))),
    ..._recent.map((r){final inc=r['kind']=='income';final n=(r['amount'] as num).toInt();return Card(child:ListTile(leading:Icon(inc?Icons.south_west:Icons.north_east,color:inc?Colors.green:Colors.deepOrange),title:Text(r['title'] as String),subtitle:Text('${r['category']} • ${DateFormat('yyyy/MM/dd').format(DateTime.parse(r['occurred_at'] as String))}'),trailing:Text('${inc?'+':'-'}${money(n)}',style:TextStyle(color:inc?Colors.green:Colors.deepOrange,fontWeight:FontWeight.bold)),onLongPress:()async{final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('حذف العملية؟'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حذف'))]));if(yes==true){await AppDatabase.instance.deleteRecord((r['id'] as num).toInt());reload();}}));}),
    const Text('اضغط مطولاً على العملية لحذفها.',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey,fontSize:12))
  ]));}));
}
class _Metric extends StatelessWidget{const _Metric(this.label,this.value);final String label,value;@override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.white70)),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))]);}
class _Action extends StatelessWidget{const _Action(this.label,this.icon,this.tap);final String label;final IconData icon;final VoidCallback tap;@override Widget build(BuildContext c)=>Card(child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(16),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:AppTheme.forest),const SizedBox(width:7),Flexible(child:Text(label,style:const TextStyle(fontWeight:FontWeight.bold)))])));}
class _RecordDialog extends StatefulWidget{const _RecordDialog({required this.kind});final String kind;@override State<_RecordDialog> createState()=>_RecordDialogState();}
class _RecordDialogState extends State<_RecordDialog>{
 final _form=GlobalKey<FormState>();final _title=TextEditingController(),_amount=TextEditingController(),_merchant=TextEditingController(),_note=TextEditingController();String _category='',_payment='cash';bool _saving=false;
 List<String> get categories=>widget.kind=='income'?['راتب','دخل إضافي','أخرى']:AppConstants.defaultCategories;
 @override void initState(){super.initState();_category=categories.first;}
 @override void dispose(){_title.dispose();_amount.dispose();_merchant.dispose();_note.dispose();super.dispose();}
 Future<void> save()async{if(!_form.currentState!.validate())return;setState(()=>_saving=true);try{await AppDatabase.instance.addRecord(kind:widget.kind,title:_title.text,amount:int.parse(_amount.text),category:_category,payment:_payment,date:DateTime.now(),merchant:_merchant.text,note:_note.text);if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الحفظ: $e')));setState(()=>_saving=false);}}
 @override Widget build(BuildContext c)=>AlertDialog(title:Text(widget.kind=='income'?'إضافة دخل':'إضافة مصروف'),content:Form(key:_form,child:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
 TextFormField(controller:_title,decoration:const InputDecoration(labelText:'البيان *'),validator:(v)=>v==null||v.trim().isEmpty?'أدخل البيان':null),
 const SizedBox(height:10),TextFormField(controller:_amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ بالريال اليمني *'),validator:(v){final n=int.tryParse(v??'');return n==null||n<=0?'أدخل مبلغاً صحيحاً':null;}),
 const SizedBox(height:10),DropdownButtonFormField<String>(value:_category,decoration:const InputDecoration(labelText:'التصنيف'),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>_category=v!)),
 const SizedBox(height:10),DropdownButtonFormField<String>(value:_payment,decoration:const InputDecoration(labelText:'طريقة الدفع'),items:const[DropdownMenuItem(value:'cash',child:Text('نقداً')),DropdownMenuItem(value:'transfer',child:Text('تحويل')),DropdownMenuItem(value:'card',child:Text('بطاقة'))],onChanged:(v)=>setState(()=>_payment=v!)),
 const SizedBox(height:10),TextField(controller:_merchant,decoration:const InputDecoration(labelText:'المتجر / المستفيد')),const SizedBox(height:10),TextField(controller:_note,decoration:const InputDecoration(labelText:'ملاحظات'))
 ])))),actions:[TextButton(onPressed:_saving?null:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:_saving?null:save,child:Text(_saving?'جارٍ الحفظ':'حفظ'))]);}
}
class _InvoiceDialog extends StatefulWidget{const _InvoiceDialog();@override State<_InvoiceDialog> createState()=>_InvoiceDialogState();}
class _InvoiceDialogState extends State<_InvoiceDialog>{
 final _merchant=TextEditingController(),_discount=TextEditingController(text:'0'),_note=TextEditingController();final List<_Line> _lines=[_Line()];bool _saving=false;
 int get subtotal=>_lines.fold(0,(s,x)=>s+(int.tryParse(x.qty.text)??0)*(int.tryParse(x.price.text)??0));
 @override void dispose(){_merchant.dispose();_discount.dispose();_note.dispose();for(final x in _lines){x.dispose();}super.dispose();}
 Future<void> save()async{final items=<InvoiceLineInput>[];for(final x in _lines){final q=int.tryParse(x.qty.text),p=int.tryParse(x.price.text);if(x.name.text.trim().isEmpty||q==null||q<=0||p==null||p<0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أكمل اسم الصنف والكمية والسعر')));return;}items.add(InvoiceLineInput(name:x.name.text,quantity:q,unitPrice:p,unit:x.unit.text));}setState(()=>_saving=true);try{await AppDatabase.instance.addInvoice(items:items,discount:int.tryParse(_discount.text)??-1,date:DateTime.now(),merchant:_merchant.text,note:_note.text);if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الفاتورة: $e')));setState(()=>_saving=false);}}
 @override Widget build(BuildContext c)=>AlertDialog(title:const Text('فاتورة مشتريات متعددة الأصناف'),content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
 TextField(controller:_merchant,decoration:const InputDecoration(labelText:'اسم المتجر')),
 ...List.generate(_lines.length,(index){final x=_lines[index];return Card(child:Padding(padding:const EdgeInsets.all(8),child:Column(children:[
 TextField(controller:x.name,decoration:InputDecoration(labelText:'الصنف رقم ${index+1}')),
 Row(children:[Expanded(child:TextField(controller:x.qty,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الكمية'))),const SizedBox(width:6),Expanded(child:TextField(controller:x.unit,decoration:const InputDecoration(labelText:'الوحدة'))),const SizedBox(width:6),Expanded(child:TextField(controller:x.price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'سعر الوحدة')))]),
 if(_lines.length>1)TextButton(onPressed:()=>setState(()=>_lines.removeAt(index).dispose()),child:const Text('حذف الصنف'))
 ])));}),
 TextButton.icon(onPressed:()=>setState(()=>_lines.add(_Line())),icon:const Icon(Icons.add),label:const Text('إضافة صنف')),
 TextField(controller:_discount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الخصم')),
 TextField(controller:_note,decoration:const InputDecoration(labelText:'ملاحظات')),
 const SizedBox(height:8),Align(alignment:Alignment.centerRight,child:Text('الإجمالي قبل الخصم: $subtotal ر.ي')),Align(alignment:Alignment.centerRight,child:Text('الإجمالي النهائي: ${subtotal-(int.tryParse(_discount.text)??0)} ر.ي',style:const TextStyle(fontWeight:FontWeight.bold)))
 ]))),actions:[TextButton(onPressed:_saving?null:()=>Navigator.pop(c),child:const Text('إلغاء')),FilledButton(onPressed:_saving?null:save,child:Text(_saving?'جارٍ الحفظ':'حفظ الفاتورة'))]);}
}
class _Line{final name=TextEditingController(),qty=TextEditingController(text:'1'),unit=TextEditingController(text:'حبة'),price=TextEditingController();void dispose(){name.dispose();qty.dispose();unit.dispose();price.dispose();}}
