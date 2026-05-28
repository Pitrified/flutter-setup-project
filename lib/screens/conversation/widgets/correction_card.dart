import 'package:flutter/material.dart';

import '../../../models/tutor_response.dart';

/// Displays tutor corrections below a message.
///
/// Shows each error with strikethrough original, bold corrected form,
/// and explanation text.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({super.key, required this.corrections});

  final List<CorrectionError> corrections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        children: corrections.map(_buildCorrectionItem).toList(),
      ),
    );
  }

  Widget _buildCorrectionItem(CorrectionError error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: error.original,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(text: ' -> '),
                TextSpan(
                  text: error.corrected,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Text(
            error.explanation,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
