import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

class HomeAssistantCamera extends StatefulWidget {
  const HomeAssistantCamera({super.key, required this.streamUri, required this.aspectRatio});

  final Uri streamUri;
  final double aspectRatio;

  @override
  State<HomeAssistantCamera> createState() => _HomeAssistantCameraState();
}

class _HomeAssistantCameraState extends State<HomeAssistantCamera> {
  late ChewieController _chewieController;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.streamUri);
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: widget.aspectRatio,
      autoPlay: true,
      showControls: false,
    );
    _chewieController.setVolume(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Chewie(controller: _chewieController),
      ),
    );
  }
}
