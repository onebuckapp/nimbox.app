import 'package:shadcn_flutter/shadcn_flutter.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? avatarInitials;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.avatarInitials,
  });
}

//
// ChatView
//
class ChatView extends StatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  final List<ChatMessage> _messages = const [
    ChatMessage(
      text: 'Chatbox is up and running! How can I assist you today?',
      isUser: false,
    ),
    ChatMessage(
      text: 'Can you explain how BinaryExponentialBackoff works?',
      isUser: true,
    ),
    ChatMessage(
      text: 'Binary Exponential Backoff is a strategy used to manage retries in network communication. When a request fails, instead of retrying immediately, the system waits for a certain amount of time before trying again. The wait time increases exponentially with each subsequent failure, which helps to reduce network congestion and improve overall performance.',
      isUser: false,
    ),
    ChatMessage(
      text: 'John, did you remember what time you took the call with Mrs. Smith?',
      isUser: true,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageRow(context, message);
      },
    );
  }

  Widget _buildMessageRow(BuildContext context, ChatMessage message) {
    if (message.isUser) {
      return ChatGroup(
        color: Theme.of(context).colorScheme.secondary,
        alignment: AxisAlignmentDirectional.end,
        type: ChatBubbleType.tail.copyWith(
          position: () => AxisDirectional.end,
        ),
        children: [
          ChatBubble(widthFactor: 0.80, child: Text(message.text)),
        ],
      );
    }

    return ChatGroup(
      color: Colors.transparent,
      avatarPrefix: 
        Card(
          borderRadius: BorderRadius.circular(19),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/chatbox-1.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      alignment: AxisAlignmentDirectional.start,
      type: ChatBubbleType.tail.copyWith(
        position: () => AxisDirectional.start,
        tailAlignment: () => AxisAlignmentDirectional.end,
      ),
      children: [
        ChatBubble(widthFactor: 1, child: Text(message.text)),
      ],
    );
  }
}