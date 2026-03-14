// lib/features/settings/how_to_use_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class HowToUsePage extends StatefulWidget {
  const HowToUsePage({super.key});

  @override
  State<HowToUsePage> createState() => _HowToUsePageState();
}

class _HowToUsePageState extends State<HowToUsePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // チュートリアルのデータ
  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': '1. テンプレートを作ろう',
      'description': 'まずは「テンプレ」タブの「+」ボタンから、読み取りたい書類の項目（日付、金額、会社名など）を設定します。\n全文をそのまま読み取るモードも選べます。',
      'icon': Icons.file_copy_outlined,
      'color': Colors.blueAccent,
    },
    {
      'title': '2. 書類をスキャンしよう',
      'description': 'ホーム画面やテンプレ画面から「スキャン開始」をタップし、カメラで書類を撮影します。\nAIが画像を解析し、設定した項目通りに自動でテキストを抽出します。',
      'icon': Icons.camera_alt_outlined,
      'color': Colors.orangeAccent,
    },
    {
      'title': '3. 確認して出力・共有',
      'description': '読み取り結果の確認画面で、必要に応じて手直しができます。\n完了したら「出力・保存」ボタンから、Excelファイル（.xlsx）やテキストとして保存・共有しましょう！',
      'icon': Icons.ios_share,
      'color': Colors.green,
    },
  ];

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0C3FC), 
            Color(0xFF8EC5FC), 
            Color(0xFFE0C3FC), 
          ],
          stops: [0.0, 0.5, 1.0], 
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('アプリの使い方'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _tutorialSteps.length,
                  itemBuilder: (context, index) {
                    final step = _tutorialSteps[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    step['icon'],
                                    size: 80,
                                    color: step['color'],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  step['title'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  step['description'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.8,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ページインジケーター（ドット）
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _tutorialSteps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10,
                      width: _currentPage == index ? 24 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF667EEA)
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
              // 「次へ」または「はじめる」ボタン
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _tutorialSteps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage < _tutorialSteps.length - 1 ? '次へ' : 'とじる',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}