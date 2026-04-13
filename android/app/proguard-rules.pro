# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services / Firebase - Only keep essential classes
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }

# Allow shrinking of common libraries while keeping reflective access safe
-keep class com.google.android.gms.internal.** { <fields>; <methods>; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# Prevent shrinking of reflective calls used by plugins
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
-ignorewarnings
