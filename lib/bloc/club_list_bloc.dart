import 'package:bloc/bloc.dart';
import 'package:connectedu_app/models/club.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:equatable/equatable.dart';

part 'club_list_event.dart';
part 'club_list_state.dart';

class ClubListBloc extends Bloc<ClubListEvent, ClubListState> {
  final ClubRepository clubRepository;
  final EventRepository eventRepository;

  ClubListBloc({required this.clubRepository, required this.eventRepository}) : super(ClubListInitial()) {
    on<LoadClubs>(_onLoadClubs);
  }

  Future<void> _onLoadClubs(LoadClubs event, Emitter<ClubListState> emit) async {
    emit(ClubListLoading());
    try {
      // 1. Fetch all clubs
      final List<Club> clubs = await clubRepository.getAllClubs();

      // 2. Fetch event counts for each club concurrently
      final List<Map<String, dynamic>> clubsWithCounts = await Future.wait(
        clubs.map((club) async {
          final events = await eventRepository.getEventsByClub(club.id);
          return {'club': club, 'eventCount': events.length};
        }).toList(),
      );

      // 3. Emit the loaded state with combined data
      emit(ClubListLoaded(clubsWithCounts));
    } catch (e) {
      emit(ClubListError(e.toString()));
    }
  }
}

