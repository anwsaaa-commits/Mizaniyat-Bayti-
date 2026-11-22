import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_sales_ledger/main.dart';
void main(){testWidgets('home screen renders', (tester) async {await tester.pumpWidget(const TunaApp());await tester.pump();expect(find.text('حسابات بيع وشراء السمك'),findsOneWidget);});}
