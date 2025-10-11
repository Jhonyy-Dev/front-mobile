import 'package:flutter/material.dart';

/// Widget reutilizable para animación slide-up con fade-in
/// 
/// Anima el contenido hijo desde abajo hacia arriba con un efecto de fade-in simultáneo.
/// Ideal para pantallas de login, formularios, o cualquier contenido que requiera
/// una entrada animada elegante.
class SlideUpAnimation extends StatefulWidget {
  /// El widget hijo que será animado
  final Widget child;
  
  /// Duración de la animación en milisegundos (default: 600ms)
  final int durationMs;
  
  /// Desplazamiento inicial vertical (default: 0.3 = 30% de la pantalla)
  final double initialOffset;
  
  /// Curva de animación (default: Curves.easeOutCubic)
  final Curve curve;
  
  /// Delay antes de iniciar la animación en milisegundos (default: 0ms)
  final int delayMs;

  const SlideUpAnimation({
    super.key,
    required this.child,
    this.durationMs = 900,
    this.initialOffset = 0.6,
    this.curve = Curves.easeOut,
    this.delayMs = 0,
  });

  @override
  State<SlideUpAnimation> createState() => _SlideUpAnimationState();
}

class _SlideUpAnimationState extends State<SlideUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.initialOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Iniciar animación con delay opcional
    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
