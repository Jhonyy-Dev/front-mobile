import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_manager.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;
  final String thumbnailPath;
  final double opacity;

  const VideoBackground({
    super.key,
    required this.child,
    this.thumbnailPath = 'assets/medical-migration.webp',
    this.opacity = 0.15,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  final VideoManager _videoManager = VideoManager();

  @override
  Widget build(BuildContext context) {
    final controller = _videoManager.controller;
    final isVideoReady = _videoManager.isInitialized && controller != null;

    return Stack(
      children: [
        // Thumbnail (aparece INSTANTÁNEAMENTE)
        Positioned.fill(
          child: Image.asset(
            widget.thumbnailPath,
            fit: BoxFit.cover,
          ),
        ),
        
        // Video precargado (aparece INMEDIATAMENTE si ya está listo)
        if (isVideoReady)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        
        // Overlay oscuro
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(widget.opacity),
                  Colors.black.withOpacity(widget.opacity + 0.15),
                ],
              ),
            ),
          ),
        ),
        
        // Contenido
        widget.child,
      ],
    );
  }
}
