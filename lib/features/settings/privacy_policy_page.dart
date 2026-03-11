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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プライバシーポリシー',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '本アプリ「AI Scan Excel」は、ユーザーの皆様のプライバシーを尊重し、個人情報の保護に努めます。本ポリシーでは、アプリが収集する情報とその利用目的、および取り扱いについて説明します。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 24),
                    
                    const _SectionTitle(title: '1. 事業者情報・お問い合わせ先'),
                    const Text(
                      // ★TODO: ここをあなたのお名前（または屋号）と連絡が取れるメールアドレスに書き換えてください
                      '開発者: [あなたの名前 または 屋号]\n連絡先: [あなたのメールアドレス]',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '2. 取得する情報と利用目的'),
                    const Text(
                      '本アプリは、以下の情報を取得および利用します。\n・カメラ機能および画像データ：書類のテキスト抽出（OCR）およびデータ化機能を提供するために利用します。\nこれらはユーザーが要求した機能を提供するための目的にのみ使用されます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '3. 外部サービスへの情報の送信（第三者提供）'),
                    const Text(
                      '本アプリは、高精度な文字抽出を実現するため、Google LLCが提供するAIサービス（Gemini API）を利用しています。そのため、本アプリ内で撮影・選択された画像データは、テキスト抽出処理を目的としてGoogleのサーバーに送信されます。\n外部サービスにおけるデータの取扱いや、AIの製品改善（学習等）への利用方針については、Googleのプライバシーポリシーおよび利用規約に従うものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '4. データの保存場所と保存期間'),
                    const Text(
                      '撮影した画像、抽出されたテキストデータ、およびスキャン履歴は、すべてユーザーの端末内（ローカルストレージ）にのみ保存されます。開発者のサーバー等に送信・蓄積されることはありません。\nデータはユーザー自身がアプリ内の機能で削除するか、アプリをアンインストールするまで保存されます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '5. ユーザーによるデータの削除'),
                    const Text(
                      'ユーザーは本アプリの履歴画面から、保存された画像やテキストデータを任意のタイミングで削除することができます。また、本アプリを端末からアンインストールすることで、すべてのローカルデータは完全に削除されます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '6. 未成年者の利用について'),
                    const Text(
                      '本アプリの利用に年齢制限は設けておりませんが、未成年者が利用する場合は、法定代理人（保護者等）の同意を得た上でご利用ください。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '7. 免責事項'),
                    const Text(
                      '本アプリが提供するテキスト抽出結果の正確性については保証いたしかねます。本アプリの利用により生じたトラブルや損害について、開発者は一切の責任を負わないものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '8. プライバシーポリシーの変更'),
                    const Text(
                      '本アプリは、必要に応じて本ポリシーを変更することがあります。重要な変更がある場合は、アプリ内でお知らせいたします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      // ★TODO: アプリをリリースする日（または今日の日付）に書き換えてください
                      '制定日: 2024年3月10日\n最終改定日: 2024年3月10日',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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