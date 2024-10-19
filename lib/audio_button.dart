import 'package:flutter/material.dart';
import 'package:neoglot/language_enum.dart';

class AudioButton extends StatefulWidget {
  final LanguageEnum language;
  final VoidCallback? onPressedEnd;

  const AudioButton({
    super.key,
    required this.language,
    required this.onPressedEnd,
  });

  @override
  _AudioButtonState createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 初始化 AnimationController，持续时间为500毫秒
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 监听动画状态，当动画完成时触发 onPressed
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPressedEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理按下事件，开始前进动画
  void _onTapDown(TapDownDetails details) {
    // 如果动画正在反向，先停止
    if (_controller.status == AnimationStatus.reverse || _controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  // 处理松开事件，开始反向动画
  void _onTapUp(TapUpDetails details) {
    if (_controller.status == AnimationStatus.forward || _controller.status == AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  // 处理取消事件，开始反向动画
  void _onTapCancel() {
    if (_controller.status == AnimationStatus.forward || _controller.status == AnimationStatus.completed) {
      _controller.reverse();
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
          // 圆环进度条
          SizedBox(
            width: 80, // 调整大小
            height: 80,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _controller.value,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          // 中间的按钮
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 80), // 调整按钮大小
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20), // 内边距
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: null, // 禁用按钮的默认 onPressed
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
