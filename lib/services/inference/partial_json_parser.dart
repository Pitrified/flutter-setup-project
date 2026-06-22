/// Tolerant, incremental JSON parser for streamed LLM output.
///
/// [PartialJsonParser.parse] takes the *whole* cumulative text buffer seen so
/// far (not a delta) and returns a best-effort [PartialJsonResult]: the
/// partially-decoded `Map<String, dynamic>` plus a parallel [JsonClosure] tree
/// marking which nodes were terminated by a real `]` / `}` / `"` in the input
/// versus left open (still streaming, i.e. would only be closed by synthesizing
/// the terminator at end-of-input).
///
/// The parser is schema-agnostic - it knows nothing about `TutorResponse` - and
/// has no Flutter or network dependencies, so it is fully unit-testable in
/// isolation. Re-parsing the entire buffer each tick is intentional: it is
/// simple and fast enough for our document sizes (optimize only if profiling
/// says so).
///
/// Boundary with [JsonExtractor]: that extractor is whole-document (handles
/// closing ``` fences and `{..}` substring selection) and stays the parser for
/// the *final* message. This parser handles the *streaming* path, reading the
/// raw buffer directly. It locates the first `{` (skipping any leading prose or
/// the opening of a markdown fence) and parses an object from there; the
/// closing fence and trailing prose are end-of-document concerns that have not
/// arrived yet mid-stream.
library;

/// Result of a single tolerant parse of a cumulative buffer.
class PartialJsonResult {
  const PartialJsonResult({required this.value, required this.closure});

  /// Best-effort decoded object. Absent keys are simply absent; a mid-token
  /// string leaf is exposed as its prefix so far; a value whose key has a colon
  /// but no value yet is `null`.
  final Map<String, dynamic> value;

  /// Per-node closed-flags mirroring [value]. Use it to tell when an array has
  /// stopped growing and when an element / string is final.
  final JsonClosure closure;
}

/// Closed-flags for one JSON node and (for containers) its children.
///
/// [closed] is `true` only when the node was terminated by a real `]` / `}` /
/// `"` (or a complete literal/number) in the input, and `false` while the node
/// is still streaming.
class JsonClosure {
  const JsonClosure({
    required this.closed,
    this.fields = const {},
    this.elements = const [],
  });

  /// An open (not-yet-closed) leaf with no children.
  const JsonClosure.open()
      : closed = false,
        fields = const {},
        elements = const [];

  /// Whether a real terminator for this node has been seen in the input.
  final bool closed;

  /// Closed-flags for an object's values, keyed by property name.
  final Map<String, JsonClosure> fields;

  /// Closed-flags for an array's elements, in order.
  final List<JsonClosure> elements;

  /// Closed-flags for the object value at [key], or null if absent.
  JsonClosure? field(String key) => fields[key];

  /// Closed-flags for the array element at [index], or null if out of range.
  JsonClosure? element(int index) =>
      index >= 0 && index < elements.length ? elements[index] : null;
}

/// Stateless, tolerant parser. Construct once (it is `const`) and reuse.
class PartialJsonParser {
  const PartialJsonParser();

  /// Parse the cumulative [buffer] into a best-effort map plus closed-flags.
  PartialJsonResult parse(String buffer) {
    final start = buffer.indexOf('{');
    if (start == -1) {
      return const PartialJsonResult(
        value: <String, dynamic>{},
        closure: JsonClosure.open(),
      );
    }
    final scanner = _Scanner(buffer, start);
    final (value, closure) = scanner.parseObject();
    return PartialJsonResult(
      value: (value as Map<String, dynamic>?) ?? const <String, dynamic>{},
      closure: closure,
    );
  }
}

/// Single-pass recursive-descent scanner over one buffer. Mutates [i] as it
/// consumes characters; every parse method tolerates truncation at any point.
class _Scanner {
  _Scanner(this.s, this.i);

  final String s;
  int i;

  bool get _atEnd => i >= s.length;

