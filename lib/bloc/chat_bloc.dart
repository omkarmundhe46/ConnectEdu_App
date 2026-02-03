import 'package:bloc/bloc.dart';
import 'package:connectedu_app/models/chat_message_model.dart';
import 'package:connectedu_app/repositories/chat_repository.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

// --- EVENTS ---
abstract class ChatEvent {}

class LoadChatHistory extends ChatEvent {
  final String currentUserId; // We need this to identify which messages are yours
  LoadChatHistory(this.currentUserId);
}

class SendChatMessage extends ChatEvent {
  final ChatMessage message; // DashChat message object
  SendChatMessage(this.message);
}

// --- STATES ---
abstract class ChatState {}
class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatError extends ChatState {
  final String error;
  ChatError(this.error);
}
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  ChatLoaded({required this.messages, this.isTyping = false});
}

// --- BLOC ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  // Define the Bot User for the UI
  final ChatUser _botUser = ChatUser(
      id: 'BOT',
      firstName: 'ConnectEdu AI',
      profileImage: "https://cdn-icons-png.flaticon.com/512/4712/4712027.png"
  );

  ChatBloc(this.chatRepository) : super(ChatInitial()) {

    // 1. UPDATED: Load History Logic
    on<LoadChatHistory>((event, emit) async {
      emit(ChatLoading());

      try {
        // Fetch history from backend (returns list ordered by Oldest -> Newest)
        final List<ChatMessageModel> historyModels = await chatRepository.getChatHistory();

        List<ChatMessage> uiMessages = [];

        // Convert to DashChat format
        // We iterate in reverse (Newest -> Oldest) because DashChat usually expects the newest message at index 0
        for (var model in historyModels.reversed) {
          uiMessages.add(ChatMessage(
            user: model.sender == 'USER'
                ? ChatUser(id: event.currentUserId) // Use real User ID passed from UI
                : _botUser,
            text: model.content,
            createdAt: model.timestamp,
          ));
        }

        // If history is empty, show the welcome message
        if (uiMessages.isEmpty) {
          final welcomeMsg = ChatMessage(
            user: _botUser,
            text: "👋 Hello! I am the ConnectEdu Assistant.\n\nAsk me about:\n📅 Upcoming Events\n🛡️ Clubs\n📞 Contact Info",
            createdAt: DateTime.now(),
          );
          uiMessages.add(welcomeMsg);
        }

        emit(ChatLoaded(messages: uiMessages));

      } catch (e) {
        // If loading history fails, just start with an empty chat or welcome message
        // This prevents the screen from getting stuck on loading
        final welcomeMsg = ChatMessage(
          user: _botUser,
          text: "👋 Hello! I am the ConnectEdu Assistant.\n\nAsk me about:\n📅 Upcoming Events\n🛡️ Clubs\n📞 Contact Info",
          createdAt: DateTime.now(),
        );
        emit(ChatLoaded(messages: [welcomeMsg]));
      }
    });

    // 2. Send Message Logic (Kept mostly the same)
    on<SendChatMessage>((event, emit) async {
      final currentState = state;
      if (currentState is ChatLoaded) {
        // Show User Message immediately & set "Typing..."
        final updatedMessages = [event.message, ...currentState.messages];
        emit(ChatLoaded(messages: updatedMessages, isTyping: true));

        try {
          // Call Backend
          final botResponseModel = await chatRepository.sendMessage(event.message.text);

          // Convert response to DashChat format
          final botMsgUi = ChatMessage(
            user: _botUser,
            text: botResponseModel.content,
            createdAt: botResponseModel.timestamp,
          );

          // Update UI
          emit(ChatLoaded(messages: [botMsgUi, ...updatedMessages], isTyping: false));

        } catch (e) {
          // Handle Error
          emit(ChatLoaded(messages: updatedMessages, isTyping: false));
        }
      }
    });
  }
}