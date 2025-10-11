import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoManager {
  static final VideoManager _instance = VideoManager._internal();
  factory VideoManager() => _instance;
  VideoManager._internal();

  VideoPlayerController? _controller;
  bool _isInitialized = false;

  VideoPlayerController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_controller != null) return; // Ya inicializado

    try {
      _controller = VideoPlayerController.asset(
        'assets/fondo.mp4',
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Inicializar sin await para no bloquear
      await _controller!.initialize();
      
      // Configuración optimizada
      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      _controller!.play();
      
      _isInitialized = true;
      debugPrint('✅ Video listo - Reproducción optimizada');
    } catch (e) {
      debugPrint('❌ Error video: $e');
      _isInitialized = false;
    }
  }

  void pause() {
    _controller?.pause();
  }

  void resume() {
    if (_controller != null && !_controller!.value.isPlaying) {
      _controller!.play();
    }
  }

  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
