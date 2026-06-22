import '../../../models/conversation_message.dart';
import '../../../models/tutor_response.dart';
import '../../../services/inference/partial_json_parser.dart';
import '../../../services/inference/structured_stream_engine.dart';

/// A single correction row as it streams in: any leaf may be absent yet, and
/// [closed] is true once the element's object is finalized (phase-1 flag).
class PartialCorrection {
  const PartialCorrection({
    this.original,
    this.corrected,
    this.explanation,
    this.closed = false,
  });

  final String? original;
  final String? corrected;
  final String? explanation;
  final bool closed;
}

/// Thin, nullable-returning accessor over a streaming
/// [StructuredDelta]`<TutorResponse>`'s best-effort map (G1).
///
/// This is the *only* place that knows the `TutorResponse` field paths for the
/// streaming UI; it does not reintroduce a hand-written partial mirror type.
class StreamingReplyView {
  const StreamingReplyView(this.delta);

  final StructuredDelta<TutorResponse> delta;

  Map<String, dynamic>? get _correction =>
      delta.partial['correction'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _conversation =>
      delta.partial['conversation'] as Map<String, dynamic>?;

  /// The tutor's conversational reply text so far (prefix while streaming).
  String? get conversationContent => _conversation?['content'] as String?;

  /// The translation of the reply (often arrives last).
  String? get conversationTranslation =>
      _conversation?['translation'] as String?;

  /// The corrected full sentence so far.
  String? get correctionContent => _correction?['content'] as String?;

  /// Whether the corrections array has stopped growing (no more rows coming).
  bool get correctionsClosed =>
      delta.closure.field('correction')?.field('errors')?.closed ?? false;

  /// Correction rows seen so far (length = elements-so-far, last may be open).
  List<PartialCorrection> get corrections {
    final errors = _correction?['errors'] as List<dynamic>?;
    if (errors == null) return const [];
    final errorsClosure = delta.closure.field('correction')?.field('errors');
    return [
      for (var i = 0; i < errors.length; i++)
        _partialFrom(errors[i], errorsClosure?.element(i)),
    ];
  }

  PartialCorrection _partialFrom(Object? raw, JsonClosure? closure) {
    final map = raw as Map<String, dynamic>?;
    return PartialCorrection(
      original: map?['original'] as String?,
      corrected: map?['corrected'] as String?,
      explanation: map?['explanation'] as String?,
      closed: closure?.closed ?? false,
    );
  }
}

/// Whether to show the live streaming overlay row.
///
/// Shown only while a send is in flight *and* the last committed message is the
/// user's - so the instant the tutor message is committed (last role becomes
/// tutor) the overlay disappears in the same rebuild that adds the committed
/// bubble. That makes the handoff duplicate-free with no gap.
bool showStreamingOverlay({
  required bool isSending,
  required List<ConversationMessage> messages,
}) {
  if (!isSending || messages.isEmpty) return false;
  return messages.last.role == MessageRole.user;
}
