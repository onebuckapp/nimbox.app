/*
    Nimbox - The missing GUI for Nimble, Nim's package manager.

    Copyright (C) 2026  George Lemon from OpenPeeps

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:web_socket/web_socket.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final ValueNotifier<String> textNotifier;
  final ValueNotifier<bool> isStreamingNotifier;
  final StreamController<String>? _streamController;
  final Queue<String> _pendingChunks = Queue<String>();
  bool _isPumping = false;
  bool _isClosing = false;

  ChatMessage({required String text, required this.isUser, bool isStreaming = false})
      : id = DateTime.now().microsecondsSinceEpoch.toString(),
        textNotifier = ValueNotifier(text),
        isStreamingNotifier = ValueNotifier(isStreaming),
        _streamController = isStreaming ? StreamController<String>() : null {
    if (isStreaming) {
      if (text.isNotEmpty) _pendingChunks.add(text);
      _streamController!.onListen = _pumpChunks;
    }
  }

  bool get isStreaming => isStreamingNotifier.value;
  Stream<String>? get stream => _streamController?.stream;
  String get text => textNotifier.value;
  set text(String v) => textNotifier.value = v;

  void addChunk(String chunk) {
    text += chunk;
    _pendingChunks.add(chunk);
    _pumpChunks();
  }

  Future<void> _pumpChunks() async {
    if (_isPumping || _streamController == null) return;
    if (!_streamController!.hasListener) return;
    _isPumping = true;
    try {
      while (_pendingChunks.isNotEmpty) {
        if (_streamController!.isClosed) break;
        _streamController!.add(_pendingChunks.removeFirst());
        await Future.delayed(const Duration(milliseconds: 16));
      }
    } finally {
      _isPumping = false;
      if (_isClosing && _pendingChunks.isEmpty && !(_streamController?.isClosed ?? true)) {
        await _streamController!.close();
        isStreamingNotifier.value = false;
      }
    }
  }

  Future<void> closeStream() async {
    _isClosing = true;
    await _pumpChunks();
    if (_pendingChunks.isEmpty && !(_streamController?.isClosed ?? true)) {
      await _streamController!.close();
      isStreamingNotifier.value = false;
    }
  }

  void dispose() {
    textNotifier.dispose();
    isStreamingNotifier.dispose();
    _streamController?.close();
  }
}

class ChatViewController {
  _ChatViewState? _state;
  void _attach(_ChatViewState state) => _state = state;
  void _detach() => _state = null;

  void sendMessage(String text, [dynamic packages]) => _state?._sendMessage(text, packages);
}

class ChatView extends StatefulWidget {
  final ChatViewController? controller;
  const ChatView({Key? key, this.controller}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  WebSocket? _webSocket; // nullable instead of late + boolean flag
  int? _streamingIndex; // Track index of currently streaming message, if any
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _connectWebSocket();
  }

  @override
  void dispose() {
    for (final m in _messages) m.dispose();
    widget.controller?._detach();
    _scrollController.dispose();
    _webSocket?.close();
    super.dispose();
  }

  void _receiveChunk(String text) {
    // Check if the message is the JSON containing the session_id
    if (_sessionId == null) {
      try {
        final Map<String, dynamic> json = jsonDecode(text);
        if (json['event'] == 'connected' && json.containsKey('session_id')) {
          _sessionId = json['session_id'];
          print('[WS] Session ID received: $_sessionId');
          return;
        }
      } catch (e) {
        print('[WS] Failed to parse JSON: $e');
      }
    }

    print('Session $_sessionId received chunk: "$text"');
    // Check for the end message with the session_id
    if (text == '[END-${_sessionId ?? ''}]') {
      if (_streamingIndex != null) {
        final msg = _messages[_streamingIndex!];
        msg.closeStream(); // closes stream after flushing pending chunks
        setState(() {
          _streamingIndex = null;
        });
      }
      return;
    }

    print('Session $_sessionId processing chunk: "$text"');
    if (_streamingIndex == null) {
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: false, isStreaming: true));
        _streamingIndex = _messages.length - 1;
      });
    } else {
      _messages[_streamingIndex!].addChunk(text);
    }
  }

  void _connectWebSocket() async {
    try {
      final ws = await WebSocket.connect(Uri.parse('ws://127.0.0.1:8000/chat'));
      if (!mounted) return;
      setState(() => _webSocket = ws);

      ws.events.listen(
        (event) {
          switch (event) {
            case TextDataReceived(text: final text):
              _receiveChunk(text);
              break;
            case BinaryDataReceived():
              break;
            case CloseReceived(code: final code, reason: final reason):
              print('[WS] Connection closed: $code [$reason]');
              if (mounted) {
                setState(() { _webSocket = null; _streamingIndex = null; });
                _reconnectWebSocket();
              }
              break;
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() { _webSocket = null; _streamingIndex = null; });
            _reconnectWebSocket();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() { _webSocket = null; _streamingIndex = null; });
            _reconnectWebSocket();
          }
        },
      );
    } catch (e) {
      print('[WS] Connection failed: $e');
      if (mounted) {
        setState(() => _webSocket = null);
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      }
    }
  }
  
  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), _connectWebSocket); // Retry after delay
  }

  void _sendMessage(String text, [dynamic packages]) {
    final ws = _webSocket;
    // print('[WS] _sendMessage called. ws is null: ${ws == null}, text: "$text"');
    if (ws == null || text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    try {
      ws.sendText(text);
      // print('[WS] Message sent: $text');
    } catch (e) {
      print('[WS] Failed to send message: $e');
    }
  }


  void _receiveMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return Center(child: Text('Start a conversation…').muted);
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = _messages[index];
        return KeyedSubtree(
          key: ValueKey(message.id),
          child: _buildMessageRow(context, message),
        );
      },
    );
  }

  Widget _buildMessageRow(BuildContext context, ChatMessage message) {
    if (message.isUser) {
      return ChatGroup(
        color: Theme.of(context).colorScheme.secondary,
        alignment: AxisAlignmentDirectional.end,
        type: ChatBubbleType.tail.copyWith(position: () => AxisDirectional.end),
        children: [
          ChatBubble(widthFactor: 0.80, child: Text(message.text)),
        ],
      );
    }

    return ChatGroup(
      color: Colors.transparent,
      avatarPrefix: Card(
        borderRadius: BorderRadius.circular(19),
        padding: const EdgeInsets.all(4),
        child: Image.asset('assets/chatbox-1.png', width: 32, height: 32, fit: BoxFit.contain),
      ),
      alignment: AxisAlignmentDirectional.start,
      type: ChatBubbleType.tail.copyWith(
        position: () => AxisDirectional.start,
        tailAlignment: () => AxisAlignmentDirectional.end,
      ),
      children: [
        ChatBubble(
          widthFactor: 1,
          // Use stream != null (AI messages always have one) instead of isStreaming flag
          child: message.stream != null
              ? ValueListenableBuilder<bool>(
                  valueListenable: message.isStreamingNotifier,
                  builder: (context, isStreaming, _) {
                    if (!isStreaming) {
                      // Stream closed: render final static markdown
                      return SmoothMarkdown(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.dark(),
                      );
                    }
                    // StreamMarkdown is the ONLY listener of the stream
                    return StreamMarkdown(
                      stream: message.stream!,
                      styleSheet: MarkdownStyleSheet.dark(),
                      useEnhancedComponents: true,
                      loadingWidget: const SizedBox(
                        height: 24,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                      ),
                    );
                  },
                )
              : SmoothMarkdown(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.dark(),
                ),
        ),
      ],
    );
  }

}