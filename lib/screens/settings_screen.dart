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
                                  onChanged: (value) async {
                                    await SettingsRepository.setShowScreenshots(
                                        value);
                                    setState(() {
                                      _showScreenshots = value;
                                    });
                                    widget.onSettingsChanged();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
