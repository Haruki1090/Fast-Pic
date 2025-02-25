import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _futureAssetsByDay = PhotoRepository.fetchAssetsGroupedByDay();
      _assetsByDay = await _futureAssetsByDay;
    } catch (e) {
      print('Error loading assets: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('写真をロード中...'),
          ],
        ),
      );
    }

    if (_assetsByDay == null || _assetsByDay!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_album_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('写真が見つかりませんでした'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return VerticalCalendarScreen(assetsByDay: _assetsByDay!);
      case 1:
        return WeeklyCalendarScreen(assetsByDay: _assetsByDay!);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '縦スクロールカレンダー' : '週間カレンダー'),
        actions: [
          // 設定ボタンを追加
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onSettingsChanged: _loadAssets,
                  ),
                ),
              );
            },
            tooltip: '設定',
          ),
          // 更新ボタン
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: !_isLoading ? _loadAssets : null,
            tooltip: '写真を更新',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景にわずかなグラデーション効果
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF5F9FF)],
              ),
            ),
          ),
          // メインコンテンツ
          _buildCurrentScreen(),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_view_month),
                  label: '月表示',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_view_week),
                  label: '週表示',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
