# Ignorar warnings de clases opcionales de ML Kit Text Recognition (chino, japonés, coreano, devanagari)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Opcional: mantener todas las clases de ML Kit por si acaso (más seguro, pero app un poco más grande)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Regla general recomendada para google_ml_kit_flutter
-keep class com.google_mlkit_** { *; }