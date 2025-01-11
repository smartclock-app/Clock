import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartclock/widgets/sidebar/sidebar_card.dart';
import 'package:smartclock/config/config.dart' show ConfigModel;

class InfoWidget extends StatelessWidget {
  const InfoWidget({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

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
              title,
              style: TextStyle(fontSize: config.sidebar.titleSize, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: config.sidebar.headingSize),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
