part of 'club_list_bloc.dart';

abstract class ClubListState extends Equatable {
  const ClubListState();
  @override
  List<Object?> get props => [];
}

class ClubListInitial extends ClubListState {}

class ClubListLoading extends ClubListState {}

// Corrected: Uses separate, strongly-typed properties
class ClubListLoaded extends ClubListState {
  final List<Club> clubs;
  final Map<int, int> eventCounts;

  const ClubListLoaded({required this.clubs, required this.eventCounts});

  @override
  List<Object> get props => [clubs, eventCounts];
}

class ClubListError extends ClubListState {
  final String message;
  final bool isRefreshError; // Flag to differentiate UI
  const ClubListError(this.message, {this.isRefreshError = false});
  @override
  List<Object> get props => [message, isRefreshError];
}

// Corrected: Holds the previous 'Loaded' state
class ClubActionInProgress extends ClubListState {
  final ClubListLoaded? previousState;
  const ClubActionInProgress({this.previousState});
  @override
  List<Object?> get props => [previousState];
}

class ClubActionSuccess extends ClubListState {
  final String message;
  const ClubActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ClubActionFailure extends ClubListState {
  final String error;
  const ClubActionFailure(this.error);
  @override
  List<Object> get props => [error];
}

