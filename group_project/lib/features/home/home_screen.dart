import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:group_project/features/settings/settings_screen.dart';
import '../../providers/theme_provider.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/edit_skills_screen.dart';
import '../matches/matches_screen.dart';
import '../chat/chat_service.dart';
import '../chat/models/conversation_preview.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  final ChatService _chatService = ChatService();

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true) {
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openMessages() {
    Navigator.pushNamed(context, '/conversations');
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchesScreen(searchQuery: query.trim()),
      ),
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data();
      return userData?['name']?.toString() ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _openConversation(ConversationPreview conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          isArchived: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = _user?.displayName?.trim();
    final email = _user?.email ?? '';

    final photo = _user?.photoURL ?? '';
    final initialTop = (name?.isNotEmpty == true
        ? name!.characters.first
        : (email.isNotEmpty ? email.characters.first : 'U'))
        .toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: FlutterLogo(size: 20)),
            ),
            Text(
              'SkillSwap',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.themeMode == ThemeMode.dark;
              final isLight = themeProvider.themeMode == ThemeMode.light;
              
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  // Toggle between light and dark (ignore system mode for simplicity)
                  if (isDark) {
                    themeProvider.setTheme('light');
                  } else {
                    themeProvider.setTheme('dark');
                  }
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: Icon(Icons.logout, color: colorScheme.onSurface),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withAlpha(50),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Text(
                    initialTop,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${name?.isNotEmpty == true ? ', $name' : ''} 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(153),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search any skill or person…',
                hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(128)),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withAlpha(153)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  onPressed: () => _performSearch(_searchCtrl.text),
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 18),
            _sectionTitle('Quick actions', colorScheme),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                _featureCard(
                  icon: Icons.school_outlined,
                  label: 'My Skills',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditSkillsScreen()),
                    );
                  },
                  theme: theme,
                ),

                _featureCard(
                  icon: Icons.people_outline,
                  label: 'My Matches',
                  color: Colors.deepOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MatchesScreen()),
                    );
                  },
                  theme: theme,
                ),

                _featureCard(
                  icon: Icons.history,
                  label: 'Match History',
                  color: Colors.amber,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Match History - Coming Soon!')),
                    );
                  },
                  theme: theme,
                ),

                _featureCard(
                  icon: Icons.message_outlined,
                  label: 'Messages',
                  color: Colors.purple,
                  onTap: _openMessages,
                  theme: theme,
                ),
                
                _featureCard(
                  icon: Icons.event_outlined,
                  label: 'Sessions',
                  color: Colors.blueGrey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sessions - Coming Soon!')),
                    );
                  },
                  theme: theme,
                ),
                
                _featureCard(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Recent conversations', colorScheme),
            const SizedBox(height: 10),
            StreamBuilder<List<ConversationPreview>>(
              stream: _chatService.getConversations(includeArchived: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final conversations = snapshot.data ?? [];
                final recentConversations = conversations.take(2).toList();
                
                if (recentConversations.isEmpty) {
                  return Container(
                    height: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, 
                               color: Colors.grey[400], size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'No recent conversations',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentConversations.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final convo = recentConversations[index];
                      final chatPartnerId = convo.participants.firstWhere(
                        (id) => id != _chatService.currentUserId,
                        orElse: () => 'Unknown',
                      );
                      
                      return FutureBuilder<String>(
                        future: _getUserName(chatPartnerId),
                        builder: (context, userNameSnapshot) {
                          final userName = userNameSnapshot.data ?? chatPartnerId;
                          final initials = userName.isNotEmpty 
                              ? userName.characters.first.toUpperCase()
                              : 'U';
                          
                          return _conversationChip(
                            initials: initials,
                            title: userName,
                            subtitle: convo.lastMessage.isEmpty || convo.lastMessage == 'message was deleted'
                                ? 'No messages yet'
                                : convo.lastMessage,
                            onTap: () => _openConversation(convo),
                            theme: theme,
                            hasUnread: convo.unreadCount > 0,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.cardColor,
        onDestinationSelected: (i) {
          if (i == 1) {
            _openMessages();
            return;
          }
          if (i == 2) {
            _openEditProfile();
            return;
          }
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha(10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchChip({
    required String initials,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final photoUrl = _user?.photoURL;
    final String initial = initials.toUpperCase();

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: theme.shadowColor.withAlpha(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withAlpha(50),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                  initial,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                            fontSize: 12.5)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                onPressed: onTap,
                tooltip: 'Message',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversationChip({
    required String initials,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool hasUnread,
  }) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: theme.shadowColor.withAlpha(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(12),
          decoration: hasUnread 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red, width: 2),
                )
              : null,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withAlpha(50),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                        fontSize: 12.5,
                        fontStyle: subtitle == 'No messages yet' ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}