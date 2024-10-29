import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:neoglot/language_enum.dart';
import './multi_ripple_painter.dart';

enum ButtonState {
  idle,
  recording,
  pausing,
  playing,
}

class AudioButton extends StatefulWidget {
  final LanguageEnum language;
  final VoidCallback? onPressed;

  const AudioButton({
    super.key,
    required this.language,
    required this.onPressed,
  });

  @override
  _AudioButtonState createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> with TickerProviderStateMixin {
  late AnimationController _progressController;
  final List<Ripple> _ripples = [];
  late Ticker _rippleTicker;
  Timer? _rippleTimer;
  Timer? _pauseTimer;

  ButtonState _buttonState = ButtonState.idle;
  double _lastProgressValue = 0.0;

  @override
  void initState() {
    super.initState();

    // 进度条动画控制器
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressController.addListener(() {
      _lastProgressValue = _progressController.value;
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_buttonState == ButtonState.playing) {
          _stopRippleAnimation();
        }
        if (_buttonState != ButtonState.recording) {
          setState(() {
            _buttonState = ButtonState.recording;
          });
          _startRippleAnimation(true);
          // 触发录音开始的回调
          widget.onPressed?.call();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (_buttonState == ButtonState.recording) {
          setState(() {
            _buttonState = ButtonState.pausing;
          });
          // 停止录音波纹动画
          _stopRippleAnimation();
          // 暂停1秒
          _pauseTimer = Timer(const Duration(seconds: 1), () {
            setState(() {
              _buttonState = ButtonState.playing;
            });
            _startRippleAnimation(false);
          });
        }
      }
    });

    // 初始化波纹生成器
    _rippleTicker = createTicker((Duration elapsed) {
      setState(() {
        // 移除已完成的波纹
        _ripples.removeWhere((ripple) {
          if (!ripple.controller.isAnimating) {
            ripple.dispose();
            return true;
          }
          return false;
        });
        // 如果没有活跃的波纹，且不在需要波纹的状态，停止 Ticker
        if (_ripples.isEmpty && _buttonState != ButtonState.recording && _buttonState != ButtonState.playing) {
          if (_rippleTicker.isActive) {
            _rippleTicker.stop();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rippleTicker.dispose();
    _rippleTimer?.cancel();
    _pauseTimer?.cancel();
    for (var ripple in _ripples) {
      ripple.dispose();
    }
    super.dispose();
  }

  // 播放波纹动画，inward向内
  void _startRippleAnimation(bool inward) {
    // 启动 Ticker
    if (!_rippleTicker.isActive) {
      _rippleTicker.start();
    }

    // 定期生成波纹
    _addRipple(inward);
    const rippleInterval = Duration(seconds: 1);
    _rippleTimer = Timer.periodic(rippleInterval, (timer) {
      _addRipple(inward);
    });
  }

  void _addRipple(bool inward) {
    if (_buttonState == ButtonState.recording || _buttonState == ButtonState.playing) {
      setState(() {
        _ripples.add(Ripple(
          vsync: this,
          duration: const Duration(seconds: 3),
          inward: inward,
        ));
      });
    } else {
      _rippleTimer?.cancel();
    }
  }

  // 停止波纹动画
  void _stopRippleAnimation() {
    _rippleTimer?.cancel();
    _rippleTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = widget.language == LanguageEnum.CN ? Colors.redAccent : Colors.blueAccent;
    return GestureDetector(
      // 按下
      onTapDown: (TapDownDetails? details) {
        _progressController.forward(from: _lastProgressValue);
      },
      // 松开
      onTapUp: (TapUpDetails? details) {
        _progressController.reverse();
      },
      // 取消
      onTapCancel: () {
        _progressController.reverse();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 波纹动画在按钮下方
          Positioned.fill(
            child: CustomPaint(
              painter: MultiRipplePainter(
                ripples: _ripples,
                language: widget.language,
              ),
            ),
          ),
          // 进度条
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _progressController.value,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                );
              },
            ),
          ),
          // 中间的按钮
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 120), // 按钮大小
              shape: const CircleBorder(),
              backgroundColor: baseColor,
            ),
            onPressed: () {},
            child: Text(
              widget.language.name,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
