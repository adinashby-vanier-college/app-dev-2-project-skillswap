import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/home/home_screen.dart';
import 'features/chat/conversations_screen.dart';
import 'features/chat/archived_chats_screen.dart';

/// Background handler for Firebase messages (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
  debugPrint("Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Add performance monitoring in debug mode
  if (kDebugMode) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.totalSpan.inMilliseconds > 16) {
          debugPrint('⚠️ Frame took ${timing.totalSpan.inMilliseconds}ms');
        }
      }
    });
  }
  
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SkillSwap',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.indigo,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.indigo,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            home: const SignInScreen(),
            routes: {
              '/signIn': (context) => const SignInScreen(),
              '/signUp': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/conversations': (context) => const ConversationsScreen(),
              '/archivedChats': (context) => const ArchivedChatsScreen(),
            },
          );
        },
      ),
    );
  }
}


// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snapshot.hasData) {
//           // Logged in → HomeScreen
//           return const HomeScreen();
//         }
//         // Not logged in → SignInScreen
//         return const SignInScreen();
//       },
//     );
//   }
// }
