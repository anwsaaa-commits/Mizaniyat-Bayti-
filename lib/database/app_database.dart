import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';

class InvoiceLineInput {
  const InvoiceLineInput({required this.name,required this.quantity,required this.unitPrice,this.unit='حبة'});
  final String name,unit; final int quantity,unitPrice;
}

class AppDatabase {
  AppDatabase._();
  static final instance=AppDatabase._();
  Database? _db;
  Future<Database> get db async {
    if(_db!=null)return _db!;
    _db=await openDatabase(p.join(await getDatabasesPath(),AppConstants.databaseName),version:1,onCreate:(d,v)async{
      await d.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT UNIQUE NOT NULL,kind TEXT NOT NULL,is_active INTEGER NOT NULL DEFAULT 1)');
      await d.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT NOT NULL CHECK(kind IN ('expense','income')),title TEXT NOT NULL,amount INTEGER NOT NULL CHECK(amount>0),category TEXT NOT NULL,payment_method TEXT NOT NULL,merchant TEXT,note TEXT,occurred_at TEXT NOT NULL,invoice_id INTEGER)");
      await d.execute('CREATE TABLE invoices(id INTEGER PRIMARY KEY AUTOINCREMENT,merchant TEXT,subtotal INTEGER NOT NULL,discount INTEGER NOT NULL,total INTEGER NOT NULL,occurred_at TEXT NOT NULL,note TEXT)');
      await d.execute('CREATE TABLE invoice_items(id INTEGER PRIMARY KEY AUTOINCREMENT,invoice_id INTEGER NOT NULL,name TEXT NOT NULL,quantity INTEGER NOT NULL,unit TEXT NOT NULL,unit_price INTEGER NOT NULL,line_total INTEGER NOT NULL,FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE)');
      await d.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT,month_key TEXT NOT NULL,category TEXT,amount INTEGER NOT NULL,UNIQUE(month_key,category))');
      final b=d.batch();
      for(final c in AppConstants.defaultCategories){b.insert('categories',{'name':c,'kind':'expense'});}
      b.insert('categories',{'name':'راتب','kind':'income'});b.insert('categories',{'name':'دخل إضافي','kind':'income'});
      await b.commit(noResult:true);
    });
    return _db!;
  }

  Future<Map<String,int>> monthSummary(DateTime date) async {
    final d=await db;final start=DateTime(date.year,date.month).toIso8601String();final end=DateTime(date.year,date.month+1).toIso8601String();
    final rows=await d.rawQuery('SELECT kind,SUM(amount) total FROM transactions WHERE occurred_at>=? AND occurred_at<? GROUP BY kind',[start,end]);
    var e=0,i=0;for(final r in rows){if(r['kind']=='expense')e=(r['total'] as num).toInt();if(r['kind']=='income')i=(r['total'] as num).toInt();}
    return {'expenses':e,'income':i,'balance':i-e};
  }
  Future<List<Map<String,Object?>>> recent({int limit=30}) async => (await db).query('transactions',orderBy:'occurred_at DESC,id DESC',limit:limit);
  Future<int> addRecord({required String kind,required String title,required int amount,required String category,required String payment,required DateTime date,String? merchant,String? note}) async {
    if(amount<=0)throw ArgumentError('المبلغ يجب أن يكون أكبر من صفر');
    return (await db).insert('transactions',{'kind':kind,'title':title.trim(),'amount':amount,'category':category,'payment_method':payment,'merchant':merchant,'note':note,'occurred_at':date.toIso8601String()});
  }
  Future<int> addInvoice({required List<InvoiceLineInput> items,required int discount,required DateTime date,String? merchant,String? note}) async {
    if(items.isEmpty||items.any((x)=>x.name.trim().isEmpty||x.quantity<=0||x.unitPrice<0))throw ArgumentError('بيانات الأصناف غير صحيحة');
    final subtotal=items.fold<int>(0,(s,x)=>s+x.quantity*x.unitPrice);
    if(discount<0||discount>subtotal)throw ArgumentError('الخصم غير صحيح');
    final d=await db;
    return d.transaction((t)async{
      final id=await t.insert('invoices',{'merchant':merchant,'subtotal':subtotal,'discount':discount,'total':subtotal-discount,'occurred_at':date.toIso8601String(),'note':note});
      final batch=t.batch();for(final x in items){batch.insert('invoice_items',{'invoice_id':id,'name':x.name,'quantity':x.quantity,'unit':x.unit,'unit_price':x.unitPrice,'line_total':x.quantity*x.unitPrice});}await batch.commit(noResult:true);
      // Exactly one transaction represents the invoice; item rows are excluded from totals.
      await t.insert('transactions',{'kind':'expense','title':'فاتورة مشتريات','amount':subtotal-discount,'category':'مواد غذائية','payment_method':'cash','merchant':merchant,'note':note,'occurred_at':date.toIso8601String(),'invoice_id':id});
      return id;
    });
  }
  Future<void> setBudget(DateTime date,int amount) async {
    if(amount<0)throw ArgumentError('الميزانية لا يمكن أن تكون سالبة');
    final key='${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}';
    await (await db).insert('budgets',{'month_key':key,'category':null,'amount':amount},conflictAlgorithm:ConflictAlgorithm.replace);
  }
  Future<int> getBudget(DateTime date) async {
    final key='${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}';
    final r=await (await db).query('budgets',columns:['amount'],where:'month_key=? AND category IS NULL',whereArgs:[key],limit:1);
    return r.isEmpty?0:(r.first['amount'] as num).toInt();
  }
  Future<int> deleteRecord(int id) async => (await db).delete('transactions',where:'id=?',whereArgs:[id]);
}
