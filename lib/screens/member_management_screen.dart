import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Simple model for the list item (you might need to fetch user details like name/email separately
// or update your backend DTO to include them. For now, we'll just show User ID).
import 'package:connectedu_app/dto/club_member_dto.dart'; // Ensure this exists or create it

class MemberManagementScreen extends StatefulWidget {
  final Club club;
  const MemberManagementScreen({super.key, required this.club});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  late Future<List<ClubMemberDto>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      // You need to add getClubMembers to your ClubRepository
      _membersFuture = context.read<ClubRepository>().getClubMembers(widget.club.id);
    });
  }

  Future<void> _removeMember(int userId) async {
    try {
      await context.read<ClubRepository>().removeMember(widget.club.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully.'), backgroundColor: Colors.green),
        );
        _loadMembers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return const Center(child: Text('No members in this club yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              final member = members[i];
              // Assuming member object has userId and maybe other fields
              // If your backend only returns IDs, you might need to fetch user details here
              // For now, we display the User ID.
              return ListTile(
                leading: CircleAvatar(child: Text(member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?'),),
                title: Text(member.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Role: ${member.role}'),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  onPressed: () => _showRemoveDialog(member.userId, member.userName),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showRemoveDialog(int userId, String userName) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName? They will lose access to club chats.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(ctx);
                _removeMember(userId);
              }
          ),
        ],
      ),
    );
  }
}