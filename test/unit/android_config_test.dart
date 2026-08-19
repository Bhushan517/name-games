import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Config Tests', () {
    test('build.gradle.kts has correct package and configurations', () {
      final file = File('android/app/build.gradle.kts');
      expect(file.existsSync(), isTrue, reason: 'build.gradle.kts must exist');
      
      final content = file.readAsStringSync();
      
      // Package ID assertions
      expect(content, contains('namespace = "com.bhushanraut.wordspark"'));
      expect(content, contains('applicationId = "com.bhushanraut.wordspark"'));
      
      // Old references must not exist
      expect(content.contains('com.example.name_twist_game'), isFalse);
      
      // AdMob placeholders
      expect(content, contains('manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"'));
      expect(content, contains('manifestPlaceholders["adMobAppId"] = "ca-app-pub-4413496842954832~2239872257"'));
      
      // Release signing
      expect(content, contains('signingConfig = signingConfigs.getByName("release")'));
    });

    test('AndroidManifest.xml uses adMobAppId placeholder', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');
      
      final content = file.readAsStringSync();
      
      expect(content, contains('android:value="\${adMobAppId}"'));
      expect(content.contains('ca-app-pub-3940256099942544~3347511713'), isFalse, reason: 'Should not hardcode test ID in manifest');
    });

    test('MainActivity is in the correct directory', () {
      final oldDir = Directory('android/app/src/main/kotlin/com/example/name_twist_game');
      final newDir = Directory('android/app/src/main/kotlin/com/bhushanraut/wordspark');
      final mainActivity = File('${newDir.path}/MainActivity.kt');

      expect(oldDir.existsSync(), isFalse, reason: 'Old package directory should be deleted');
      expect(newDir.existsSync(), isTrue, reason: 'New package directory should exist');
      expect(mainActivity.existsSync(), isTrue, reason: 'MainActivity.kt should exist in new package');

      final content = mainActivity.readAsStringSync();
      expect(content, contains('package com.bhushanraut.wordspark'));
    });
  });
}
