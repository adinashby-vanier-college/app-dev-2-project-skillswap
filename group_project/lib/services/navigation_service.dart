import 'package:flutter/material.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/conversations_screen.dart';
import '../features/chat/archived_chats_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/edit_skills_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/matches/matches_screen.dart';
import '../utils/app_logger.dart';

/// Centralized navigation service for consistent routing and deep linking support.
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current context from navigator
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// App route names - centralized for consistency
  static const String signIn = '/signIn';
  static const String signUp = '/signUp';
  static const String home = '/home';
  static const String conversations = '/conversations';
  static const String archivedChats = '/archivedChats';
  static const String editProfile = '/editProfile';
  static const String editSkills = '/editSkills';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String matches = '/matches';

  /// Route generator for named routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    AppLogger.debug('Navigating to: ${settings.name}', tag: 'NAVIGATION');

    switch (settings.name) {
      case '/signIn':
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      
      case '/signUp':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/conversations':
        return MaterialPageRoute(builder: (_) => const ConversationsScreen());
      
      case '/archivedChats':
        return MaterialPageRoute(builder: (_) => const ArchivedChatsScreen());
      
      case '/editProfile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      
      case '/editSkills':
        return MaterialPageRoute(builder: (_) => const EditSkillsScreen());
      
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      
      case '/matches':
        final args = settings.arguments as Map<String, dynamic>?;
        final searchQuery = args?['searchQuery'] as String?;
        return MaterialPageRoute(
          builder: (_) => MatchesScreen(searchQuery: searchQuery),
        );
      
      default:
        AppLogger.warn('Unknown route: ${settings.name}', tag: 'NAVIGATION');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }

  /// Navigate to a named route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    AppLogger.debug('Navigating to: $routeName', tag: 'NAVIGATION');
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  Future<dynamic> navigateAndReplace(String routeName, {Object? arguments}) {
    AppLogger.debug('Navigating and replacing with: $routeName', tag: 'NAVIGATION');
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate and clear all previous routes
  Future<dynamic> navigateAndClearStack(String routeName, {Object? arguments}) {
    AppLogger.debug('Navigating and clearing stack to: $routeName', tag: 'NAVIGATION');
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  void goBack([dynamic result]) {
    AppLogger.debug('Going back', tag: 'NAVIGATION');
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop(result);
    }
  }

  /// Check if can go back
  bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Navigate to home screen (common after login)
  Future<void> navigateToHome() {
    return navigateAndReplace(home);
  }

  /// Navigate to sign in screen (common after logout)
  Future<void> navigateToSignIn() {
    return navigateAndClearStack(signIn);
  }

  /// Navigate to matches with optional search query
  Future<void> navigateToMatches({String? searchQuery}) {
    final arguments = searchQuery != null ? {'searchQuery': searchQuery} : null;
    return navigateTo(matches, arguments: arguments);
  }

  /// Show error dialog
  Future<void> showErrorDialog(String title, String message) async {
    final context = currentContext;
    if (context == null) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    final context = currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    final context = currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}