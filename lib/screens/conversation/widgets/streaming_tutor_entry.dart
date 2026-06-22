import 'package:flutter/material.dart';

import '../../../models/tutor_response.dart';
import '../../../services/inference/structured_stream_engine.dart';
import 'correction_card.dart';
import 'message_bubble.dart';
import 'streaming_reply_view.dart';

/// The live tutor entry rendered while a turn streams in.
///
/// Binds a single in-flight [StructuredDelta] to a partial-tolerant
/// [MessageBubble] plus [CorrectionCard]: the reply text grows token by token
/// and each correction row appears as its array element arrives, filling in
/// live. Only this entry rebuilds per delta - the committed [ListView] items do
/// not.
class StreamingTutorEntry extends StatelessWidget {
  const StreamingTutorEntry({super.key, required this.delta});

  final StructuredDelta<TutorResponse> delta;

  @override
  Widget build(BuildContext context) {
    final view = StreamingReplyView(delta);
    final corrections = view.corrections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageBubble.streaming(
          content: view.conversationContent ?? '',
          translation: view.conversationTranslation,
        ),
        if (corrections.isNotEmpty)
          CorrectionCard.partial(partials: corrections),
      ],
    );
  }
}