  void _skipWs() {
    while (!_atEnd) {
      final c = s[i];
      if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
        i++;
      } else {
        break;
      }
    }
  }

  (dynamic, JsonClosure) _parseValue() {
    _skipWs();
    if (_atEnd) return (null, const JsonClosure.open());
    final c = s[i];
    switch (c) {
      case '{':
        return parseObject();
      case '[':
        return _parseArray();
      case '"':
        return _parseString();
      case 't':
      case 'f':
      case 'n':
        return _parseKeyword();
      default:
        final code = c.codeUnitAt(0);
        if (c == '-' || (code >= 0x30 && code <= 0x39)) {
          return _parseNumber();
        }
        // Unrecognized token: nothing usable.
        return (null, const JsonClosure.open());
    }
  }

  (dynamic, JsonClosure) parseObject() {
    i++; // consume '{'
    final map = <String, dynamic>{};
    final fields = <String, JsonClosure>{};
    while (true) {
      _skipWs();
      if (_atEnd) return (map, JsonClosure(closed: false, fields: fields));
      final c = s[i];
      if (c == '}') {
        i++;
        return (map, JsonClosure(closed: true, fields: fields));
      }
      if (c == ',') {
        i++; // tolerate stray / trailing comma
        continue;
      }
      if (c != '"') {
        // Unexpected token where a key was expected; stop tolerantly.
        return (map, JsonClosure(closed: false, fields: fields));
      }
      final (keyValue, _) = _parseString();
      final key = keyValue as String;
      _skipWs();
      if (_atEnd || s[i] != ':') {
        // Key seen but no colon/value yet: do not commit the key.
        return (map, JsonClosure(closed: false, fields: fields));
      }
      i++; // consume ':'
      final (value, closure) = _parseValue();
      map[key] = value;
      fields[key] = closure;
      _skipWs();
      if (_atEnd) return (map, JsonClosure(closed: false, fields: fields));
      final sep = s[i];
      if (sep == ',') {
        i++;
        continue;
      }
      if (sep == '}') {
        i++;
        return (map, JsonClosure(closed: true, fields: fields));
      }
      // Unexpected separator; stop tolerantly.
      return (map, JsonClosure(closed: false, fields: fields));
    }
  }

  (dynamic, JsonClosure) _parseArray() {
    i++; // consume '['
    final list = <dynamic>[];
    final elements = <JsonClosure>[];
    while (true) {
      _skipWs();
      if (_atEnd) return (list, JsonClosure(closed: false, elements: elements));
      final c = s[i];
      if (c == ']') {
        i++;
        return (list, JsonClosure(closed: true, elements: elements));
      }
      if (c == ',') {
        i++;
        continue;
      }
      final (value, closure) = _parseValue();
      list.add(value);
      elements.add(closure);
      _skipWs();
      if (_atEnd) return (list, JsonClosure(closed: false, elements: elements));
      final sep = s[i];
      if (sep == ',') {
        i++;
        continue;
      }
      if (sep == ']') {
        i++;
        return (list, JsonClosure(closed: true, elements: elements));
      }
      // Unexpected separator; stop tolerantly.
      return (list, JsonClosure(closed: false, elements: elements));
    }
  }

  (dynamic, JsonClosure) _parseString() {
    i++; // consume opening '"'
    final buf = StringBuffer();
    while (!_atEnd) {
      final c = s[i];
      if (c == r'\') {
        i++;
        if (_atEnd) {
          // Dangling escape at end-of-input: drop it, keep the prefix.
          return (buf.toString(), const JsonClosure.open());
        }
        final e = s[i];
        switch (e) {
          case '"':
            buf.write('"');
          case r'\':
            buf.write(r'\');
          case '/':
            buf.write('/');
          case 'b':
            buf.write('\b');
          case 'f':
            buf.write('\f');
          case 'n':
            buf.write('\n');
          case 'r':
            buf.write('\r');
          case 't':
            buf.write('\t');
          case 'u':
            // A unicode escape needs exactly 4 hex digits after the 'u'.
            if (i + 5 > s.length) {
              // Incomplete escape at end-of-input: drop it, keep the prefix.
              return (buf.toString(), const JsonClosure.open());
            }
            final hex = s.substring(i + 1, i + 5);
            final code = int.tryParse(hex, radix: 16);
            if (code == null) {
              // Malformed; emit the 'u' literally and continue tolerantly.
              buf.write('u');
              i++;
              continue;
            }
            buf.writeCharCode(code);
            i += 5; // 'u' + 4 hex digits
            continue;
          default:
            buf.write(e); // unknown escape: emit literally
        }
        i++;
        continue;
      }
      if (c == '"') {
        i++;
        return (buf.toString(), const JsonClosure(closed: true));
      }
      buf.write(c);
      i++;
    }
    // End-of-input before the closing quote: unterminated, expose the prefix.
    return (buf.toString(), const JsonClosure.open());
  }

  (dynamic, JsonClosure) _parseNumber() {
    final start = i;
    while (!_atEnd) {
      final c = s[i];
      final code = c.codeUnitAt(0);
      if (c == '-' ||
          c == '+' ||
          c == '.' ||
          c == 'e' ||
          c == 'E' ||
          (code >= 0x30 && code <= 0x39)) {
        i++;
      } else {
        break;
      }
    }
    final raw = s.substring(start, i);
    // Stopping at a real delimiter (not end-of-input) means the token is whole;
    // stopping at end-of-input means more digits could still arrive.
    final closed = !_atEnd;
    return (_parseNumberPrefix(raw), JsonClosure(closed: closed));
  }

  /// Longest parseable numeric prefix of [raw] (handles mid-token `12.`, `1e`).
  num? _parseNumberPrefix(String raw) {
    var candidate = raw;
    while (candidate.isNotEmpty) {
      final parsed = num.tryParse(candidate);
      if (parsed != null) return parsed;
      candidate = candidate.substring(0, candidate.length - 1);
    }
    return null;
  }

  (dynamic, JsonClosure) _parseKeyword() {
    const keywords = <String, dynamic>{
      'true': true,
      'false': false,
      'null': null,
    };
    for (final entry in keywords.entries) {
      if (s.startsWith(entry.key, i)) {
        i += entry.key.length;
        return (entry.value, const JsonClosure(closed: true));
      }
    }
    // A truncated prefix of a literal at end-of-input: value is unknown until it
    // completes, so expose null and leave it open.
    final remaining = s.substring(i);
    for (final word in keywords.keys) {
      if (remaining.isNotEmpty && word.startsWith(remaining)) {
        i = s.length;
        return (null, const JsonClosure.open());
      }
    }
    return (null, const JsonClosure.open());
  }
}
