import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/custom_colors.dart';


/// Screen for editing user profile information.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = false;
  bool _initializing = true;
  bool _dirty = false; // track if user changed anything
  File? _avatarFile;
  String? _avatarUrl; // existing photoURL if any

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    final theme = Theme.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.cardColor,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: theme.colorScheme.onSurface),
                title: Text('Choose from gallery', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: theme.colorScheme.onSurface),
                title: Text('Take a photo', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (_avatarUrl != null || _avatarFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove current photo', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'remove') {
      setState(() {
        _avatarFile = null;
        _avatarUrl = null;
        _dirty = true;
      });
      return;
    }

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
    if (_avatarFile == null && _avatarUrl == null) {
      try {
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

      final newPhotoUrl = await _uploadAvatarIfNeeded(uid);

      await _user.updateDisplayName(_nameCtrl.text.trim());
      await _user.updatePhotoURL(newPhotoUrl);

      String location = _locationCtrl.text.trim();
      double? lat;
      double? lng;

      if (location.isNotEmpty) {
        try {
          final results = await locationFromAddress(location);
          if (results.isNotEmpty) {
            lat = results.first.latitude;
            lng = results.first.longitude;
          }
        } catch (e) {
          debugPrint("Geocoding failed: $e");
        }
      }

      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'location': location,
        'lat': lat,
        'lng': lng,
        'photoUrl': newPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack('Profile saved');
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Delete Account', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to permanently delete your account?',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final navigator = Navigator.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('No user logged in');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      await user.delete();

      if (!mounted) return;
      _showSnack('Account deleted successfully');

      await FirebaseAuth.instance.signOut();

      navigator.pushNamedAndRemoveUntil('/signIn', (route) => false);

    } catch (e) {
      if (!mounted) return;
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: theme.cardColor,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
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

                          _LabeledField(
                            label: 'Name',
                            child: TextFormField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: colorScheme.onSurface.withValues(alpha: 153/255)),
                                hintText: 'Your full name',
                                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 128/255)),
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

                          _LabeledField(
                            label: 'Email',
                            child: TextFormField(
                              controller: _emailCtrl,
                              readOnly: true,
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 153/255)),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurface.withValues(alpha: 153/255)),
                                hintText: 'Email',
                                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 128/255)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _LabeledField(
                            label: 'Location',
                            child: TextFormField(
                              controller: _locationCtrl,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined, color: colorScheme.onSurface.withValues(alpha: 153/255)),
                                hintText: 'City, Country',
                                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 128/255)),
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

                          _LabeledField(
                            label: 'Bio',
                            child: TextFormField(
                              controller: _bioCtrl,
                              textInputAction: TextInputAction.newline,
                              maxLines: 4,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.info_outline, color: colorScheme.onSurface.withValues(alpha: 153/255)),
                                hintText: 'Tell people about yourself',
                                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 128/255)),
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
                          const SizedBox(height: 12),

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
          errorBuilder: (_, _, _) => _initials(context),
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
            color: theme.colorScheme.primary.withValues(alpha: 46/255),
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
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary),
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