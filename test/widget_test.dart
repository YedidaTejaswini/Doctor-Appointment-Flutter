import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_appointment/main.dart';

void main() {
  testWidgets('MediCare smoke test', (WidgetTester tester) async {
    const app = MediCareApp();
    expect(app, isNotNull);
  });
}
