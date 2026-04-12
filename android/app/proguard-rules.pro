# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services / Firebase
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Iconsax / Icons
-keep class com.iconsax.** { *; }

# Prevent shrinking of reflective calls used by plugins
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
-ignorewarnings
