import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../providers/conversation_provider.dart';
import 'widgets/correction_card.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

/// Conversation screen - main chat interface.
///
/// Displays message history, input field, and tutor corrections.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    final controller = ref.read(conversationControllerProvider);
    if (controller == null) return;
    if (controller.currentConversation == null) {
      await controller.startConversation();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    final controller = ref.read(conversationControllerProvider);
    await controller?.sendMessage(text);

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(conversationControllerProvider);

    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('fala')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Conversation?>(
              stream: controller.conversationStream,
              initialData: controller.currentConversation,
              builder: (context, snapshot) {
                final conversation = snapshot.data;
                if (conversation == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildMessageList(conversation.messages);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ConversationMessage> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Say something in Portuguese!'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const TypingIndicator();
        }
        final message = messages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageBubble(message: message),
            if (message.tutorResponse?.correction.errors != null &&
                message.tutorResponse!.correction.errors.isNotEmpty)
              CorrectionCard(
                corrections: message.tutorResponse!.correction.errors,
              ),
          ],
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type in Portuguese...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
