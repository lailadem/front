import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/chat_message.dart';
import '../../models/session.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Session session;

  const ChatScreen({super.key, required this.session});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  late types.User _user;
  bool _isLoading = true;
  String? _error;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = types.User(
      id: authProvider.user?.id.toString() ?? '0',
      firstName: authProvider.user?.name,
    );
    _loadMessages();
    _initPusher();
  }

  @override
  void dispose() {
    _pusher.unsubscribe(channelName: 'session.${widget.session.id}');
    _pusher.disconnect();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService().getMessages(widget.session.id);
      if (result['success']) {
        final messagesData = result['messages'] as List;
        final messages = messagesData.map((msg) {
          final chatMessage = ChatMessage.fromJson(msg as Map<String, dynamic>);
          return types.TextMessage(
            author: types.User(
              id: chatMessage.senderId.toString(),
              firstName: chatMessage.senderName,
            ),
            createdAt:
                DateTime.parse(chatMessage.createdAt).millisecondsSinceEpoch,
            id: chatMessage.id.toString(),
            text: chatMessage.message,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _messages = messages;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = result['message'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initPusher() async {
    try {
      await _pusher.init(
        apiKey: '60a2c9e41232573996d8',
        cluster: 'ap2',
        onEvent: _onPusherEvent,
      );
      await _pusher.subscribe(channelName: 'session.${widget.session.id}');
      await _pusher.connect();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Pusher connection error: $e';
        });
      }
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName == 'App\\Events\\NewMessage') {
      final data = json.decode(event.data);
      final messageData = data['message'] as Map<String, dynamic>;
      final newChatMessage = ChatMessage.fromJson(messageData);

      // Avoid adding duplicate message if user is the sender
      if (newChatMessage.senderId.toString() == _user.id) {
        return;
      }

      final newMessage = types.TextMessage(
        author: types.User(
          id: newChatMessage.senderId.toString(),
          firstName: newChatMessage.senderName,
        ),
        createdAt:
            DateTime.parse(newChatMessage.createdAt).millisecondsSinceEpoch,
        id: newChatMessage.id.toString(),
        text: newChatMessage.message,
      );

      _addMessage(newMessage);
    }
  }

  void _addMessage(types.Message message) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSubmitted(types.PartialText message) async {
    final text = message.text;
    if (text.trim().isEmpty) return;

    final optimisticMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(), // Temporary UUID
      text: text,
      status: types.Status.sending,
    );

    _addMessage(optimisticMessage);

    try {
      final result = await ApiService().sendMessage(widget.session.id, text);

      if (result['success']) {
        // The API service now correctly returns the message object under the 'data' key.
        final sentMessage = result['data'] as ChatMessage;

        final newTextMessage = types.TextMessage(
          author: types.User(
            id: sentMessage.senderId.toString(),
            firstName: sentMessage.senderName,
          ),
          createdAt:
              DateTime.parse(sentMessage.createdAt).millisecondsSinceEpoch,
          id: sentMessage.id.toString(),
          text: sentMessage.message,
          status: types.Status.sent,
        );
        _replaceMessage(optimisticMessage.id, newTextMessage);
      } else {
        _updateMessageStatus(optimisticMessage.id, types.Status.error);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to send message: ${result['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      _updateMessageStatus(optimisticMessage.id, types.Status.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _replaceMessage(String oldId, types.Message newTextMessage) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == oldId);
      if (index != -1) {
        _messages[index] = newTextMessage;
      }
    });
  }

  void _updateMessageStatus(String messageId, types.Status status) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final oldMessage = _messages[index] as types.TextMessage;
        _messages[index] = oldMessage.copyWith(status: status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isProfessional = authProvider.user?.role == 'professional';

    // Determine the other user's name for the chat title
    final otherUserName = isProfessional
        ? widget.session.client?.name ?? 'Client'
        : widget.session.professional?.name ?? 'Professional';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $otherUserName'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $_error', textAlign: TextAlign.center),
                ))
              : Chat(
                  messages: _messages,
                  onSendPressed: _handleSubmitted,
                  user: _user,
                  showUserAvatars: true,
                  showUserNames: true,
                  theme: DefaultChatTheme(
                    primaryColor: Colors.deepPurple.shade300,
                    sentMessageBodyTextStyle:
                        const TextStyle(color: Colors.black),
                    inputBackgroundColor: Colors.grey[200]!,
                    inputTextColor: Colors.black,
                    inputTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
    );
  }
}
