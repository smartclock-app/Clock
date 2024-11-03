import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartclock/util/config.dart' show ConfigModel;

class SidebarCard extends StatelessWidget {
  const SidebarCard({super.key, required this.child, this.padding = true});

  final bool padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigModel>().config;

    return Container(
      margin: EdgeInsets.only(bottom: config.sidebar.cardSpacing),
      padding: padding ? EdgeInsets.all(config.sidebar.cardSpacing) : null,
      decoration: BoxDecoration(
        color: config.sidebar.cardColor,
        borderRadius: BorderRadius.circular(config.sidebar.cardRadius),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
