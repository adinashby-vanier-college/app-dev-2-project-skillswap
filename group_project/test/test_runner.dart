import 'package:flutter_test/flutter_test.dart';

// Import working test files
import 'working_tests.dart' as working_tests;
import 'simple_widget_test.dart' as simple_tests;
import 'unit_test.dart' as unit_tests;

/// Main test runner that executes all working test suites
/// 
/// Run with: flutter test test/test_runner.dart
void main() {
  group('SkillSwap App Test Suite', () {
    group('Core Functionality Tests', () {
      working_tests.main();
    });
    
    group('Simple Widget Tests', () {
      simple_tests.main();
    });
    
    group('Unit Tests', () {
      unit_tests.main();
    });
  });
}