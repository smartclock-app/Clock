import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/config/config.dart' show ConfigModel;

class ErrorInfoWidget extends StatefulWidget {
  const ErrorInfoWidget({super.key, required this.title, required this.message, this.stack});

  final String title;
  final String message;
  final String? stack;

  @override
  State<ErrorInfoWidget> createState() => _ErrorInfoWidgetState();
}

class _ErrorInfoWidgetState extends State<ErrorInfoWidget> {
  bool showStack = false;

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return SidebarCard(
      child: GestureDetector(
        onTap: () => setState(() => showStack = !showStack),
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
                widget.title,
                style: TextStyle(fontSize: config.sidebar.titleSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                widget.message,
                style: TextStyle(fontSize: config.sidebar.headingSize),
                textAlign: TextAlign.center,
              ),
              if (showStack && widget.stack != null) ...[
                const SizedBox(height: 16),
                Text(widget.stack!),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
