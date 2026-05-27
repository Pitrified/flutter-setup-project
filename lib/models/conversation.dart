import 'package:freezed_annotation/freezed_annotation.dart';

import 'conversation_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// A conversation session between user and tutor.
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<ConversationMessage> messages,
    @Default('pt-BR') String language,
    @Default('A1') String cefrLevel,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
