import 'package:flutter/material.dart';
import 'dart:ui';
import '../model/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  final Function() onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.onSettingsChanged,
  });

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool? _showScreenshots;
  bool _isLoading = true;
  bool _isSaving = false; // 保存中フラグ

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final showScreenshots = await SettingsRepository.getShowScreenshots();
    setState(() {
      _showScreenshots = showScreenshots;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.white.withOpacity(0.7),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    '表示設定',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SwitchListTile(
                                  title: const Text('スクリーンショットを表示'),
                                  subtitle:
                                      const Text('スクリーンショットを写真一覧に表示するかどうか'),
                                  value: _showScreenshots ?? true,
                                  onChanged: _isSaving
                                      ? null
                                      : (value) async {
                                          // 保存開始前に確認ダイアログを表示
                                          final confirmed =
                                              await _showConfirmationDialog(
                                                  value);
                                          if (!confirmed) return;

                                          setState(() {
                                            _isSaving = true; // 保存中フラグをセット
                                          });

                                          await SettingsRepository
                                              .setShowScreenshots(value);

                                          setState(() {
                                            _showScreenshots = value;
                                            _isSaving = false;
                                          });

                                          // 設定変更をメイン画面に通知
                                          if (mounted) {
                                            Navigator.pop(context); // 設定画面を閉じる
                                            widget
                                                .onSettingsChanged(); // メイン画面に通知
                                          }
                                        },
                                  secondary: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.screenshot),
                                ),
                                // スクリーンショット表示設定変更の注意書き
                                if (!_isSaving)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 16),
                                    child: Text(
                                      'スクリーンショットの除外設定には時間がかかる場合があります。\n特に写真が多い場合は時間がかかります。',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 保存中はローディングインジケーターを表示
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            '設定を保存中...\n変更の適用には時間がかかる場合があります',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // 設定変更前の確認ダイアログ
  Future<bool> _showConfirmationDialog(bool newValue) async {
    final message = newValue
        ? 'スクリーンショットを表示に含めますか？'
        : 'スクリーンショットを非表示にしますか？\n\n処理に時間がかかる場合があります。';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newValue ? 'スクリーンショット表示' : 'スクリーンショット非表示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変更する'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
