import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/screens/edit_profile_screen.dart';
import 'package:connectedu_app/screens/my_registrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  // Helper to get a placeholder icon
  Widget _getProfilePlaceholder(BuildContext context) {
    return Icon(
      Icons.person,
      size: 50,
      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.7),
    );
  }

  // Helper to format the role
  String _formatRole(String role) {
    switch (role) {
      case 'COLLEGE_ADMIN':
        return 'College Admin';
      case 'CLUB_ADMIN':
        return 'Club Admin';
      case 'CLUB_MEMBER':
        return 'Club Member';
      case 'USER':
        return 'Student';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- THIS IS THE FIX ---
    // We must wrap the screen in a BlocBuilder to get live updates
    // when the profile is changed.
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Get the most up-to-date user object from the state
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
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () {
                              // TODO: Add more options if needed
                            },
                          ),
                        ],
                      ),
                    ),

                    // --- Profile Info Header ---
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                // Use CachedNetworkImage
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
                              currentUser.name, // Use currentUser
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phone, // Use updated phone
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                        // --- Edit Button ---
                        Positioned(
                          top: 75,
                          left: 65,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(1, 1),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                              child: IconButton(
                                iconSize: 16,
                                icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onSecondaryContainer),
                                onPressed: () {
                                  // --- THIS IS THE NAVIGATION ---
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      // We don't need a BlocProvider, as AuthBloc is app-wide
                                      builder: (_) => EditProfileScreen(user: currentUser),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- Account Overview Section ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                              child: Text(
                                'Account Overview',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildProfileOption(
                              context,
                              icon: Icons.person_outline,
                              iconColor: Colors.blueAccent,
                              title: 'My Profile',
                              subtitle: '${_formatRole(currentUser.role)} - ${currentUser.department}', // Use currentUser
                              onTap: () {
                                // --- THIS IS THE NAVIGATION ---
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(user: currentUser),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildProfileOption(
                              context,
                              icon: Icons.list_alt_outlined,
                              iconColor: Colors.green,
                              title: 'My Registrations',
                              subtitle: 'View event participation history',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyRegistrationsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildProfileOption(
                              context,
                              icon: Icons.lock_outline,
                              iconColor: Colors.orange,
                              title: 'Change Password',
                              subtitle: 'Update your login password',
                              onTap: () {
                                // TODO: Navigate to Change Password Screen
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // --- Logout Button ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          context.read<AuthBloc>().add(LoggedOut());
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    // --- END OF BLOCBUILDER WRAPPER ---
  }

  // Helper widget for list tile options
  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}