# Flutter-specific ProGuard rules
# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the app's MainActivity (referenced only from AndroidManifest.xml)
-keep class com.fala.app.MainActivity { *; }

# Keep annotations
-keepattributes *Annotation*

# Suppress warnings for Play Core (deferred components, not used)
-dontwarn com.google.android.play.core.**

# MediaPipe proto classes referenced reflectively but not bundled
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
