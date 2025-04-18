import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/config/config.dart' show ConfigModel;

class SidebarCard extends StatelessWidget {
  const SidebarCard({super.key, required this.child, this.padding = true, this.margin = true});

  final bool margin;
  final bool padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return Container(
      margin: margin ? EdgeInsets.only(bottom: config.clock.padding) : null,
      padding: padding ? EdgeInsets.all(config.clock.padding) : null,
      decoration: BoxDecoration(
        color: config.sidebar.cardColor,
        borderRadius: BorderRadius.circular(config.sidebar.cardRadius),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
