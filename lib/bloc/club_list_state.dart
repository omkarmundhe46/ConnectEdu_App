part of 'club_list_bloc.dart';

abstract class ClubListState extends Equatable {
  const ClubListState();

  @override
  List<Object> get props => [];
}

class ClubListInitial extends ClubListState {}

class ClubListLoading extends ClubListState {}

class ClubListLoaded extends ClubListState {
  // Store clubs paired with their event counts
  final List<Map<String, dynamic>> clubsWithEventCounts;

  const ClubListLoaded(this.clubsWithEventCounts);

  @override
  List<Object> get props => [clubsWithEventCounts];
}

class ClubListError extends ClubListState {
  final String message;

  const ClubListError(this.message);

  @override
  List<Object> get props => [message];
}

