import 'package:flutter/material.dart';
import 'package:neoglot/language_enum.dart';

import 'ripple_painter.dart';

// 按钮状态枚举
enum ButtonState {
  idle, // 闲置状态
  recording, // 录音状态
  playing, // 播放状态
}

class AudioButton extends StatefulWidget {
  final LanguageEnum language;
  final VoidCallback? onPressedStart;
  final VoidCallback? onPressedEnd;

  const AudioButton({
    super.key,
    required this.language,
    this.onPressedStart,
    required this.onPressedEnd,
  });

  @override
  _AudioButtonState createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _rippleRecordingController;
  late AnimationController _ripplePlayingController;
  ButtonState _buttonState = ButtonState.idle;

  @override
  void initState() {
    super.initState();

    // 进度条动画控制器（1秒内从0到1）
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 进度条完成，触发 onPressed 并开始录音波纹动画
        widget.onPressedEnd?.call();
        setState(() {
          _buttonState = ButtonState.recording;
        });
        _startRecordingRipple();
      } else if (status == AnimationStatus.dismissed) {
        // 反向动画完成，进入播放状态
        setState(() {
          _buttonState = ButtonState.playing;
        });
        _startPlayingRipple();
      }
    });

    // 录音波纹动画控制器（从大到小，持续2秒，重复）
    _rippleRecordingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 播放波纹动画控制器（从小到大，持续2秒，重复）
    _ripplePlayingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _rippleRecordingController.dispose();
    _ripplePlayingController.dispose();
    super.dispose();
  }

  // 开始录音波纹动画
  void _startRecordingRipple() {
    _rippleRecordingController.repeat();
  }

  // 停止录音波纹动画
  void _stopRecordingRipple() {
    _rippleRecordingController.stop();
    _rippleRecordingController.reset();
  }

  // 开始播放波纹动画
  void _startPlayingRipple() {
    _ripplePlayingController.repeat(reverse: false);
  }

  // 停止播放波纹动画
  void _stopPlayingRipple() {
    _ripplePlayingController.stop();
    _ripplePlayingController.reset();
  }

  // 处理按下事件
  void _onTapDown(TapDownDetails details) {
    if (_buttonState == ButtonState.idle) {
      _progressController.forward();
    }
  }

  // 处理松开事件
  void _onTapUp(TapUpDetails details) {
    if (_buttonState == ButtonState.idle) {
      if (_progressController.isAnimating) {
        _progressController.reverse();
      }
    } else if (_buttonState == ButtonState.recording) {
      // 停止录音波纹动画并开始播放播声音波纹动画
      _stopRecordingRipple();
      _progressController.reverse();
    }
  }

  // 处理取消事件（如用户滑出按钮范围）
  void _onTapCancel() {
    if (_buttonState == ButtonState.idle) {
      if (_progressController.isAnimating) {
        _progressController.reverse();
      }
    } else if (_buttonState == ButtonState.recording) {
      // 停止录音波纹动画并开始播放播声音波纹动画
      _stopRecordingRipple();
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown, // 按下
      onTapUp: _onTapUp, // 松开
      onTapCancel: _onTapCancel, // 取消
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 录音波纹动画（位于最底层）
          if (_buttonState == ButtonState.recording)
            AnimatedBuilder(
              animation: _rippleRecordingController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(
                    animationValue: _rippleRecordingController.value,
                    color: widget.language == LanguageEnum.CN
                        ? Colors.redAccent.withOpacity(0.5)
                        : Colors.blueAccent.withOpacity(0.5),
                    maxRadius: 120,
                    shrink: true,
                  ),
                );
              },
            ),
          // 播放波纹动画（位于最底层）
          if (_buttonState == ButtonState.playing)
            AnimatedBuilder(
              animation: _ripplePlayingController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(
                    animationValue: _ripplePlayingController.value,
                    color: widget.language == LanguageEnum.CN
                        ? Colors.blueAccent.withOpacity(0.5)
                        : Colors.redAccent.withOpacity(0.5),
                    maxRadius: 120,
                    shrink: false,
                  ),
                );
              },
            ),
          // 圆环进度条（位于按钮下方）
          SizedBox(
            width: 100, // 调整大小
            height: 100,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _progressController.value,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          // 中间的按钮（位于最上层）
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 80), // 调整按钮大小
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20), // 内边距
              backgroundColor:
                  widget.language == LanguageEnum.CN ? Colors.redAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.5),
            ),
            onPressed: () {}, // 禁用按钮的默认 onPressed
            child: Text(
              widget.language.name,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
