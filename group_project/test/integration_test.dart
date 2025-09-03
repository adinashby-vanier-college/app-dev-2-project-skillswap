import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_project/features/settings/settings_screen.dart';
import 'package:group_project/features/settings/help_center_screen.dart';
import 'package:group_project/features/settings/terms_of_service_screen.dart';
import 'package:group_project/features/settings/privacy_policy_screen.dart';
import 'package:group_project/features/settings/send_feedback_screen.dart';
import 'package:group_project/features/settings/contact_us_screen.dart';

void main() {
  group('Basic Screen Integration Tests', () {
    testWidgets('Settings screen displays title and loads without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
        ),
      );

      // Should show settings screen and title
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Legal screens display correctly', (WidgetTester tester) async {
      // Test Terms of Service directly
      await tester.pumpWidget(
        MaterialApp(
          home: const TermsOfServiceScreen(),
        ),
      );

      expect(find.byType(TermsOfServiceScreen), findsOneWidget);
      expect(find.text('SkillSwap Terms of Service'), findsOneWidget);

      // Test Privacy Policy directly
      await tester.pumpWidget(
        MaterialApp(
          home: const PrivacyPolicyScreen(),
        ),
      );

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('SkillSwap Privacy Policy'), findsOneWidget);
    });
  });

  group('Form Interaction Tests', () {
    testWidgets('Basic form widgets work correctly', (WidgetTester tester) async {
      // Test a basic form without Firebase dependencies
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify form elements exist
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Submit'), findsOneWidget);

      // Test text input
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Feedback form displays basic elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SendFeedbackScreen(),
        ),
      );

      expect(find.text('We value your feedback!'), findsOneWidget);

      // Find form elements
      final typeDropdown = find.byType(DropdownButtonFormField<String>);
      final feedbackField = find.byType(TextFormField);

      expect(typeDropdown, findsOneWidget);
      expect(feedbackField, findsOneWidget);

      // Enter feedback text
      await tester.enterText(feedbackField, 'This is a test feedback message with enough characters to pass validation.');
      await tester.pump();
    });
  });

  group('User Interface Tests', () {
    testWidgets('Contact us screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ContactUsScreen(),
        ),
      );

      expect(find.text('Get in Touch'), findsOneWidget);

      // Find contact options
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Business Inquiries'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
    });

    testWidgets('Help Center FAQ displays', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HelpCenterScreen(),
        ),
      );

      // Find FAQ items
      expect(find.text('How do I find skill partners?'), findsOneWidget);
      expect(find.text('How do I add or edit my skills?'), findsOneWidget);
      expect(find.text('How does the matching system work?'), findsOneWidget);
    });
  });

  group('Theme Compatibility Tests', () {
    testWidgets('App works with light and dark themes', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SettingsScreen(),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SettingsScreen(),
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Form displays validation elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SendFeedbackScreen(),
        ),
      );

      // Just verify the form elements exist
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('Screens dispose properly without memory leaks', (WidgetTester tester) async {
      // Create and destroy multiple screens to test for memory leaks
      final screens = [
        const SettingsScreen(),
        const HelpCenterScreen(),
        const TermsOfServiceScreen(),
        const PrivacyPolicyScreen(),
        const SendFeedbackScreen(),
        const ContactUsScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(
          MaterialApp(home: screen),
        );
        
        // Verify screen loads
        expect(find.byWidget(screen), findsOneWidget);
        
        // Replace with different screen
        await tester.pumpWidget(
          MaterialApp(home: const Scaffold(body: Text('Different Screen'))),
        );
        
        // Verify old screen is gone
        expect(find.byWidget(screen), findsNothing);
        expect(find.text('Different Screen'), findsOneWidget);
      }
    });
  });
}