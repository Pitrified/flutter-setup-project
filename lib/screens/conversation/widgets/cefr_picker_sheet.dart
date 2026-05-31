import 'package:flutter/material.dart';

import '../../../models/cefr_level.dart';

/// Bottom sheet that lets the user pick a [CefrLevel].
///
/// Returns the selected level, or `null` if the user dismissed the sheet
/// without picking. The currently active level is marked with a check.
Future<CefrLevel?> showCefrPickerSheet(
  BuildContext context, {
  required CefrLevel current,
}) {
  return showModalBottomSheet<CefrLevel>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'CEFR level',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final level in CefrLevel.values)
            ListTile(
              title: Text(level.displayName),
              subtitle: Text(level.description),
              trailing: level == current
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(level),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
