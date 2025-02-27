import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';

import 'screens/vertical_calendar_screen.dart';
import 'screens/weekly_calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'model/photo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PhotoManager.setLog(true);

  // システムUIをエッジツーエッジに設定（没入感の向上）
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // システムナビゲーションバーを透明に
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.white.withOpacity(0.8),
        ),
        useMaterial3: true, // Material 3デザインを使用
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),
        ),
        fontFamily: 'Noto Sans JP', // 日本語フォントの指定
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            letterSpacing: 0.1,
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

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late Future<Map<DateTime, AssetEntity>> _futureAssetsByDay;
  Map<DateTime, AssetEntity>? _assetsByDay;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showScreenshotsChanging = false;

  // UI表示のための変数
  bool _showAppBar = false;
  bool _showNavBar = false;
  late AnimationController _appBarAnimController;
  late AnimationController _navBarAnimController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _navBarSlideAnimation;

  // スクロール方向検知用
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = false;
  double lastScrollOffset = 0;

  // ページ切替アニメーション用
  late PageController _pageController;
  double currentPage = 0;

  // 年月表示用
  String currentMonthYear = '';
  late AnimationController _monthYearFadeController;
  late Animation<double> _monthYearFadeAnimation;

  bool _showFAB = true; // FABの表示/非表示を制御
  late AnimationController _fabAnimController; // FABのアニメーション用
  late Animation<double> _fabScaleAnimation; // FAB表示/非表示のアニメーション

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ja_JP');

    // 現在の年月を設定
    final now = DateTime.now();
    currentMonthYear = DateFormat.yMMMM('ja_JP').format(now);

    // アニメーションコントローラーの初期化
    _appBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _monthYearFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // アニメーションの定義
    _appBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appBarAnimController,
      curve: Curves.easeOutCubic,
    ));

    _navBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navBarAnimController,
      curve: Curves.easeOutCubic,
    ));

    _monthYearFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _monthYearFadeController,
      curve: Curves.easeIn,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    ));

    _monthYearFadeController.forward();
    _fabAnimController.forward(); // FABを初期表示

    // ページコントローラー初期化
    _pageController = PageController(initialPage: 0);
    currentPage = 0;

    // スクロールリスナー設定
    _scrollController.addListener(_scrollListener);

    _loadAssets();
  }

  @override
  void dispose() {
    _appBarAnimController.dispose();
    _navBarAnimController.dispose();
    _monthYearFadeController.dispose();
    _fabAnimController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // スクロール検知のリスナーも修正
  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // 下スクロール時
      if (!_isScrollingDown) {
        _isScrollingDown = true;

        // メニューを非表示にする
        if (_showAppBar) {
          _hideUIElements();

          // メニューが完全に消えた後にFABを表示
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _showFAB = true;
                _fabAnimController.forward();
              });
            }
          });
        }
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // 上スクロール時
      if (_isScrollingDown) {
        _isScrollingDown = false;

        // FABが表示されていれば非表示にし、メニューを表示
        if (_showFAB) {
          setState(() {
            _showFAB = false;
            _fabAnimController.reverse().then((_) {
              if (mounted) {
                _showUIElements();
              }
            });
          });
        }
      }
    }

    lastScrollOffset = _scrollController.offset;
  }

  // UIの表示/非表示を制御する関数
  void _toggleUIVisibility() {
    setState(() {
      if (_showAppBar) {
        // メニューが表示されている場合は非表示にし、FABを表示
        _hideUIElements();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showFAB = true;
              _fabAnimController.forward();
            });
          }
        });
      } else {
        // メニューが非表示の場合は表示し、FABを非表示
        _showFAB = false;
        _fabAnimController.reverse().then((_) {
          if (mounted) {
            _showUIElements();
          }
        });
      }
    });
  }

  void _showUIElements() {
    setState(() {
      _showAppBar = true;
      _showNavBar = true;
      _showFAB = false; // FABを非表示にする
      _appBarAnimController.forward();
      _navBarAnimController.forward();
    });

    // 5秒後に自動的に非表示にする
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _hideUIElements();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showFAB = true;
              _fabAnimController.forward();
            });
          }
        });
      }
    });
  }

  void _hideUIElements() {
    setState(() {
      _showAppBar = false;
      _showNavBar = false;
      _appBarAnimController.reverse();
      _navBarAnimController.reverse();
    });
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      _showSnackBar(
        '写真を読み込み中です...',
        duration: const Duration(seconds: 3),
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

        _showSnackBar(
          '写真の読み込みが完了しました',
          backgroundColor: Colors.green.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _showScreenshotsChanging = false;
        });

        _showSnackBar(
          '写真の読み込み中にエラーが発生しました',
          backgroundColor: Colors.red.withOpacity(0.8),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  void _showSnackBar(String message,
      {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor ?? Colors.black87.withOpacity(0.7),
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  Future<void> _reloadAssetsAfterSettingsChange() async {
    setState(() {
      _showScreenshotsChanging = true;
    });

    _showSnackBar(
      '設定を適用中です...',
      duration: const Duration(seconds: 3),
    );

    await _loadAssets();
  }

  // カレンダー表示を切り替えるための関数
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      currentPage = index.toDouble();

      // 月/週表示切替時にアニメーション効果
      _monthYearFadeController.reset();
      _monthYearFadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleUIVisibility,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: _buildAppBar(),
        body: _isLoading ? _buildLoadingScreen() : _buildCalendarScreen(),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (!_showAppBar) return null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0),
      child: SlideTransition(
        position: _appBarSlideAnimation,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: true,
              title: FadeTransition(
                opacity: _monthYearFadeAnimation,
                child: Text(
                  _selectedIndex == 0 ? '縦スクロールカレンダー' : '週間カレンダー',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.photo_library_outlined),
                onPressed: () {
                  // 写真ライブラリへのショートカットを実装
                },
                tooltip: 'ライブラリ',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  onPressed: !_isRefreshing && !_showScreenshotsChanging
                      ? () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      SettingsScreen(
                                onSettingsChanged:
                                    _reloadAssetsAfterSettingsChange,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
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
                      icon: const Icon(Icons.refresh_outlined, size: 22),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomNavBar() {
    if (!_showNavBar) return null;

    return SlideTransition(
      position: _navBarSlideAnimation,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarItem(0, Icons.calendar_month, '月表示'),
                    _buildNavBarItem(1, Icons.view_week, '週表示'),
                    _buildNavBarItem(2, Icons.search, '検索'),
                    _buildNavBarItem(3, Icons.favorite_outline, 'お気に入り'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          if (index <= 1) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    if (!_showFAB) return null;

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: FloatingActionButton(
        onPressed: _toggleUIVisibility,
        elevation: 2,
        backgroundColor: Colors.white.withOpacity(0.8),
        child: const Icon(Icons.menu, color: Colors.black87),
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
            _showScreenshotsChanging ? 'スクリーンショット設定を適用中...' : '写真を読み込み中...',
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '写真を読み込めませんでした。\n更新ボタンを押してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_assetsByDay!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '表示できる写真がありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ページビューでスワイプで切り替えられるようにする
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        VerticalCalendarScreen(
          assetsByDay: _assetsByDay!,
          scrollController: _scrollController,
        ),
        WeeklyCalendarScreen(
          assetsByDay: _assetsByDay!,
          scrollController: _scrollController,
        ),
      ],
    );
  }
}
