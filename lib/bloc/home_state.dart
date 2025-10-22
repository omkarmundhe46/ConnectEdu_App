part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Club> clubs;
  final List<Event> upcomingEvents;

  const HomeLoaded({required this.clubs, required this.upcomingEvents});

  @override
  List<Object> get props => [clubs, upcomingEvents];
}

class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}

