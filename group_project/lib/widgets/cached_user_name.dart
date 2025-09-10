import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CachedUserName extends StatefulWidget {
  final String userId;
  final Widget Function(String name) builder;
  
  const CachedUserName({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  State<CachedUserName> createState() => _CachedUserNameState();
}

class _CachedUserNameState extends State<CachedUserName> {
  static final Map<String, String> _nameCache = {};
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_nameCache.containsKey(widget.userId)) {
      setState(() {
        _userName = _nameCache[widget.userId];
        _isLoading = false;
      });
      return;
    }

    final mockUsers = ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace', 'Hank'];
    if (mockUsers.contains(widget.userId)) {
      setState(() {
        _userName = widget.userId;
        _nameCache[widget.userId] = widget.userId;
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final userData = userDoc.data();
      final name = userData?['name']?.toString() ?? widget.userId;
      
      if (mounted) {
        setState(() {
          _userName = name;
          _nameCache[widget.userId] = name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = widget.userId;
          _nameCache[widget.userId] = widget.userId;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.builder(widget.userId);
    }
    return widget.builder(_userName ?? widget.userId);
  }
}