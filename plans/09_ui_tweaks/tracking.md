# Ui tweaks - implementation tracking

Small UI and functionality fixes, one sub-plan each, from tap-to-reveal translation to the
CEFR picker to how an unparseable reply reads. Open: item 08 in the list has no sub-plan yet.

This folder ran before `tracking.md` was the convention, so this file was written during the
normalisation pass in
[`../21_plans_query_skill/02_normalisation.md`](../21_plans_query_skill/02_normalisation.md). The table
is the phase files as they stand; the log is what `plans/00_tracking.md` recorded before it was deleted.

Analysis and decisions in [`00_start.md`](00_start.md).

## Phases

| #  | Phase | Plan | Status |
| -- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------ |
| 01 | 01 - Show translation on tap                                               | [`01_show_translation.md`](01_show_translation.md)                           | done |
| 02 | 02 - CEFR level indicator and picker                                       | [`02_cefr_level_picker.md`](02_cefr_level_picker.md)                         | done |
| 03 | 03 - Topic suggestions and picker                                          | [`03_topic_picker.md`](03_topic_picker.md)                                   | done |
| 04 | 04 - Scroll to bottom                                                      | [`04_scroll_to_bottom.md`](04_scroll_to_bottom.md)                           | done |
| 05 | 05 - Higher, wrapping input field                                          | [`05_higher_input_field.md`](05_higher_input_field.md)                       | done |
| 06 | 06 - New conversation button                                               | [`06_new_conversation_button.md`](06_new_conversation_button.md)             | done |
| 07 | 07 - Engine selection: correct model name, OpenAI default, scoped settings | [`07_engine_selection.md`](07_engine_selection.md)                           | done |
| 09 | 09 - Split CEFR text into guidance + description                           | [`09_cefr_guidance_and_description.md`](09_cefr_guidance_and_description.md) | done |
| 10 | 10 - A malformed reply reads as a failed turn, not as the tutor talking    | [`10_malformed_reply_display.md`](10_malformed_reply_display.md)             | done |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-07-15 : items 01 to 03 executed (translation, CEFR picker, topic picker).
- 2026-08-02 : items 04 to 07 and 09 executed (scroll-to-bottom, taller input, new-conversation button, engine selection, CEFR guidance).
- 2026-09-25 : item 10, an unparseable reply now reads as a failed turn rather than as the tutor writing English prose.
- 2026-09-25 : item 08 in the list, long corrections not wrapping while streaming, has no sub-plan; this folder stays in progress until it does.
