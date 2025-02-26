import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui';

import 'screens/vertical_calendar_screen.dart';
import 'screens/weekly_calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'model/photo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PhotoManager.setLog(true); // ログ有効化

  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertical Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.7),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<Map<DateTime, AssetEntity>> _futureAssetsByDay;
  Map<DateTime, AssetEntity>? _assetsByDay;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showScreenshotsChanging = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ja_JP');
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('写真を読み込み中です。スクリーンショットのフィルタリングに時間がかかる場合があります...'),
          duration: Duration(seconds: 3),
        ),
      );

      _futureAssetsByDay = PhotoRepository.fetchAssetsGroupedByDay();
      final assetsByDay = await _futureAssetsByDay;

      if (mounted) {
        setState(() {
          _assetsByDay = assetsByDay;
          _isLoading = false;
          _isRefreshing = false;
          _showScreenshotsChanging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真の読み込みが完了しました'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _showScreenshotsChanging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の読み込み中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _reloadAssetsAfterSettingsChange() async {
    setState(() {
      _showScreenshotsChanging = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('設定を適用中です。スクリーンショットのフィルタリングを更新しています...'),
        duration: Duration(seconds: 3),
      ),
    );

    await _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '縦スクロールカレンダー' : '週間カレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: !_isRefreshing && !_showScreenshotsChanging
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          onSettingsChanged: _reloadAssetsAfterSettingsChange,
                        ),
                      ),
                    );
                  }
                : null,
            tooltip: '設定',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: !_isRefreshing && !_showScreenshotsChanging
                    ? _loadAssets
                    : null,
                tooltip: '写真を更新',
              ),
              if (_isRefreshing || _showScreenshotsChanging)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildCalendarScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '月表示',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_week),
            label: '週表示',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _showScreenshotsChanging
                ? 'スクリーンショット設定を適用中...\nフィルタリングには時間がかかる場合があります'
                : '写真を読み込み中...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (_isRefreshing || _showScreenshotsChanging)
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 32.0, right: 32.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarScreen() {
    if (_assetsByDay == null) {
      return const Center(child: Text('写真を読み込めませんでした。\n更新ボタンを押してください。'));
    }

    if (_assetsByDay!.isEmpty) {
      return const Center(child: Text('表示できる写真がありません'));
    }

    if (_selectedIndex == 0) {
      return VerticalCalendarScreen(assetsByDay: _assetsByDay!);
    } else {
      return WeeklyCalendarScreen(assetsByDay: _assetsByDay!);
    }
  }
}
