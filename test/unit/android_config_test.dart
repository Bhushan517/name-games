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

      // Sdk versions
      expect(content, contains('compileSdk = 36'));
      expect(content, contains('targetSdk = 36'));

      // Old references must not exist
      expect(content.contains('com.example.name_twist_game'), isFalse);

      // AdMob placeholders
      expect(
          content,
          contains(
              'manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"'));
      expect(
          content,
          contains(
              'manifestPlaceholders["adMobAppId"] = "ca-app-pub-4413496842954832~2239872257"'));

      // Release signing logic
      expect(content,
          contains('signingConfig = signingConfigs.getByName("release")'));
      expect(content,
          isNot(contains('signingConfig = signingConfigs.getByName("debug")')));

      // Missing key.properties logic
      expect(
          content,
          contains(
              'throw GradleException("android/key.properties is missing. Required for release builds.")'));
      expect(
          content,
          contains(
              'throw GradleException("storeFile is missing in key.properties")'));
      expect(
          content,
          contains(
              'throw GradleException("The configured keystore file does not exist: " + storeFilePath)'));
      expect(
          content,
          contains(
              'throw GradleException("storePassword is empty in key.properties")'));
      expect(
          content,
          contains(
              'throw GradleException("keyPassword is empty in key.properties")'));
      expect(
          content,
          contains(
              'throw GradleException("keyAlias is empty in key.properties")'));
      expect(
          content,
          contains(
              'val isReleaseBuild = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }'));
    });

    test('AndroidManifest.xml uses adMobAppId placeholder', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue,
          reason: 'AndroidManifest.xml must exist');

      final content = file.readAsStringSync();

      expect(content, contains('android:value="\${adMobAppId}"'));
      expect(
          content.contains('ca-app-pub-3940256099942544~3347511713'), isFalse,
          reason: 'Should not hardcode test ID in manifest');
    });

    test('MainActivity is in the correct directory', () {
      final oldDir =
          Directory('android/app/src/main/kotlin/com/example/name_twist_game');
      final newDir =
          Directory('android/app/src/main/kotlin/com/bhushanraut/wordspark');
      final mainActivity = File('${newDir.path}/MainActivity.kt');

      expect(oldDir.existsSync(), isFalse,
          reason: 'Old package directory should be deleted');
      expect(newDir.existsSync(), isTrue,
          reason: 'New package directory should exist');
      expect(mainActivity.existsSync(), isTrue,
          reason: 'MainActivity.kt should exist in new package');

      final content = mainActivity.readAsStringSync();
      expect(content, contains('package com.bhushanraut.wordspark'));
    });
  });
}
