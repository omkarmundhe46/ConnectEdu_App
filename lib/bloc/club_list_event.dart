part of 'club_list_bloc.dart';

abstract class ClubListEvent extends Equatable {
  const ClubListEvent();

  @override
  List<Object> get props => [];
}

class LoadClubs extends ClubListEvent {}

