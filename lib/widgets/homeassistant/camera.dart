// camera.dart
import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class HomeAssistantCamera extends StatefulWidget {
  const HomeAssistantCamera({super.key, required this.streamUri, required this.aspectRatio});

  final Uri streamUri;
  final double aspectRatio;

  @override
  State<HomeAssistantCamera> createState() => _HomeAssistantCameraState();
}

class _HomeAssistantCameraState extends State<HomeAssistantCamera> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.streamUri.toString()));
    player.setVolume(0);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Video(
          controller: controller,
          controls: NoVideoControls,
          aspectRatio: widget.aspectRatio,
        ),
      ),
    );
  }
}
