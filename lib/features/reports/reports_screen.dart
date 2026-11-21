import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../core/constants/app_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _end = DateTime.now();
  String _mode = 'month';
  bool _loading = true;
  List<Map<String,Object?>> _rows = [];
  Map<String,int> _summary = {'expenses':0,'income':0,'balance':0};
  final _money = NumberFormat('#,##0','en');

  String _amount(int n) => '${_money.format(n)} ${AppConstants.currencySymbol}';
  DateTime get _exclusiveEnd => DateTime(_end.year,_end.month,_end.day+1);

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await AppDatabase.instance.reportSummary(_start,_exclusiveEnd);
    final rows = await AppDatabase.instance.reportRows(_start,_exclusiveEnd);
    if(!mounted)return;
    setState((){_summary=summary;_rows=rows;_loading=false;});
  }

  void _daily() {
    final now=DateTime.now();
    setState((){_mode='day';_start=DateTime(now.year,now.month,now.day);_end=_start;});
    _load();
  }
  void _monthly() {
    final now=DateTime.now();
    setState((){_mode='month';_start=DateTime(now.year,now.month);_end=DateTime(now.year,now.month+1,0);});
    _load();
  }
  Future<void> _pick(bool isStart) async {
    final selected=await showDatePicker(context:context,initialDate:isStart?_start:_end,firstDate:DateTime(2020),lastDate:DateTime(2100),locale:const Locale('ar'));
    if(selected==null)return;
    setState((){_mode='custom';if(isStart)_start=selected;else _end=selected;});
    await _load();
  }

  @override
  void initState(){super.initState();_load();}

  @override
  Widget build(BuildContext context){
    final expenses=_summary['expenses']??0;
    final income=_summary['income']??0;
    return Scaffold(
      appBar:AppBar(title:const Text('التقارير المالية التفصيلية')),
      body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
        onRefresh:_load,
        child:ListView(padding:const EdgeInsets.all(16),children:[
          Wrap(spacing:8,runSpacing:8,children:[
            ChoiceChip(label:const Text('اليوم'),selected:_mode=='day',onSelected:(_)=>_daily()),
            ChoiceChip(label:const Text('هذا الشهر'),selected:_mode=='month',onSelected:(_)=>_monthly()),
            ChoiceChip(label:const Text('فترة مخصصة'),selected:_mode=='custom',onSelected:(_)=>setState(()=>_mode='custom')),
          ]),
          const SizedBox(height:10),
          Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
            Expanded(child:InkWell(onTap:()=>_pick(true),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('من تاريخ'),Text(DateFormat('yyyy/MM/dd').format(_start),style:const TextStyle(fontWeight:FontWeight.bold))]))),
            Expanded(child:InkWell(onTap:()=>_pick(false),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('إلى تاريخ'),Text(DateFormat('yyyy/MM/dd').format(_end),style:const TextStyle(fontWeight:FontWeight.bold))]))),
          ]))),
          const SizedBox(height:8),
          _summaryCard('إجمالي الدخل',income,Colors.green),
          _summaryCard('إجمالي المصروفات',expenses,Colors.deepOrange),
          _summaryCard('صافي الرصيد',income-expenses,(income-expenses)>=0?Colors.teal:Colors.red),
          const SizedBox(height:12),
          Text('تفاصيل العمليات (${_rows.length})',style:Theme.of(context).textTheme.titleLarge),
          if(_rows.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد عمليات خلال الفترة المحددة',textAlign:TextAlign.center))),
          ..._rows.map((r){
            final isIncome=r['kind']=='income';
            final value=(r['amount'] as num).toInt();
            final date=DateTime.parse(r['occurred_at'] as String);
            final merchant=(r['merchant'] as String?)??'';
            return Card(child:ListTile(
              leading:Icon(isIncome?Icons.south_west:Icons.north_east,color:isIncome?Colors.green:Colors.deepOrange),
              title:Text((r['title']??'') as String),
              subtitle:Text('${r['category']??''} • ${DateFormat('yyyy/MM/dd - HH:mm').format(date)}${merchant.isNotEmpty?'\n'+merchant:''}'),
              trailing:Text('${isIncome?'+':'-'}${_amount(value)}',style:TextStyle(color:isIncome?Colors.green:Colors.deepOrange,fontWeight:FontWeight.bold)),
            ));
          }),
          const SizedBox(height:12),
          const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('تصدير وحفظ PDF عربي منسق سيتم إكماله ضمن التحديث، بعد تضمين خط عربي مناسب لضمان ظهور الحروف بشكل صحيح.',textAlign:TextAlign.center))),
        ]),
      ),
    );
  }

  Widget _summaryCard(String label,int value,Color color)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w600))),Text(_amount(value),style:TextStyle(fontWeight:FontWeight.bold,color:color,fontSize:17))])));
}
