import 'dart:io';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:smartclock/util/config.dart' show ConfigModel;

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  late List<String> log;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final configModel = context.read<ConfigModel>();
    final file = File(path.join(configModel.appDir.path, "logs.txt"));
    log = file.readAsLinesSync();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clock Logs"),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            controller: scrollController,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black, height: 1.5, fontFamily: "RobotoMono"),
                children: [
                  for (String line in log) ...[
                    TextSpan(text: line.substring(0, 36), style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "${line.substring(36)}\n"),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
