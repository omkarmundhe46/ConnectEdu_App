import 'package:connectedu_app/bloc/club_list_bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageClubAdminsScreen extends StatelessWidget {
  const ManageClubAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load on entry
    context.read<ClubListBloc>().add(LoadClubsAndEvents());

    return Scaffold(
      appBar: AppBar(title: const Text("Club Governance")),
      body: BlocBuilder<ClubListBloc, ClubListState>(
        builder: (context, state) {
          if (state is ClubListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ClubListLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.clubs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final club = state.clubs[index];
                return _buildAdminRow(context, club);
              },
            );
          }
          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }

  Widget _buildAdminRow(BuildContext context, Club club) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: club.logoUrl != null ? NetworkImage(club.logoUrl!) : null,
        child: club.logoUrl == null ? const Icon(Icons.groups) : null,
      ),
      title: Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // --- FIXED ROW 1: Admin Name ---
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              // Wrap Text in Expanded to prevent overflow
              Expanded(
                child: Text(
                  club.adminName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis, // Cut off long text
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2), // Small spacing between rows
          // --- FIXED ROW 2: Admin Email ---
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              // Wrap Text in Expanded to prevent overflow
              Expanded(
                child: Text(
                  club.adminEmail.isNotEmpty ? club.adminEmail : "No Email",
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis, // Cut off long text
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'change') {
            _showChangeAdminDialog(context, club);
          } else if (value == 'remove') {
            _confirmRemoveAdmin(context, club);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'change', child: Text("Change Admin")),
          const PopupMenuItem(value: 'remove', child: Text("Remove Admin", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showChangeAdminDialog(BuildContext context, Club club) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Assign Admin for ${club.name}"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "New Admin Email", hintText: "user@example.com"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // Dispatch Update Event with new Email
              if (emailController.text.isNotEmpty) {
                context.read<ClubListBloc>().add(UpdateClub(
                  clubId: club.id,
                  name: club.name,
                  description: club.description,
                  adminEmail: emailController.text.trim(),
                  logoUrl: club.logoUrl,
                  category: club.category,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveAdmin(BuildContext context, Club club) {
    // Optional: Add confirmation dialog here
    context.read<ClubListBloc>().add(UpdateClub(
      clubId: club.id,
      name: club.name,
      description: club.description,
      adminEmail: '', // Sending empty email usually unassigns logic backend side
      logoUrl: club.logoUrl,
      category: club.category,
    ));
  }
}