import 'package:flutter/material.dart';

import '../../../models/topic.dart';

/// Bottom sheet for picking a [Topic].
///
/// Layout: a `TextField` at the top with an "Apply" button for a custom topic,
/// then a scrollable list of [kSuggestedTopics]. Returns the picked [Topic],
/// or `null` if the user dismissed the sheet.
Future<Topic?> showTopicPickerSheet(
  BuildContext context, {
  required Topic current,
}) {
  return showModalBottomSheet<Topic>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _TopicPickerBody(current: current),
    ),
  );
}

class _TopicPickerBody extends StatefulWidget {
  const _TopicPickerBody({required this.current});

  final Topic current;

  @override
  State<_TopicPickerBody> createState() => _TopicPickerBodyState();
}

class _TopicPickerBodyState extends State<_TopicPickerBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current.isCustom ? widget.current.value : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    Navigator.of(context).pop(Topic(value: raw, isCustom: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Pick a topic', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Custom topic',
                        hintText: 'e.g. ciclismo',
                      ),
                      onSubmitted: (_) => _apply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            if (!widget.current.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(Topic.none),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear topic'),
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: kSuggestedTopics.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = kSuggestedTopics[index];
                  final isSelected = t == widget.current;
                  return ListTile(
                    title: Text(t.value),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.of(context).pop(t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
