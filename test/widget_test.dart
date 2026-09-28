import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:woo_manager_app/main.dart';
void main(){testWidgets('connection screen is rendered when no session exists',(tester) async {FlutterSecureStorage.setMockInitialValues({});await tester.pumpWidget(const WooManagerApp());await tester.pumpAndSettle();expect(find.text('اتصال امن به فروشگاه'),findsOneWidget);});}
