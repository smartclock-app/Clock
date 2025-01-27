import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'package:smartclock/config/config.dart' show ConfigModel, Config;
import 'package:smartclock/util/event_utils.dart';
import 'package:smartclock/util/logger_util.dart';
import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/widgets/updater/install_apk.dart';

class Updater extends StatefulWidget {
  const Updater({super.key});

  @override
  State<Updater> createState() => _UpdaterState();
}

class _UpdaterState extends State<Updater> {
  Map<String, dynamic>? updateInfo;
  bool updateInProgress = false;
  String updateDismissed = "";
  double _progressValue = 0.0;
  StreamSubscription<ClockEvent>? _subscription;
  late Config config;
  Logger logger = LoggerUtil.logger;

  bool semverCompare(String versionA, String versionB) {
    final a = versionA.split(".").map(int.parse).toList();
    final b = versionB.split(".").map(int.parse).toList();

    for (var i = 0; i < a.length; i++) {
      if (a[i] > b[i]) {
        return true;
      } else if (a[i] < b[i]) {
        return false;
      }
    }

    return false;
  }

  void checkForUpdates() async {
    logger.i("[Updater] Checking for updates");
    const url = "https://api.github.com/repos/smartclock-app/Clock/releases/latest";

    final response = await Dio().get(
      url,
      options: Options(headers: {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      }),
    );
    final latest = response.data;

    final currentVersion = Config.version;
    final latestVersion = latest["tag_name"].toString().substring(1);

    if (semverCompare(latestVersion, currentVersion)) {
      logger.i("[Updater] Update available: v$currentVersion -> $latestVersion");
      setState(() => updateInfo = latest);
    } else {
      logger.i("[Updater] No updates available");
      setState(() => updateInfo = null);
    }
  }

  void onDownloadProgress(int received, int total) {
    setState(() {
      _progressValue = received / total;
    });
  }

  void installCallback(String message) {
    setState(() {
      updateInProgress = false;
      _progressValue = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    config = context.read<ConfigModel>().config;
    checkForUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = context.read<StreamController<ClockEvent>>().stream;
    _subscription?.cancel();
    _subscription = stream.listen((event) {
      if (event.event == ClockEvents.refetch && event.time.second == 0 && event.time.minute % 5 == 0) {
        checkForUpdates();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (updateInfo == null || updateDismissed == updateInfo?['name']) return const SizedBox.shrink();

    if (updateInProgress) {
      return SidebarCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xfff8f8f8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                "Downloading Update",
                style: TextStyle(fontSize: config.sidebar.titleSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progressValue),
            ],
          ),
        ),
      );
    } else {
      return SidebarCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xfff8f8f8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                "v${Config.version} -> ${updateInfo!['name']}",
                style: TextStyle(fontSize: config.sidebar.titleSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (Platform.isAndroid) ...[
                FilledButton(
                  onPressed: () {
                    setState(() {
                      updateInProgress = true;
                    });
                    final List<dynamic> assets = updateInfo!['assets'];
                    final apk = assets.firstWhere((e) => (e['name'] as String).endsWith(".apk"));
                    final url = apk['url'];
                    installApk(url: url, onDownloadProgress: onDownloadProgress, callback: installCallback);
                  },
                  child: Text("Download Update", style: TextStyle(fontSize: config.sidebar.headingSize)),
                ),
              ],
              FilledButton(
                onPressed: () {
                  setState(() {
                    updateDismissed = updateInfo!['name'];
                  });
                },
                child: Text("Skip", style: TextStyle(fontSize: config.sidebar.subheadingSize)),
              ),
            ],
          ),
        ),
      );
    }
  }
}
