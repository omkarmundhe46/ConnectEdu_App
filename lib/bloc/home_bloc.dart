import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ClubRepository clubRepository;
  final EventRepository eventRepository;

  HomeBloc({required this.clubRepository, required this.eventRepository}) : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  void _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Fetch both sets of data in parallel
      final futureClubs = clubRepository.getAllClubs();
      final futureEvents = eventRepository.getAllUpcomingEvents();

      final results = await Future.wait([futureClubs, futureEvents]);

      final clubs = results[0] as List<Club>;
      final events = results[1] as List<Event>;

      emit(HomeLoaded(clubs: clubs, upcomingEvents: events));
    } catch (e) {
      emit(HomeError(message: 'Failed to load data. Please try again.'));
    }
  }
}

