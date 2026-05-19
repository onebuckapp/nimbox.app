import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});
}

class ChatViewController {
  _ChatViewState? _state;
  void _attach(_ChatViewState state) => _state = state;
  void _detach() => _state = null;
  void sendMessage(String text, List<String> packages) => _state?._receiveMessage(text, packages);
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
  StreamController<String>? _streamController;
  bool _isStreaming = false;

  final List<String> _responseChunks = [
    '# AI Response\n\n',
    'Hello! I am your **AI assistant**. ',
    'How can I help you today?\n\n',
    'Feel free to ask me anything.',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _scrollController.dispose();
    _streamController?.close();
    super.dispose();
  }

  void _receiveMessage(String text, List<String> packages) {
    if (text.trim().isEmpty && packages.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom(); // Scroll to the bottom after adding a new message
    _startStreamingResponse();
  }


  Future<void> _startStreamingResponse() async {
    if (_isStreaming) return;

    setState(() {
      _isStreaming = true;
      _streamController = StreamController<String>();
      _messages.add(ChatMessage(text: '', isUser: false));
    });

    final buffer = StringBuffer(); // 👈 accumulate chunks

    for (final chunk in _responseChunks) {
      if (!mounted || _streamController == null) break;
      buffer.write(chunk); // 👈 keep track of full text
      _streamController!.add(chunk);
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (mounted) {
      final fullText = buffer.toString();
      setState(() {
        _isStreaming = false;
        _messages[_messages.length - 1] = ChatMessage(text: fullText, isUser: false);
      });
      await _streamController?.close();
      _streamController = null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent, // Scroll to the very bottom
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
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
      itemBuilder: (context, index) => _buildMessageRow(context, _messages[index], index),
    );
  }

  Widget _buildMessageRow(BuildContext context, ChatMessage message, int index) {
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

    final isStreamingMessage = index == _messages.length - 1 && _isStreaming && _streamController != null;

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
          child: isStreamingMessage
              ? StreamMarkdown(
                  stream: _streamController!.stream,
                  loadingWidget: const CircularProgressIndicator(),
                  styleSheet: MarkdownStyleSheet.dark(),
                )
              : message.isUser
                  ? Text(message.text)
                  :  SmoothMarkdown(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.dark(),
                    )
        ),
      ],
    );
  }
}