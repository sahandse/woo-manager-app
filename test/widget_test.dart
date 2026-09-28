import 'package:flutter_test/flutter_test.dart';
import 'package:woo_manager_app/main.dart';
void main(){testWidgets('connection screen is rendered',(tester) async {await tester.pumpWidget(const WooManagerApp());expect(find.text('اتصال به فروشگاه'),findsOneWidget);});}
