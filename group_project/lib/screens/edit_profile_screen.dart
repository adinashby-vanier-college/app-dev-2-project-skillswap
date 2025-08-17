// lib/screens/edit_profile_screen.dart
// Final Edit Profile screen with avatar picker, validation, Firebase Auth/Firestore/Storage integration.
// Comments are in English only (as requested).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/custom_colors.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // read-only (from Auth)
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // State
  bool _loading = false;
  bool _initializing = true;
  bool _dirty = false; // track if user changed anything
  File? _avatarFile;
  String? _avatarUrl; // existing photoURL if any

  // Common getters
  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // mark dirty when user edits fields
    _nameCtrl.addListener(_markDirty);
    _bioCtrl.addListener(_markDirty);
    _locationCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _user.uid;
      _emailCtrl.text = _user.email ?? '';
      _avatarUrl = _user.photoURL;

      // Load from Firestore (users/{uid})
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data() ?? {};
      _nameCtrl.text =
          data['name'] ?? _user.displayName ?? ''; // prefer custom name
      _bioCtrl.text = data['bio']?.toString() ?? '';
      _locationCtrl.text = data['location']?.toString() ?? '';

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
      });
      _showSnack('Failed to load profile: $e');
    }
  }

  Future<void> _pickAvatar() async {
    // return 'gallery' | 'camera' | 'remove'
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (_avatarUrl != null || _avatarFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove current photo'),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    // handle remove
    if (choice == 'remove') {
      setState(() {
        _avatarFile = null;
        _avatarUrl = null;
        _dirty = true;
      });
      return;
    }

    // pick image
    final picker = ImagePicker();
    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _dirty = true;
      });
    }
  }


  Future<String?> _uploadAvatarIfNeeded(String uid) async {
    // If user removed photo and no new file -> clear photo
    if (_avatarFile == null && _avatarUrl == null) {
      try {
        // Optional: delete previous storage file (best-effort)
        final ref =
        FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
        await ref.delete().catchError((_) {});
      } catch (_) {}
      return null;
    }

    if (_avatarFile == null) return _avatarUrl; // unchanged

    final ref =
    FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
    final task = await ref.putFile(
      _avatarFile!,
      SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=3600'),
    );
    final url = await task.ref.getDownloadURL();
    return url;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = _user.uid;

      // Upload avatar if needed
      final newPhotoUrl = await _uploadAvatarIfNeeded(uid);

      // Update Firebase Auth profile (displayName, photoURL)
      await _user.updateDisplayName(_nameCtrl.text.trim());
      await _user.updatePhotoURL(newPhotoUrl);

      // Upsert Firestore user doc
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'photoUrl': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('Profile saved');
      Navigator.of(context).pop(true); // return to previous screen with result
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
  // Delete account method
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('No user logged in');
        return;
      }

      // Delete Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete Auth account
      await user.delete();

      if (!mounted) return;

// Show success message
      _showSnack('Account deleted successfully');

// Sign out to clear current user
      await FirebaseAuth.instance.signOut();

// Go to login screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/signIn', (route) => false);

    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        _showSnack('Please log in again to delete your account.');
      } else {
        _showSnack('Failed to delete account: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F7),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                _Avatar(
                                  size: 108,
                                  imageFile: _avatarFile,
                                  imageUrl: _avatarUrl,
                                  displayName: _nameCtrl.text.trim(),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Material(
                                    color: CustomColors.primaryRed,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _pickAvatar,
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          _LabeledField(
                            label: 'Name',
                            child: TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Your full name',
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Name is required';
                                if (t.length < 2) {
                                  return 'Too short';
                                }
                                if (t.length > 40) {
                                  return 'Max 40 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email (read-only)
                          _LabeledField(
                            label: 'Email',
                            child: TextFormField(
                              controller: _emailCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'Email',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Location (as text field per your choice)
                          _LabeledField(
                            label: 'Location',
                            child: TextFormField(
                              controller: _locationCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined),
                                hintText: 'City, Country',
                              ),
                              maxLength: 80,
                              buildCounter: (
                                  context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) =>
                              null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bio
                          _LabeledField(
                            label: 'Bio',
                            child: TextFormField(
                              controller: _bioCtrl,
                              textInputAction: TextInputAction.newline,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.info_outline),
                                hintText: 'Tell people about yourself',
                                alignLabelWithHint: true,
                              ),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.length > 200) {
                                  return 'Max 200 characters';
                                }
                                return null;
                              },
                            ),
                          ),

                          const Spacer(),

                    // Save button
                    SizedBox(
                      height: 48,
                      width: double.infinity, // full width
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: CustomColors.primaryRed, // project red
                          foregroundColor: Colors.white, // white text
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // rounded corners
                          ),
                        ),
                        onPressed: (_loading || !_dirty) ? null : _save,
                        child: _loading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Save',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                          // spacing between Save and Delete
                          const SizedBox(height: 12),

// Delete Account button
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: _deleteAccount,
                              child: const Text(
                                'Delete Account',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Simple avatar widget that supports File or Network image with fallback initials.
class _Avatar extends StatelessWidget {
  final double size;
  final File? imageFile;
  final String? imageUrl;
  final String? displayName;

  const _Avatar({
    required this.size,
    this.imageFile,
    this.imageUrl,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget img;
    if (imageFile != null) {
      img = ClipOval(
        child: Image.file(
          imageFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      img = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(context),
        ),
      );
    } else {
      img = _initials(context);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: img,
    );
  }

  Widget _initials(BuildContext context) {
    final initials = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: CustomColors.primaryRed, // project red
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: Colors.white, // white text for contrast
        ),
      ),
    );
  }
}

/// Label + Input wrapper to keep spacing and styles consistent.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Theme(
          // Slightly rounded + filled fields for modern look
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                BorderSide(color: theme.dividerColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
