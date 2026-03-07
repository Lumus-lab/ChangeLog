# ObjectBox rules
-keep class io.objectbox.relation.ToOne { *; }
-keep class io.objectbox.relation.ToMany { *; }
-keep class io.objectbox.relation.Order { *; }
-keep class io.objectbox.Box { *; }
-keep class io.objectbox.BoxStore { *; }
-keep class io.objectbox.Cursor { *; }
-keep class io.objectbox.Query { *; }
-keep class io.objectbox.Transaction { *; }
-keep class io.objectbox.internal.** { *; }
-keep class * extends io.objectbox.relation.ToOne
-keep class * extends io.objectbox.relation.ToMany

# Keep your model classes
-keep class com.lumus.changelog.models.** { *; }

# Flutter and standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# JNI / Native
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers class * extends android.app.Activity {
   public void *(android.view.View);
}
-keep class * extends android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

