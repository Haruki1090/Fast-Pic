import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:ui';

import '../widgets/month_calendar.dart';
import 'photo_map_screen.dart';

class VerticalCalendarScreen extends StatefulWidget {
  final Map<DateTime, AssetEntity> assetsByDay;
  final ScrollController scrollController;

  const VerticalCalendarScreen({
    super.key,
    required this.assetsByDay,
    required this.scrollController,
  });

  @override
  VerticalCalendarScreenState createState() => VerticalCalendarScreenState();
}

class VerticalCalendarScreenState extends State<VerticalCalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _currentDate = DateTime.now();

  // マップボタンの表示管理
  bool _showMapButton = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    // スクロールリスナーを設定
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // スクロール方向に応じてマップボタンの表示/非表示を切り替え
  void _handleScroll() {
    // スクロール方向を検出
    final currentPosition = _scrollController.offset;
    final isScrollingDown = currentPosition > _lastScrollPosition;

    // 下スクロール時はボタンを非表示
    if (isScrollingDown && _showMapButton) {
      setState(() {
        _showMapButton = false;
      });
    }
    // 上スクロール時はボタンを表示
    else if (!isScrollingDown && !_showMapButton) {
      setState(() {
        _showMapButton = true;
      });
    }

    _lastScrollPosition = currentPosition;
  }

  List<Map<String, int>> _generateAllMonths() {
    final List<Map<String, int>> months = [];
    final currentYear = _currentDate.year;
    final currentMonth = _currentDate.month;

    // 過去5年分を古い順に生成（例: 2020年1月 → 2025年2月）
    for (int year = currentYear - 5; year <= currentYear; year++) {
      final startMonth = year == currentYear - 5 ? 1 : 1;
      final endMonth = year == currentYear ? currentMonth : 12;

      for (int month = startMonth; month <= endMonth; month++) {
        months.add({'year': year, 'month': month});
      }
    }
    return months;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // マップ画面に遷移
  void _navigateToMapScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PhotoMapScreen(
          assetsByDay: widget.assetsByDay,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = _generateAllMonths();
    if (months.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      body: Stack(
        children: [
          // メインのカレンダー表示
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final y = months[index]["year"]!;
              final m = months[index]["month"]!;
              return MonthCalendar(
                year: y,
                month: m,
                assetsByDay: widget.assetsByDay,
              );
            },
          ),

          // マップ表示ボタン（画面下部に表示）
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showMapButton ? 16.0 : -80.0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildMapButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            elevation: 0,
            child: InkWell(
              onTap: _navigateToMapScreen,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '撮影場所マップを見る',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
