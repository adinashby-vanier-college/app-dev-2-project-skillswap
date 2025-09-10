import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../home/home_screen.dart';
import 'sign_in_screen.dart';

/// Screen for email verification after user registration.
class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final isVerified = await AuthService.instance.reloadAndCheckEmailVerified();
      if (!mounted) return;

      if (isVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (r) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Not verified yet. Please click the link in your email.'),
              duration: Duration(seconds: 3),
            ),
          );
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        _ => e.message ?? 'Failed to check verification. Please try again.'
      };
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Check failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Verification email has been resent.'),
            duration: Duration(seconds: 3),
          ),
        );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'too-many-requests' => 'Too many requests. Please wait before trying again.',
        _ => e.message ?? 'Failed to resend verification email.'
      };
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Resend failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = widget.email ?? AuthService.instance.currentUserEmail ?? 'No email found';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F7),
      appBar: AppBar(title: const Text('Verify Email'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'We sent a verification email to:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please open your mailbox and click the verification link.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _checking ? null : _checkVerified,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF6524F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _checking
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Text('Verified & Continue'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: _resending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Resend Email'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                            (r) => false,
                      );
                    },
                    child: const Text('Back to Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
