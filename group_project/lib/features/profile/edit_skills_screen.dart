import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  final TextEditingController _newSkillHaveController = TextEditingController();
  final TextEditingController _newSkillWantController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  
  List<String> _skillsHave = [];
  List<String> _skillsWant = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          // Handle both old format (string) and new format (array)
          final skillsHaveData = data['skillsHave'];
          final skillsWantData = data['skillsWant'];
          
          if (skillsHaveData is List) {
            _skillsHave = List<String>.from(skillsHaveData);
          } else if (skillsHaveData is String && skillsHaveData.isNotEmpty) {
            _skillsHave = [skillsHaveData];
          }
          
          if (skillsWantData is List) {
            _skillsWant = List<String>.from(skillsWantData);
          } else if (skillsWantData is String && skillsWantData.isNotEmpty) {
            _skillsWant = [skillsWantData];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading skills: $e");
    }
  }

  Future<void> _saveSkills() async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'skillsHave': _skillsHave,
        'skillsWant': _skillsWant,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skills updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving skills: $e')),
      );
    }
  }

  void _addSkillHave() {
    final skill = _newSkillHaveController.text.trim();
    if (skill.isNotEmpty && !_skillsHave.contains(skill)) {
      setState(() {
        _skillsHave.add(skill);
        _newSkillHaveController.clear();
      });
    }
  }

  void _addSkillWant() {
    final skill = _newSkillWantController.text.trim();
    if (skill.isNotEmpty && !_skillsWant.contains(skill)) {
      setState(() {
        _skillsWant.add(skill);
        _newSkillWantController.clear();
      });
    }
  }

  void _removeSkillHave(String skill) {
    setState(() {
      _skillsHave.remove(skill);
    });
  }

  void _removeSkillWant(String skill) {
    setState(() {
      _skillsWant.remove(skill);
    });
  }

  Widget _buildSkillChip(String skill, bool isHave) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Chip(
        label: Text(skill),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: isHave ? () => _removeSkillHave(skill) : () => _removeSkillWant(skill),
        backgroundColor: Colors.red.withOpacity(0.1),
        deleteIconColor: Colors.red,
        labelStyle: const TextStyle(color: Colors.red),
        side: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildSkillSection(
    String title, 
    List<String> skills, 
    TextEditingController controller, 
    VoidCallback onAdd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        
        // Add skill input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Add a skill...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text("Add"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Skills chips
        if (skills.isNotEmpty)
          Wrap(
            children: skills.map((skill) => 
              _buildSkillChip(skill, title.contains("Have"))
            ).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              "No skills added yet. Add some skills above!",
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Edit Skills"),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Manage Your Skills",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Add multiple skills to find better matches",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 30),

              // Skills I Have Section
              _buildSkillSection(
                "Skills I Have",
                _skillsHave,
                _newSkillHaveController,
                _addSkillHave,
              ),
              
              const SizedBox(height: 30),

              // Skills I Want to Learn Section
              _buildSkillSection(
                "Skills I Want to Learn",
                _skillsWant,
                _newSkillWantController,
                _addSkillWant,
              ),
              
              const SizedBox(height: 20),
              
              Text(
                "💡 Tip: Add multiple skills to increase your chances of finding matches!",
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSkills,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Save Skills (${_skillsHave.length + _skillsWant.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
