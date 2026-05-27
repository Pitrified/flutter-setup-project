# versions

please do a sanity check on android version supported. is 14 api 36 recent enough for llm apis we plan to use? do a web search for this. and the minimum release api, 8, too low? then use tool #askQuestions to gather additional feedback for next steps. thanks

---

## Answer

### Correction: Android 14 = API 34, not 36

| Android version | API level | Released |
|-----------------|-----------|----------|
| Android 16 | 36 | 2025 |
| Android 15 | 35 | 2024 |
| Android 14 | 34 | 2023 |

Our docs currently say "Target Android 14 (API 34)" for development.

### Target SDK should be 35+

Google Play requires `targetSdk 35+` for new apps and updates since **August 31, 2025**.
We must compile/target API 35 (Android 15) or 36 (Android 16) to submit to the Play Store.

**Recommendation:** target API 36 (Android 16, latest stable as of May 2026).

### Minimum SDK: API 26 (Android 8) is safe but academic

- API 26 covers 94.8% of active devices
- The LLM inference libraries (MediaPipe/LiteRT-LM) do not specify a hard minimum SDK higher than 26
- Jetpack/AndroidX requires minSdk 23+ (we are above this)
- **However:** no device running Android 8 has the hardware to run a 1B model (those are 2017-era phones with 2-4 GB RAM)
- The practical floor is 2022 flagships (Snapdragon 8 Gen 1, 8 GB RAM) which ship with Android 12+ (API 31+)

**Options:**

| minSdk | Android version | Practical effect |
|--------|-----------------|------------------|
| 26 | 8.0 (2017) | Safe default, no users excluded that could actually run the model. More "compatible" on paper. |
| 28 | 9.0 (2018) | Same practical effect, slightly cleaner (drops Oreo quirks) |
| 31 | 12 (2021) | Matches the realistic device floor. Drops ~20% of Play Store devices on paper, but those devices can't run the model anyway. |

**Recommendation:** keep minSdk 26 (no harm, maximum compatibility surface area).
The model download screen can show a hardware warning for underpowered devices.
Raising it later is trivial and non-breaking.

### Summary of changes needed in docs

| Setting | Current (wrong) | Corrected |
|---------|-----------------|-----------|
| Target/compile SDK | API 34 (Android 14) | API 36 (Android 16) |
| minSdk | API 26 (Android 8) | API 26 (keep as-is) |
| Development emulator | API 34 | API 36 |

### LLM SDK compatibility

MediaPipe LLM Inference API (which flutter_gemma wraps) states it is
"optimized for high-end Android devices such as Pixel 8 and Samsung S23 or later."
No hard API level floor is documented beyond standard Android SDK requirements.
API 36 as target is fully compatible.