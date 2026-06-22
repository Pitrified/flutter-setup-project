import 'package:flutter/material.dart';

import '../../../models/tutor_response.dart';
import 'streaming_reply_view.dart';

/// Displays tutor corrections below a message.
///
/// Shows each error with strikethrough original, bold corrected form, and
/// explanation text. Works for both committed corrections ([CorrectionCard])
/// and live, partially-streamed ones ([CorrectionCard.partial]) - in the
/// partial case any leaf may be absent yet, so rows render a skeleton until
/// their data arrives and only draw the strike->replace once both [original]
/// and [corrected] exist.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({super.key, required List<CorrectionError> this.corrections})
      : partials = null;

  /// Live, partially-streamed corrections (phase 6).
  const CorrectionCard.partial({super.key, required List<PartialCorrection> this.partials})
      : corrections = null;

  final List<CorrectionError>? corrections;
  final List<PartialCorrection>? partials;

  List<_Row> get _rows {
    final committed = corrections;
    if (committed != null) {
      return [
        for (final e in committed)
          _Row(
            original: e.original,
            corrected: e.corrected,
            explanation: e.explanation,
            closed: true,
          ),
      ];
    }
    return [
      for (final e in partials!)
        _Row(
          original: e.original,
          corrected: e.corrected,
          explanation: e.explanation,
          closed: e.closed,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = _rows;

    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++)
            KeyedSubtree(
              key: ValueKey(i),
              child: _buildRow(context, rows[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _Row row) {
    final original = row.original;
    final corrected = row.corrected;
    final explanation = row.explanation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: _buildDiff(context, original, corrected),
          ),
          if (explanation != null && explanation.isNotEmpty)
            Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          else if (!row.closed)
            // Explanation not arrived yet for an in-progress row.
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _skeleton(context, width: 140),
            ),
        ],
      ),
    );
  }

  /// The strike->replace line. Only drawn once both [original] and [corrected]
  /// are present (a half value would mislead); otherwise a skeleton stands in.
  Widget _buildDiff(BuildContext context, String? original, String? corrected) {
    if (original == null || original.isEmpty) {
      return _skeleton(context, width: 100);
    }
    if (corrected == null || corrected.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            original,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.red,
            ),
          ),
          const Text(' -> '),
          _skeleton(context, width: 60),
        ],
      );
    }
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: original,
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.red,
            ),
          ),
          const TextSpan(text: ' -> '),
          TextSpan(
            text: corrected,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(BuildContext context, {required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Normalized correction row used for rendering both committed and partial.
class _Row {
  const _Row({
    this.original,
    this.corrected,
    this.explanation,
    required this.closed,
  });

  final String? original;
  final String? corrected;
  final String? explanation;
  final bool closed;
}
