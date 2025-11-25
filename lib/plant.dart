import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, File;
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import 'safedatetime.dart';

class Plant {
  String? name;
  String? desc;
  DateTime? expiration;
  DateTime? startDate;
  PlantKind? kind;
  String? prizeDescription;
  RewardType? rewardType;
  

  Map<Weekday, bool>? weekdaySelection;
  bool? wateredToday;

  int? numTimes;
  DurationType? duration;
  int? numCompletedPerDuration;

  TimingOption? timingOption;

  // scale of 1 to 0
  double health = 1;

  Plant();

  //static Map<String, Plant> allPlants = Map();
  factory Plant.fromMap(Map<String, dynamic> plantData) {
    return Plant()
      ..name = plantData['name'] as String?
      ..desc = plantData['desc'] as String?
      ..expiration = plantData['expiration'] != null
        ? DateTime.parse(plantData['expiration'] as String)
        : null
      ..kind = plantData['kind'] != null
        ? PlantKind.plantFromPrettyName(plantData['kind'] as String)
        : null
      ..prizeDescription = plantData['prizeDescription'] as String?
      ..weekdaySelection = plantData['weekdaySelection'] != null
        ? (plantData['weekdaySelection'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
          Weekday.values.firstWhere((e) => e.name == key),
          value as bool,
          ),
        )
        : null
      ..numTimes = plantData['numTimes'] as int?
      ..duration = plantData['duration'] != null
        ? DurationType.values.firstWhere(
          (e) => e.prettyName == plantData['duration'],
          orElse: () => DurationType.day,
        )
        : null
      ..timingOption = plantData['timingOption'] != null
        ? TimingOption.values.firstWhere(
          (e) => e.name == plantData['timingOption'],
          orElse: () => TimingOption.daysOfTheWeek,
        )
        : null
      ..startDate = plantData['startDate'] != null
        ? DateTime.parse(plantData['startDate'] as String)
        : null
      ..wateredToday = plantData['wateredToday'] as bool?
      ..numCompletedPerDuration = plantData['numCompletedPerDuration'] as int?
      ..health = plantData['health'] != null
        ? (plantData['health'] as num).toDouble()
        : 1
      ..rewardType = plantData['rewardType'] != null
        ? RewardType.values.firstWhere(
          (e) => e.name == plantData['rewardType'],
          orElse: () => RewardType.message,
        )
        : RewardType.message;
    }

  double getProgress() {
    if (startDate == null || expiration == null) {
      return 0.0;
    }

    final now = SafeDateTime.now();
    if (now.isBefore(startDate!) || now.isAfter(expiration!)) {
      return 0.0;
    }

    final totalDuration = expiration!.difference(startDate!).inMilliseconds;
    final elapsedDuration = now.difference(startDate!).inMilliseconds;

    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }

  void shareLink() {
    final url =
        'https://laithali004.github.io/rooting-reward/?habit=${Uri.encodeComponent(this.desc ?? '')}&time=${Uri.encodeComponent(DateFormat('MM-dd-yy').format(this.expiration!))}';

    if (Platform.isLinux) {
      final Uri uri = Uri.parse(url);
      launchUrl(uri);
    } else {
      SharePlus.instance.share(
        ShareParams(
          text: "Your friend wants your help to stay in rootine! ${url}",
        ),
      );
    }
  }

  bool needsWater() {
    if (timingOption == TimingOption.daysOfTheWeek) {
      if (wateredToday!) {
        return false;
      }
      final currentDay = SafeDateTime.now().weekday;
      final weekday = Weekday.values[currentDay - 1];
      return weekdaySelection?[weekday] ?? false;
    } else {
      if (numTimes! < numCompletedPerDuration!) {
        return true;
      }
      return false;
    }
  }

  bool waterPlant() {
    bool success = false;
    if (timingOption == TimingOption.daysOfTheWeek && needsWater()) {
      wateredToday = true;
      success = true;
    } else if (timingOption == TimingOption.numTimesPerDuration && needsWater()) {
      numTimes = (numTimes ?? 0) + 1;
      success = true;
    }
    if (success) {
      health = (health + 0.1).clamp(0.0, 1.0);
    }
    return success;
  }

  void undoWaterPlant() {
    if (timingOption == TimingOption.daysOfTheWeek) {
      print("setting wateredToday to false");
      wateredToday = false;
    } else if (timingOption == TimingOption.numTimesPerDuration) {
      numCompletedPerDuration = (numCompletedPerDuration ?? 0) > 0
          ? numCompletedPerDuration! - 1
          : 0;
    }
    health = (health - 0.1).clamp(0.0, 1.0);
  }
  
  Future<void> extractRootineFile(File file) async {
    if (!file.path.endsWith('.rootine')) {
      throw ArgumentError('File must have a .rootine extension');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final Map<String, List<int>> fileData = {};
    for (final file in archive) {
      if (file.isFile) {
        fileData[file.name] = file.content as List<int>;
      }
    }

    // Now `fileData` contains the extracted file names and their bytes
    if (fileData.containsKey('meta.json')) {
      final metaJsonBytes = fileData['meta.json']!;
      final metaJsonString = String.fromCharCodes(metaJsonBytes);
      final Map<String, dynamic> metaData = Map<String, dynamic>.from(
      jsonDecode(metaJsonString) as Map,
      );

      // Now `metaData` contains the parsed JSON data from "meta.json"
      if (metaData.containsKey('rewardType')) {
        final rewardTypeString = metaData['rewardType'] as String;
        this.rewardType = RewardType.values.firstWhere(
          (e) => e.name == rewardTypeString,
          orElse: () => RewardType.message,
        );
      }
      switch (rewardType) {
        case RewardType.drawing:
          if (fileData.containsKey('drawing.png')) {
        final drawingBytes = fileData['drawing.png']!;
        this.prizeDescription = base64Encode(drawingBytes);
          }
          break;
        case RewardType.gift:
          if (fileData.containsKey('gift_code.txt')) {
        final giftCodeBytes = fileData['gift_code.txt']!;
        this.prizeDescription = String.fromCharCodes(giftCodeBytes);
          }
          break;
        case RewardType.message:
          if (fileData.containsKey('message.txt')) {
        final messageBytes = fileData['message.txt']!;
        this.prizeDescription = String.fromCharCodes(messageBytes);
          }
          break;
        default:
          print("wtf");
      }

    } else {
      throw Exception('meta.json not found in the archive');
    }
    print("Successfully imported file");
    print(prizeDescription);
    
  }
}

enum PlantKind {
  fern(prettyName: "Fern", numSketches: 3),
  daisy(prettyName: "Daisy", numSketches: 3),
  tree(prettyName: "Tree", numSketches: 3);

  final String prettyName;
  final int numSketches;

  const PlantKind({required this.prettyName, required this.numSketches});

  static PlantKind plantFromPrettyName(String prettyName) {
    for (PlantKind k in PlantKind.values) {
      if (prettyName == k.prettyName) {
        return k;
      }
    }
    return PlantKind.values.first;
  }
}

enum RewardType {
  gift,
  message,
  drawing
}

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

enum DurationType {
  day(prettyName: "Day", numDays: 1),
  week(prettyName: "Week", numDays: 7),
  month(prettyName: "Month", numDays: 31);

  final String prettyName;
  final int numDays;

  Duration toDuration() {
    return Duration(days: numDays);
  }

  const DurationType({required this.prettyName, required this.numDays});
}

enum TimingOption { daysOfTheWeek, numTimesPerDuration }
