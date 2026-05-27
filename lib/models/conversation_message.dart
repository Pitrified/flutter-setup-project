import 'package:freezed_annotation/freezed_annotation.dart';

import 'tutor_response.dart';

part 'conversation_message.freezed.dart';
part 'conversation_message.g.dart';

/// Role of a message sender.
enum MessageRole {
  user,
  tutor,
  system,
}

/// A single message in a conversation.
@freezed
abstract class ConversationMessage with _$ConversationMessage {
  const factory ConversationMessage({
    required String id,
    required MessageRole role,
    required String content,
    required DateTime timestamp,
    TutorResponse? tutorResponse,
  }) = _ConversationMessage;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$ConversationMessageFromJson(json);
}
