## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.firebase.** { *; }

## Google Play Services
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.internal.** { *; }

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

## OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

## AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-keep class androidx.core.app.CoreComponentFactory { *; }
-dontwarn androidx.**

## Evitar problemas con Android 14
-keep class android.app.Application { *; }
-keep class android.app.Activity { *; }
