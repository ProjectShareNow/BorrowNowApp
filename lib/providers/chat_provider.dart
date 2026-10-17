import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/service_registry.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatModel> _chats = [];
  List<MessageModel> _currentMessages = [];
  ChatModel? _activeChat;
  bool _isSending = false;
  String? _errorMessage;

  StreamSubscription? _chatsSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _activeChatSub;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get currentMessages => _currentMessages;
  ChatModel? get activeChat => _activeChat;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  void listenToUserChats(String userId) {
    _chatsSub?.cancel();
    _chatsSub = ServiceRegistry.chatService.getUserChatsStream(userId).listen((
      list,
    ) {
      _chats = list;
      notifyListeners();
    });
  }

  void listenToChat(String chatId) {
    _activeChatSub?.cancel();
    _activeChat = null;
    _activeChatSub = ServiceRegistry.chatService.getChatStream(chatId).listen((
      chat,
    ) {
      _activeChat = chat;
      notifyListeners();
    });
  }

  void listenToMessages(String chatId) {
    _messagesSub?.cancel();
    _currentMessages = [];
    _messagesSub = ServiceRegistry.chatService.getMessagesStream(chatId).listen((
      list,
    ) {
      _currentMessages = list;
      notifyListeners();
    });
  }

  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String? recipientId,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ServiceRegistry.chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        recipientId: recipientId,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await ServiceRegistry.chatService.markMessagesAsRead(
      chatId: chatId,
      currentUserId: userId,
    );
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _messagesSub?.cancel();
    _activeChatSub?.cancel();
    super.dispose();
  }
}
