# R8 rules for the release build (minify + shrink).

# youtubedl-android reads yt-dlp's JSON into model classes by reflection (Jackson).
-keep class com.yausername.youtubedl_android.** { *; }
-keep class com.yausername.ffmpeg.** { *; }
-keepclassmembers class com.yausername.youtubedl_android.mapper.** { *; }
-dontwarn com.fasterxml.jackson.**
-dontwarn org.apache.commons.compress.**
-dontwarn org.tukaani.xz.**

# audio_service: the service and the media button receiver are named in the manifest.
-keep class com.ryanheise.audioservice.** { *; }

# Widget, tile and receivers are created by the system from the manifest.
-keep class com.codecore.player.** { *; }

# NewPipeExtractor (flavor full): rules of the NewPipe app (Rhino JS engine, timeago patterns loaded by reflection).
-keep class org.mozilla.javascript.** { *; }
-keep class org.mozilla.classfile.ClassFileWriter
-dontwarn org.mozilla.javascript.tools.**
-dontwarn javax.script.**
-dontwarn java.beans.**
-keep class org.schabi.newpipe.extractor.timeago.patterns.** { *; }
-dontwarn jdk.dynalink.**
