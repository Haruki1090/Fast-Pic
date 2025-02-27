import 'package:flutter/material.dart';
import 'dart:ui';

// オーバースクロールを検知するインジケータ
class PullToShowMapIndicator extends StatelessWidget {
  final double overscrollPercent; // オーバースクロールの進行度 (0.0-1.0)
  final bool isTriggered; // マップ表示のトリガーが引かれたか

  const PullToShowMapIndicator({
    Key? key,
    required this.overscrollPercent,
    required this.isTriggered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (overscrollPercent <= 0.0) return const SizedBox.shrink();

    return Container(
      height: 80.0 * overscrollPercent,
      width: double.infinity,
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16 * overscrollPercent),
          topRight: Radius.circular(16 * overscrollPercent),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7 * overscrollPercent),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.5 * overscrollPercent),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24 * overscrollPercent,
                  width: 24 * overscrollPercent,
                  child: CircularProgressIndicator(
                    value: isTriggered ? null : overscrollPercent,
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.withOpacity(overscrollPercent),
                    ),
                  ),
                ),
                SizedBox(height: 8 * overscrollPercent),
                Text(
                  isTriggered ? 'マップを読み込み中...' : 'さらに下に引っ張ってマップを表示',
                  style: TextStyle(
                    fontSize: 14.0 * overscrollPercent,
                    color: Colors.black87.withOpacity(overscrollPercent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// スクロールを監視するカスタムScrollPhysics
class OverscrollMapNotifier extends ScrollPhysics {
  final Function(double) onOverscroll;
  final double triggerThreshold;

  const OverscrollMapNotifier({
    required this.onOverscroll,
    required this.triggerThreshold,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  OverscrollMapNotifier applyTo(ScrollPhysics? ancestor) {
    return OverscrollMapNotifier(
      onOverscroll: onOverscroll,
      triggerThreshold: triggerThreshold,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 下方向のスクロールでリストの最下部に達した場合
    if (offset > 0 && position.pixels >= position.maxScrollExtent) {
      final overscroll = offset;
      onOverscroll(overscroll);
    } else if (offset < 0 || position.pixels < position.maxScrollExtent) {
      // オーバースクロールがない場合は0をコールバック
      onOverscroll(0);
    }

    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 標準の境界条件を適用
    return super.applyBoundaryConditions(position, value);
  }
}
