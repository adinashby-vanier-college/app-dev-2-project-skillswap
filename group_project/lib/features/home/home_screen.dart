import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:group_project/features/settings/settings_screen.dart';
import '../../providers/theme_provider.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/edit_skills_screen.dart';
import '../matches/matches_screen.dart';
import '../matches/match_history_screen.dart';
import '../matches/all_sessions_screen.dart';
import '../../services/notification_service.dart';
import '../notifications/notifications_screen.dart';
import '../chat/chat_service.dart';
import '../chat/models/conversation_preview.dart';

/// Main home screen with bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  final ChatService _chatService = ChatService();
  late final Stream<List<ConversationPreview>> _conversationsStream;
  late final Stream<int> _notificationsStream;

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
  void initState() {
    super.initState();
    // Initialize streams once to prevent multiple subscriptions
    _conversationsStream = _chatService.getConversations(includeArchived: false);
    _notificationsStream = NotificationService().getUnreadCount();
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
            RepaintBoundary(
              child: Container(
                height: 34,
                width: 34,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 25/255),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: FlutterLogo(size: 20)),
              ),
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
          StreamBuilder<int>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
                GestureDetector(
                  onTap: _openEditProfile,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withValues(alpha: 50/255),
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
                          color: colorScheme.onSurface.withValues(alpha: 153/255),
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
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 128/255)),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 153/255)),
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
            RepaintBoundary(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
              children: [
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
                  icon: Icons.history,
                  label: 'Match History',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
                    );
                  },
                  theme: theme,
                ),

                StreamBuilder<List<ConversationPreview>>(
                  stream: _conversationsStream,
                  builder: (context, snapshot) {
                    final conversations = snapshot.data ?? [];
                    final totalUnread = conversations.fold<int>(
                      0, (sum, conv) => sum + conv.unreadCount
                    );
                    
                    return _featureCardWithBadge(
                      icon: Icons.message_outlined,
                      label: 'Messages',
                      color: Colors.purple,
                      onTap: _openMessages,
                      theme: theme,
                      badgeCount: totalUnread,
                    );
                  },
                ),
                
                _featureCard(
                  icon: Icons.event_outlined,
                  label: 'Sessions',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: StreamBuilder<List<ConversationPreview>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          final conversations = snapshot.data ?? [];
          final totalUnread = conversations.fold<int>(
            0, (sum, conv) => sum + conv.unreadCount
          );
          
          return NavigationBar(
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
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined), 
                selectedIcon: Icon(Icons.home), 
                label: 'Home'
              ),
              NavigationDestination(
                icon: totalUnread > 0 
                    ? Badge(
                        label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
                        child: const Icon(Icons.message_outlined),
                      )
                    : const Icon(Icons.message_outlined),
                selectedIcon: totalUnread > 0 
                    ? Badge(
                        label: Text(totalUnread > 99 ? '99+' : '$totalUnread'),
                        child: const Icon(Icons.message),
                      )
                    : const Icon(Icons.message),
                label: 'Messages',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline), 
                selectedIcon: Icon(Icons.person), 
                label: 'Profile'
              ),
            ],
          );
        },
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
    return _FeatureCard(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
      theme: theme,
    );
  }

  Widget _featureCardWithBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required int badgeCount,
  }) {
    return _FeatureCardWithBadge(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
      theme: theme,
      badgeCount: badgeCount,
    );
  }
}

class _FeatureCardWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;
  final int badgeCount;

  const _FeatureCardWithBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.theme,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor,
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 20/255)
              : color.withValues(alpha: 40/255),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: color.withValues(alpha: 20/255),
          splashColor: color.withValues(alpha: 30/255),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 120/255),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon, 
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor,
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 20/255)
              : color.withValues(alpha: 40/255),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: color.withValues(alpha: 20/255),
          splashColor: color.withValues(alpha: 30/255),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 120/255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon, 
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureCardWithBadge({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required int badgeCount,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [
                  theme.cardColor,
                  theme.cardColor.withValues(alpha: 200/255),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 30/255),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 40/255)
                : Colors.grey.shade300.withValues(alpha: 100/255),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 20/255)
              : color.withValues(alpha: 40/255),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          highlightColor: color.withValues(alpha: 20/255),
          splashColor: color.withValues(alpha: 30/255),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 120/255),
                            color.withValues(alpha: 80/255),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 60/255),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon, 
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}