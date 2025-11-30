import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/screens/analytics_dashboard_screen.dart';
import 'package:connectedu_app/screens/change_password_screen.dart';
import 'package:connectedu_app/screens/edit_profile_screen.dart';
import 'package:connectedu_app/screens/my_registrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart'; // For Invite Friend
import 'package:url_launcher/url_launcher.dart'; // For Privacy Policy

class ProfileScreen extends StatelessWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  Widget _getProfilePlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 50,
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'COLLEGE_ADMIN': return 'College Admin';
      case 'CLUB_ADMIN': return 'Club Admin';
      case 'CLUB_MEMBER': return 'Club Member';
      case 'USER': return 'Student';
      default: return 'User';
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://your-privacy-policy-url.com'); // Replace with your URL
    if (!await launchUrl(url)) {
      // handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final User currentUser = (state is AuthAuthenticated) ? state.user : user;
        final phone = currentUser.phone ?? 'Not set';
        final profileImageUrl = currentUser.profileImageUrl;

        return Scaffold(
          body: Stack(
            children: [
              // --- Background Header ---
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
              ),
              // --- Main Content ---
              SafeArea(
                child: Column(
                  children: [
                    // --- Custom App Bar ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text(
                            'Profile',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          // Invisible icon to balance the row
                          const IconButton(icon: Icon(Icons.more_vert, color: Colors.transparent), onPressed: null),
                        ],
                      ),
                    ),

                    // --- Profile Info Header ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                    ? CachedNetworkImageProvider(profileImageUrl)
                                    : null,
                                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                                    ? _getProfilePlaceholder(context)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentUser.name,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser.email,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_formatRole(currentUser.role)}, ${currentUser.department}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // --- Edit Button (Corner of Circle) ---
                        Positioned(
                          top: 75,
                          left: MediaQuery.of(context).size.width / 2 + 20,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: currentUser)));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Scrollable Menu List ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Header removed as per design image which is just a list

                              _buildProfileOption(context, icon: Icons.person_outline, title: 'My Profile', onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: currentUser)));
                              }),

                              _buildProfileOption(context, icon: Icons.list_alt_outlined, title: 'My Registrations', onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRegistrationsScreen()));
                              }),


                              if (currentUser.role == 'COLLEGE_ADMIN' || currentUser.role == 'CLUB_ADMIN')
                                Column(
                                  children: [
                                    _buildProfileOption(
                                      context,
                                      icon: Icons.analytics_outlined,
                                      iconColor: Colors.purple,
                                      title: 'Analytics Dashboard',
                                      subtitle: 'View performance stats',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AnalyticsDashboardScreen(user: currentUser)),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                  ],
                                ),


                              _buildProfileOption(context, icon: Icons.lock_outline, title: 'Change Password', onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                              }),

                              _buildProfileOption(context, icon: Icons.share_outlined, title: 'Invite a Friend', onTap: () {
                                Share.share('Check out ConnectEdu app! https://connectedu.com');
                              }),

                              _buildProfileOption(context, icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {
                                _launchPrivacyPolicy();
                              }),

                              _buildProfileOption(context, icon: Icons.settings_outlined, title: 'Settings', onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings not implemented')));
                              }),

                              const Divider(),

                              _buildProfileOption(
                                  context,
                                  icon: Icons.logout,
                                  title: 'Logout',
                                  isDestructive: true,
                                  onTap: () {
                                    context.read<AuthBloc>().add(LoggedOut());
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for list tile options
  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? iconColor, // Added as optional
        String? subtitle, // Added as optional
        bool isDestructive = false,
      }) {
    final theme = Theme.of(context);
    final textColor = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    // Determine the icon color: Destructive Red > Custom Color > Default Primary
    final effectiveIconColor = isDestructive
        ? Colors.red
        : (iconColor ?? theme.colorScheme.primary);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
      // Only show subtitle if it's provided
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}