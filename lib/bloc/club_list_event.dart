part of 'club_list_bloc.dart';

abstract class ClubListEvent extends Equatable {
  const ClubListEvent();
  @override
  List<Object?> get props => [];
}

// Event to load all clubs and event counts
class LoadClubsAndEvents extends ClubListEvent {}

// Event to create a new club
class CreateClub extends ClubListEvent {
  final String name;
  final String description;
  final String adminEmail;
  final String? logoUrl;
  final String category;
  const CreateClub({required this.name, required this.description, required this.adminEmail, this.logoUrl, required this.category,});
  @override
  List<Object?> get props => [name, description, adminEmail, logoUrl, category];
}

// Event to update an existing club
class UpdateClub extends ClubListEvent {
  final int clubId;
  final String name;
  final String description;
  final String adminEmail;
  final String? logoUrl;
  final String category;
  const UpdateClub({required this.clubId, required this.name, required this.description, required this.adminEmail, this.logoUrl, required this.category,});
  @override
  List<Object?> get props => [clubId, name, description, adminEmail, logoUrl, category];
}

// Event to delete a club
class DeleteClub extends ClubListEvent {
  final int clubId;
  const DeleteClub(this.clubId);
  @override
  List<Object> get props => [clubId];
}

