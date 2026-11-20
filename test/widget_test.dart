import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/features/auth/login_screen.dart';

void main() {
  testWidgets(
    'LoginScreen muestra título LibreMIEL y aviso de privacidad local',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('LibreMIEL'), findsOneWidget);
      expect(find.text('Usuario / DNI'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.textContaining('miel.unlam.edu.ar'), findsOneWidget);
    },
  );
}
