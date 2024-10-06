import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart' show Config;

class InfoWidget extends StatelessWidget {
  const InfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<Config>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f8f8),
        borderRadius: BorderRadius.circular(10),
      ),
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
              "Widgets",
              style: TextStyle(fontSize: config.calendar.monthTitleSize, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "No widgets enabled.\n\nYou can enable widgets in the conf file.\n\nTo hide this message, enable at least one widget, or disable the sidebar.",
              style: TextStyle(fontSize: config.calendar.eventTimeSize),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
