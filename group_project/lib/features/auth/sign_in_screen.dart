import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../../utils/custom_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/fcm_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isTwitterLoading = false;

  Future<void> _signIn() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Signed in successfully")),
      );
      
      // Initialize FCM after successful sign in
      FCMService().initialize().catchError((e) {
        // FCM initialization error handled silently
      });
      
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    
    setState(() {
      _isGoogleLoading = true;
    });
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final user = await _authService.signInWithGoogle();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Google sign in: ${user.displayName ?? "Success"}")),
      );
      
      // Initialize FCM after successful sign in
      FCMService().initialize().catchError((e) {
        // FCM initialization error handled silently
      });
      
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      // Google sign-in error handled silently
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Google login failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }


  Future<void> _signInWithTwitter() async {
    if (_isTwitterLoading) return;
    
    setState(() {
      _isTwitterLoading = true;
    });
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final user = await _authService.signInWithTwitter();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Twitter sign in: ${user.displayName ?? "Success"}")),
      );
      
      // Initialize FCM after successful sign in
      FCMService().initialize().catchError((e) {
        // FCM initialization error handled silently
      });
      
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Twitter login failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTwitterLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                "Sign In",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hi there! Nice to see you again.",
                style: TextStyle(fontSize: 16, color: CustomColors.lightGrey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "example@email.com",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? "Signing in..." : "Sign in",
                onPressed: _isLoading ? null : _signIn,
              ),
              const SizedBox(height: 16),
              const Text("or use one of your social profiles"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGoogleLoading ? null : () => _signInWithGoogle(),
                      icon: _isGoogleLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata),
                      label: Text(_isGoogleLoading ? "Loading..." : "Google"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTwitterLoading ? null : () => _signInWithTwitter(),
                      icon: _isTwitterLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close, size: 20),
                      label: Text(_isTwitterLoading ? "Loading..." : "X"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: implement Forgot Password
                    },
                    child: const Text("Forgot Password?"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signUp');
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: CustomColors.primaryRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
