# Shrinker rules for the release build.

# Camera text reading (google_mlkit_text_recognition) refers to the Chinese,
# Devanagari, Japanese and Korean readers, which are optional and not in the
# app: only the Latin one is, for IMEIs and serial numbers. Without these
# lines R8 stops the build on the missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
