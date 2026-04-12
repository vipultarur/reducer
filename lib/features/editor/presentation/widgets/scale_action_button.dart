import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reducer/core/theme/design_tokens.dart';

class ScaleActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ScaleActionButton({super.key, required this.icon, this.onTap});

  @override
  State<ScaleActionButton> createState() => _ScaleActionButtonState();
}

class _ScaleActionButtonState extends State<ScaleActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (widget.onTap != null && _isHolding) {
        widget.onTap!();
        _pulseController.reverse().then((_) => _pulseController.forward());
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isHolding = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          _isHolding = true;
          widget.onTap!();
          _pulseController.reverse();
          // Initial delay before auto-repeat
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _isHolding && _timer == null) {
              _startTimer();
            }
          });
        }
      },
      onTapUp: (_) {
        _stopTimer();
        _pulseController.forward();
      },
      onTapCancel: () {
        _stopTimer();
        _pulseController.forward();
      },
      child: ScaleTransition(
        scale: _pulseController,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.onTap != null
                ? DesignTokens.primaryBlue.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: widget.onTap != null
                ? Border.all(
                    color: DesignTokens.primaryBlue.withValues(alpha: 0.2),
                    width: 1.5)
                : null,
          ),
          child: Icon(
            widget.icon,
            color:
                widget.onTap != null ? DesignTokens.primaryBlue : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}
