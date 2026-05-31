/// JSON Schema for [TutorResponse] used with OpenAI structured outputs.
///
/// Mirrors the freezed model exactly:
/// - `correction`: { content, translation, errors[] }
/// - `conversation`: { content, translation }
///
/// All properties are `required`, `additionalProperties: false`, so OpenAI's
/// strict mode rejects shapes that would fail [TutorResponse.fromJson].
const Map<String, dynamic> tutorResponseJsonSchema = <String, dynamic>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['correction', 'conversation'],
  'properties': {
    'correction': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['content', 'translation', 'errors'],
      'properties': {
        'content': {'type': 'string'},
        'translation': {'type': 'string'},
        'errors': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['original', 'corrected', 'explanation'],
            'properties': {
              'original': {'type': 'string'},
              'corrected': {'type': 'string'},
              'explanation': {'type': 'string'},
            },
          },
        },
      },
    },
    'conversation': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['content', 'translation'],
      'properties': {
        'content': {'type': 'string'},
        'translation': {'type': 'string'},
      },
    },
  },
};
