import 'package:flutter/material.dart';

import '../../../models/conversation_message.dart';

/// Chat bubble displaying a single conversation message.
///
/// User messages align right with primary color; tutor messages align left
/// with surface color. Tutor messages that carry a translation in
/// [ConversationMessage.tutorResponse] toggle a smaller, dimmer translation
/// line under the original reply when tapped.
class MessageBubble extends StatefulWidget {
  const MessageBubble({super.key, required this.message});

  final ConversationMessage message;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final translation = message.tutorResponse?.conversation.translation ?? '';
    final canToggle = !isUser && translation.isNotEmpty;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: TextStyle(
              color: isUser
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: canToggle && _showTranslation
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      translation,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: canToggle
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showTranslation = !_showTranslation),
              child: bubble,
            )
          : bubble,
    );
  }
}
