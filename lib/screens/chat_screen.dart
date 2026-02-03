import 'package:connectedu_app/bloc/chat_bloc.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/chat_repository.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatelessWidget {
  final User currentUser;

  const ChatScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        RepositoryProvider.of<ChatRepository>(context),
      )..add(LoadChatHistory(currentUser.id.toString())), // <--- UPDATED LINE
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent),
              SizedBox(width: 8),
              Text("AI Assistant"),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoaded) {
              return DashChat(
                // Ensure this ID matches what you passed in LoadChatHistory
                currentUser: ChatUser(id: currentUser.id.toString(), firstName: currentUser.name),
                messages: state.messages,
                onSend: (ChatMessage m) {
                  context.read<ChatBloc>().add(SendChatMessage(m));
                },
                typingUsers: state.isTyping ? [ChatUser(id: 'BOT', firstName: 'AI')] : [],

                messageOptions: MessageOptions(
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    if (message.user.id == 'BOT') {
                      return MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.black87, fontSize: 16),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          code: TextStyle(backgroundColor: Colors.grey[200], color: Colors.black),
                        ),
                      );
                    }
                    return Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    );
                  },
                  containerColor: const Color(0xFF6C63FF),
                  currentUserContainerColor: Colors.black87,
                  textColor: Colors.white,
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
              );
            }
            // Show loading spinner while fetching history
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}