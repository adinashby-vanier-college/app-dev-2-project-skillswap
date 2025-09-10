import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_exceptions.dart';
import '../../utils/custom_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/navigation_service.dart';

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
  bool _isResetLoading = false;

  Future<void> _signIn() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Signed in successfully")),
      );
      
      NavigationService().navigateToHome();
    } on AuthException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: e is AuthNetworkException ? Colors.orange : Colors.red,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
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
    try {
      final user = await _authService.signInWithGoogle();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Google sign in: ${user.displayName ?? "Success"}")),
      );
      
      NavigationService().navigateToHome();
    } on AuthException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: e is AuthSocialException ? Colors.blue : Colors.red,
        ),
      );
    } catch (e) {
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
    try {
      final user = await _authService.signInWithTwitter();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Twitter sign in: ${user.displayName ?? "Success"}")),
      );
      
      NavigationService().navigateToHome();
    } on AuthException catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: e is AuthSocialException ? Colors.blue : Colors.red,
        ),
      );
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

  Future<void> _forgotPassword() async {
    if (_isResetLoading) return;
    
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isResetLoading = true);
    
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset instructions sent to $email\n\nPlease check your inbox (and spam folder)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Please check your internet connection'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResetLoading = false);
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isResetLoading ? null : _forgotPassword,
                  child: Text(
                    _isResetLoading ? "Sending..." : "Forgot Password?",
                    style: TextStyle(
                      color: _isResetLoading ? Colors.grey : CustomColors.primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      NavigationService().navigateTo(NavigationService.signUp);
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
