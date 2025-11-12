
import 'dart:async';
import 'dart:convert'; // For jsonEncode
import 'dart:io'; // For File

import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/models/chat_message.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/discussion_repository.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscussionScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final int clubId;

  const DiscussionScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.clubId,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  StompClient? _stompClient;
  StompUnsubscribe? _subscription;
  final List<ChatMessage> _messages = [];

  bool _isLoadingHistory = true;
  bool _isConnecting = true;
  bool _isUploading = false;
  String? _connectionError;

  User? _currentUser; // We'll get this from the AuthBloc

  @override
  void initState() {
    super.initState();
    // Get the current user from the AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
    }
    _loadHistoryAndConnect();
  }

  Future<void> _loadHistoryAndConnect() async {
    setState(() {
      _isLoadingHistory = true;
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      // Load message history first, using the clubId from the widget
      final history = await context.read<DiscussionRepository>().getMessageHistory(
        widget.clubId,
        widget.eventId,
      );

      setState(() {
        _messages.addAll(history);
        _isLoadingHistory = false;
      });
      _scrollToBottom();

      // 2. Now, connect to the WebSocket
      await _activateStompClient();

    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
        _isConnecting = false;
        _connectionError = "Failed to load chat: ${e.toString()}";
      });
    }
  }

  Future<void> _sendFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return; // User canceled the picker

    final PlatformFile platformFile = result.files.first;
    final File file = File(platformFile.path!);

    setState(() { _isUploading = true; });

    try {
      // 1. Upload the file to S3
      final fileUrl = await context.read<DiscussionRepository>().uploadFile(file);

      // 2. Send the file message via WebSocket
      final message = {
        'content': platformFile.name, // Send the original filename as the content
        'fileUrl': fileUrl,
        'messageType': 'FILE', // Use the 'FILE' type
      };

      _stompClient?.send(
        destination: '/app/chat.sendMessage/${widget.eventId}',
        body: jsonEncode(message),
      );

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  Future<void> _activateStompClient() async {
    final secureStorage = context.read<SecureStorageService>();
    final String? token = await secureStorage.getToken();
    final String websocketUrl = ApiService.websocketUrl; // e.g., 'ws://10.0.2.2:8080/ws'

    _stompClient = StompClient(
      config: StompConfig(
        url: websocketUrl,
        onConnect: _onStompConnected,
        onDisconnect: (frame) => debugPrint('STOMP Disconnected'),
        beforeConnect: () async {
          debugPrint('STOMP waiting to connect...');
        },
        onWebSocketError: (dynamic error) {
          debugPrint('STOMP WebSocket Error: $error');
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _connectionError = "Connection failed. Please try again.";
            });
          }
        },
        // This is where we pass our JWT token for security
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    debugPrint('STOMP Connected!');
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _connectionError = null;
      });
    }

    // Subscribe to the event topic to receive messages
    _subscription = _stompClient!.subscribe(
      destination: '/topic/event/${widget.eventId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final Map<String, dynamic> data = jsonDecode(frame.body!);
          final newMessage = ChatMessage.fromJson(data);

          // Add the new message to our list
          if (mounted) {
            setState(() {
              _messages.add(newMessage);
            });
            _scrollToBottom();
          }
        }
      },
    );
  }

  void _sendMessage() {
    final content = _textController.text;
    if (content.isEmpty) return;

    final message = {
      'content': content,
      'messageType': 'TEXT',
    };

    _stompClient?.send(
      destination: '/app/chat.sendMessage/${widget.eventId}',
      body: jsonEncode(message),
    );
    _textController.clear();
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() { _isUploading = true; });

    try {
      final file = File(image.path);
      // 1. Upload the file to S3 via our repository
      final fileUrl = await context.read<DiscussionRepository>().uploadFile(file);

      // 2. Send the file message via WebSocket
      final message = {
        'content': 'Sent an image',
        'fileUrl': fileUrl,
        'messageType': 'IMAGE',
      };

      _stompClient?.send(
        destination: '/app/chat.sendMessage/${widget.eventId}',
        body: jsonEncode(message),
      );

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.call();
    _stompClient?.deactivate();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingHistory) {
      return const Center(child: Text("Loading message history..."));
    }

    if (_connectionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_connectionError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistoryAndConnect,
                child: const Text('Retry Connection'),
              )
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(child: Text("No messages yet. Say hello!"));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final bool isMe = message.userId == _currentUser?.id;
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isMe ? Colors.white70 : theme.colorScheme.primary,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),

            // Show Image or Text or file
            if (message.messageType == 'IMAGE' && message.fileUrl != null)
              _buildImageMessage(message.fileUrl!)
            else if (message.messageType == 'FILE' && message.fileUrl != null)
              _buildFileMessage(message.content, message.fileUrl!) // 'content' holds the filename
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : theme.colorScheme.onSecondaryContainer,
                ),
              ),

            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.sentAt.toLocal()),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(String filename, String url) {
    // Wrap the file bubble in an InkWell to make it tappable
    return InkWell(
      onTap: () => _launchFileUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                filename,
                style: const TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline, // Make it look like a link
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    // Wrap the image in an InkWell to make it tappable
    return InkWell(
      onTap: () => _launchFileUrl(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 250,
          ),
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (context, url) => const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            // The constraints are now on the parent widget
          ),
        ),
      ),
    );
  }

  Future<void> _launchFileUrl(String url) async {
    final Uri uri = Uri.parse(url);
    // Use externalApplication mode to let the OS handle it (e.g., open Gallery, Browser, or PDF viewer)
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $url'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextInput() {
    if (_isConnecting) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text("Connecting to chat..."),
          ],
        ),
      );
    }

    if (_connectionError != null) {
      return const SizedBox.shrink(); // Hide input if connection failed
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              // Attach File Button
              icon: Icon(Icons.attach_file, color: Theme.of(context).hintColor),
              onPressed: _isUploading ? null : _sendFile,
            ),
            // Attach Image Button
            IconButton(
              icon: Icon(Icons.image_outlined, color: Theme.of(context).hintColor),
              onPressed: _isUploading ? null : _sendImage,
            ),
            // Text Field
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              )
            else
              FloatingActionButton(
                mini: true,
                onPressed: _sendMessage,
                child: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}