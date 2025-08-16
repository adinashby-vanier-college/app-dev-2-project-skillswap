import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  // Fake data for demonstration (non-IT skills included)
  final List<Map<String, String>> matches = const [
    {"name": "Alice", "skill": "Basketball"},
    {"name": "Bob", "skill": "Guitar Playing"},
    {"name": "Charlie", "skill": "Cooking"},
    {"name": "Diana", "skill": "Singing"},
    {"name": "Ethan", "skill": "Photography"},
    {"name": "Fiona", "skill": "Public Speaking"},
    {"name": "George", "skill": "Drawing"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Matches"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  match["name"]![0], // first letter of name
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(match["name"] ?? "Unknown"),
              subtitle: Text("Skill: ${match["skill"]}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tapped on ${match['name']}")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
