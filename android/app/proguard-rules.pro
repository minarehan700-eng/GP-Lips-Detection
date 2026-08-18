# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# MediaPipe (tasks + framework + JNI)
-keep class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }
-keep class com.google.mediapipe.framework.** { *; }
-keep class com.google.mediapipe.formats.** { *; }
-keep class com.google.protobuf.** { *; }
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# App bridge
-keep class com.example.lips_offline.FaceLandmarkerBridge { *; }
-keep class com.example.lips_offline.MainActivity { *; }

# Auto-value annotation processor (compile-time only, safe to ignore at runtime)
-dontwarn javax.annotation.processing.AbstractProcessor
-dontwarn javax.annotation.processing.SupportedAnnotationTypes
-dontwarn javax.lang.model.SourceVersion
-dontwarn javax.lang.model.element.Element
-dontwarn javax.lang.model.element.ElementKind
-dontwarn javax.lang.model.element.Modifier
-dontwarn javax.lang.model.type.TypeMirror
-dontwarn javax.lang.model.type.TypeVisitor
-dontwarn javax.lang.model.util.SimpleTypeVisitor8

# javax.annotation (not bundled on Android)
-dontwarn javax.annotation.**

# Flutter Play Store deferred components (not used in this app)
-dontwarn com.google.android.play.core.**

# MediaPipe proto (optional profiling/template classes)
-dontwarn com.google.mediapipe.proto.**
