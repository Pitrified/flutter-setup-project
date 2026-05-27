---
status: not-started
depends_on: [05_controllers/00_conversation_controller.md]
produces: [lib/screens/conversation/conversation_screen.dart, lib/widgets/message_bubble.dart, lib/widgets/correction_card.dart]
---

# Plan: Conversation Screen

## Goal

The main interaction surface. Displays message history, input field, and
structured correction cards. Connects to ConversationController via provider.

## Implementation

`lib/screens/conversation/conversation_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation_message.dart';
import '../../models/inference_status.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/inference_provider.dart';
import '../../widgets/correction_card.dart';
import '../../widgets/message_bubble.dart';

/// Main conversation screen - chat with the tutor.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    final controller = ref.read(conversationControllerProvider);
    if (controller.currentConversation == null) {
      await controller.startConversation();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    _textController.clear();
    setState(() => _sending = true);

    final controller = ref.read(conversationControllerProvider);
    await controller.sendMessage(text);

    setState(() => _sending = false);
    _scrollToBottom();
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(conversationControllerProvider);
    final messages = controller.currentConversation?.messages ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('fala')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ConversationMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageBubble(message: message),
        if (message.tutorResponse != null &&
            message.tutorResponse!.correction.errors.isNotEmpty)
          CorrectionCard(correction: message.tutorResponse!.correction),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type in Portuguese...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_sending,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
```

## Shared widgets

`lib/widgets/message_bubble.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/conversation_message.dart';

/// Chat bubble displaying a single message.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
```

`lib/widgets/correction_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/tutor_response.dart';

/// Card displaying grammar/vocabulary corrections.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({super.key, required this.correction});

  final CorrectionBlock correction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 16, right: 48, top: 4, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Corrections',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ...correction.errors.map((e) => _buildErrorItem(context, e)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorItem(BuildContext context, CorrectionError error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: error.original,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(text: ' -> '),
                TextSpan(
                  text: error.corrected,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Text(
            error.explanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
```

## Acceptance criteria

- [ ] Shows message history with user/tutor bubbles
- [ ] Input field with send button
- [ ] Loading state during inference
- [ ] Correction card shown below tutor messages with errors
- [ ] Auto-scrolls to bottom on new messages
- [ ] No direct service imports (uses providers only)
- [ ] `flutter analyze` passes
