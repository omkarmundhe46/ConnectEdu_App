import 'package:bloc/bloc.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:equatable/equatable.dart';

part 'event_list_event.dart';
part 'event_list_state.dart';

class EventListBloc extends Bloc<EventListEvent, EventListState> {
  final EventRepository eventRepository;

  EventListBloc({required this.eventRepository}) : super(EventListInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<FilterEvents>(_onFilterEvents); // Add handler for the new event
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventListState> emit) async {
    emit(EventListLoading());
    try {
      final List<Event> events = await eventRepository.getEventsByClub(event.clubId);
      // Sort events by date, newest first (optional, adjust as needed)
      events.sort((a, b) => b.date.compareTo(a.date));
      // Default to showing UPCOMING events first
      emit(EventListLoaded(allEvents: events, currentFilter: EventFilter.upcoming));
    } catch (e) {
      emit(EventListError(e.toString()));
    }
  }

  // --- ADD THIS NEW HANDLER ---
  void _onFilterEvents(FilterEvents event, Emitter<EventListState> emit) {
    // We only need to update the filter if the data is already loaded
    if (state is EventListLoaded) {
      final currentState = state as EventListLoaded;
      // Emit a new state with the updated filter
      emit(currentState.copyWith(currentFilter: event.filter));
    }
  }

}
