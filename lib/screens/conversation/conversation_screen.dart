import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/cefr_level.dart';
import '../../models/conversation.dart';
import '../../models/conversation_message.dart';
import '../../models/topic.dart';
import '../../models/tutor_response.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/conversation/conversation_controller.dart';
import '../../services/inference/structured_stream_engine.dart';
import 'widgets/cefr_picker_sheet.dart';
import 'widgets/correction_card.dart';
import 'widgets/message_bubble.dart';
import 'widgets/streaming_reply_view.dart';
import 'widgets/streaming_tutor_entry.dart';
import 'widgets/topic_picker_sheet.dart';
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
      await controller.startConversation(
        cefrLevel: ref.read(defaultCefrLevelProvider),
        topic: ref.read(defaultTopicProvider),
      );
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
      appBar: AppBar(
        title: const Text('fala'),
        actions: [
          _TopicAction(controller: controller),
          _CefrAction(controller: controller),
        ],
      ),
      drawer: const _AppDrawer(),
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
                return _buildMessageList(controller, conversation.messages);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    ConversationController controller,
    List<ConversationMessage> messages,
  ) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Say something in Portuguese!'),
      );
    }

    final showOverlay = showStreamingOverlay(
      isSending: _isSending,
      messages: messages,
    );

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (showOverlay ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildStreamingOverlay(controller);
        }
        final message = messages[index];
        final errors = message.tutorResponse?.correction.errors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Corrections annotate the user's message, so they render above the
            // tutor reply (consistent with the live streaming order).
            if (errors != null && errors.isNotEmpty)
              CorrectionCard(corrections: errors),
            MessageBubble(message: message),
          ],
        );
      },
    );
  }

  /// The live in-flight tutor entry. Shows the typing indicator until the first
  /// delta arrives, then the partial-tolerant bubble + corrections.
  Widget _buildStreamingOverlay(ConversationController controller) {
    return StreamBuilder<StructuredDelta<TutorResponse>>(
      stream: controller.streamingReply,
      builder: (context, snapshot) {
        final delta = snapshot.data;
        if (delta == null) return const TypingIndicator();
        final view = StreamingReplyView(delta);
        final hasContent = (view.conversationContent ?? '').isNotEmpty ||
            view.corrections.isNotEmpty;
        if (!hasContent) return const TypingIndicator();
        return StreamingTutorEntry(delta: delta);
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                'fala',
                style: TextStyle(fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CefrAction extends ConsumerWidget {
  const _CefrAction({required this.controller});

  final ConversationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Conversation?>(
      stream: controller.conversationStream,
      initialData: controller.currentConversation,
      builder: (context, snapshot) {
        final current =
            CefrLevelX.fromString(snapshot.data?.cefrLevel) ?? CefrLevel.a1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: ActionChip(
            label: Text(current.displayName),
            tooltip: 'CEFR level: ${current.description}',
            onPressed: () async {
              final picked = await showCefrPickerSheet(
                context,
                current: current,
              );
              if (picked == null || picked == current) return;
              await controller.setCefrLevel(picked);
              await ref
                  .read(defaultCefrLevelProvider.notifier)
                  .select(picked);
            },
          ),
        );
      },
    );
  }
}

class _TopicAction extends ConsumerWidget {
  const _TopicAction({required this.controller});

  final ConversationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Conversation?>(
      stream: controller.conversationStream,
      initialData: controller.currentConversation,
      builder: (context, snapshot) {
        final raw = snapshot.data?.topic ?? '';
        final current = raw.isEmpty
            ? Topic.none
            : Topic(value: raw, isCustom: !_isSuggested(raw));
        final label = raw.isEmpty
            ? 'Pick a topic'
            : raw.length > 18
                ? '${raw.substring(0, 17)}\u2026'
                : raw;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: Text(label),
            onPressed: () async {
              final picked = await showTopicPickerSheet(
                context,
                current: current,
              );
              if (picked == null) return;
              await controller.setTopic(picked.value);
              await ref
                  .read(defaultTopicProvider.notifier)
                  .select(picked.value);
            },
          ),
        );
      },
    );
  }

  bool _isSuggested(String value) =>
      kSuggestedTopics.any((t) => t.value == value);
}
