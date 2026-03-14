// lib/features/settings/privacy_policy_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          title: const Text('プライバシーポリシー'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildGlassCard(
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'プライバシーポリシー',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Harusaki（以下、「開発者」といいます。）は、開発者が提供するアプリケーション「AI Scan Excel」（以下、「本アプリ」といいます。）における、ユーザー情報の取扱いについて、以下のとおりプライバシーポリシー（以下、「本ポリシー」といいます。）を定めます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 24),
                    
                    _SectionTitle(title: '第1条（適用）'),
                    Text(
                      '本ポリシーは、本アプリの利用に関して適用されます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第2条（取得する情報）'),
                    Text(
                      '本アプリは、以下の情報を取得することがあります。\n1. ユーザーが撮影または選択した画像データ\n2. 画像から抽出されたテキストデータおよび解析結果\n3. スキャン履歴\n4. ユーザーが作成または設定したテンプレート情報（テンプレート名、抽出項目、モード設定その他これに関連する情報）\n5. 累計スキャン回数その他、本アプリの利用に伴って端末内に保存される利用情報\n6. お問い合わせ時にユーザーが任意に提供する情報',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第3条（利用目的）'),
                    Text(
                      '開発者は、前条の情報を以下の目的で利用します。\n1. OCR、表抽出、情報解析その他本アプリの機能を提供するため\n2. スキャン結果の表示、保存、履歴管理、テンプレート管理等を行うため\n3. 本アプリの利便性向上、品質改善、不具合対応のため\n4. ユーザーからのお問い合わせに対応するため\n5. 利用規約に違反する行為への対応その他、本アプリの適切な運営のため',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第4条（外部サービスの利用および情報送信）'),
                    Text(
                      '本アプリは、文字抽出およびデータ解析機能を提供するため、Google LLC が提供する Firebase Cloud Functions および Gemini API 等の外部サービスを利用しています。\nこのため、ユーザーが撮影または選択した画像データのほか、抽出項目、解析モード、追加指示その他解析に必要な情報が、当該処理のために外部サービスへ送信される場合があります。\n外部サービスに送信された情報の取扱いは、当該サービス提供者の利用規約、プライバシーポリシーその他の定めに従います。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第5条（情報の保存場所）'),
                    Text(
                      '本アプリにおいて取得または生成される画像データ、抽出結果、スキャン履歴、テンプレート設定等の情報は、主としてユーザーの端末内に保存されます。\n開発者は、開発者が管理する独自サーバーに、これらの情報を恒久的に保存するものではありません。\nただし、第4条に定める機能提供の過程で、外部サービスを経由して情報が送信・処理される場合があります。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第6条（第三者提供）'),
                    Text(
                      '開発者は、法令に基づく場合を除き、ユーザーの情報を第三者に提供しません。\nただし、本アプリの機能提供に必要な範囲で、第4条に定める外部サービスへ情報を送信する場合があります。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第7条（情報の管理）'),
                    Text(
                      '開発者は、ユーザー情報の漏えい、滅失または毀損の防止その他の安全管理のため、合理的な範囲で必要かつ適切な措置を講じるよう努めます。\nもっとも、端末の管理状態、通信環境、外部サービスの利用状況その他の事情により、完全な安全性を保証するものではありません。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第8条（ユーザーによる削除）'),
                    Text(
                      'ユーザーは、本アプリ上の履歴削除機能、テンプレート削除機能、または端末上でのアプリ削除その他の方法により、本アプリ内に保存された情報を削除することができます。\nなお、外部サービスに送信された情報については、当該外部サービスの取扱いに従うものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第9条（未成年者の利用）'),
                    Text(
                      '未成年者が本アプリを利用する場合は、必要に応じて親権者その他の法定代理人の同意を得たうえで利用するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第10条（本アプリの性質）'),
                    Text(
                      '本アプリによるOCR結果、表抽出結果、解析結果その他の出力は、参考情報として提供されるものであり、その正確性、完全性、有用性または特定目的への適合性を保証するものではありません。\nユーザーは、自己の責任において内容を確認のうえ利用するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第11条（本ポリシーの変更）'),
                    Text(
                      '開発者は、必要に応じて本ポリシーを変更することがあります。\n本ポリシーを変更する場合、変更後の内容および適用開始日を、本アプリ内への表示その他適切な方法により周知します。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 32),

                    Text(
                      '【お問い合わせ窓口】\n開発者: Harusaki\nメールアドレス: Sol_Zafkiel@harusakis.com\n\n施行日: 2026年3月11日\n最終改定日: 2026年3月11日',
                      style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey, fontWeight: FontWeight.bold),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
      ),
    );
  }
}