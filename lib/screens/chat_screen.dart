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
    // 1. Get the current theme to determine Light or Dark mode
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => ChatBloc(
        RepositoryProvider.of<ChatRepository>(context),
      )..add(LoadChatHistory(currentUser.id.toString())),
      child: Scaffold(
        // 2. Removed hardcoded white/black colors so AppBar adapts automatically
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent),
              SizedBox(width: 8),
              Text("AI Assistant"),
            ],
          ),
          elevation: 1,
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoaded) {
              return DashChat(
                currentUser: ChatUser(id: currentUser.id.toString(), firstName: currentUser.name),
                messages: state.messages,
                onSend: (ChatMessage m) {
                  context.read<ChatBloc>().add(SendChatMessage(m));
                },
                typingUsers: state.isTyping ? [ChatUser(id: 'BOT', firstName: 'AI')] : [],

                // --- 3. ADDED INPUT OPTIONS TO FIX INVISIBLE TYPING TEXT ---
                inputOptions: InputOptions(
                  inputTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  inputDecoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    // Adapts background color of input field to light/dark mode
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    hintText: 'Write a message...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),

                messageOptions: MessageOptions(
                  messageTextBuilder: (message, previousMessage, nextMessage) {
                    if (message.user.id == 'BOT') {
                      return MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          // Adapts markdown text color
                          p: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                          code: TextStyle(
                            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }
                    return Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    );
                  },
                  // --- 4. ADAPTIVE BUBBLE COLORS ---
                  // Bot bubble: Dark grey in dark mode, light grey in light mode
                  containerColor: isDarkMode ? Colors.grey[850]! : Colors.grey[200]!,
                  // User bubble: Vibrant purple
                  currentUserContainerColor: const Color(0xFF6C63FF),
                  textColor: isDarkMode ? Colors.white : Colors.black87,
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}