# Flutter-specific ProGuard rules
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Suppress warnings for Play Core (deferred components, not used)
-dontwarn com.google.android.play.core.**
