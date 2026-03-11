// lib/features/settings/terms_of_service_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          title: const Text('利用規約'),
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
                      '利用規約',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'この利用規約（以下、「本規約」といいます。）は、本アプリ「AI Scan Excel」（以下、「本アプリ」といいます。）の利用条件を定めるものです。ユーザーの皆様（以下、「ユーザー」といいます。）には、本規約に従って本アプリをご利用いただきます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 24),
                    
                    _SectionTitle(title: '第1条（適用および同意）'),
                    Text(
                      '本規約は、ユーザーと開発者との間の本アプリの利用に関わる一切の関係に適用されます。ユーザーは、本アプリを利用することにより、本規約に同意したものとみなされます。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第2条（禁止事項）'),
                    Text(
                      'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。\n1. 法令または公序良俗に違反する行為\n2. 犯罪行為に関連する行為\n3. 本アプリのプログラムをリバースエンジニアリング、逆コンパイル、逆アセンブルする行為\n4. 本アプリまたは連携する外部APIの不正利用、自動アクセス、または過度なリクエストを送信する行為\n5. 開発者、他のユーザー、または第三者の知的財産権、プライバシーその他の権利を侵害する行為\n6. 本アプリの運営を妨害するおそれのある行為\n7. その他、開発者が不適切と判断する行為',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第3条（外部サービスの利用）'),
                    Text(
                      '本アプリは、文字抽出等の機能を提供するために、Google LLCが提供するAPI等の外部サービスを利用する場合があります。当該外部サービスの利用にあたっては、各事業者が定める利用条件やプライバシーポリシーが適用されるものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第4条（本アプリの提供の停止・終了等）'),
                    Text(
                      '開発者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本アプリの全部または一部の提供を停止、中断、または終了することができるものとします。\n1. 本アプリにかかるシステムの保守点検または更新を行う場合\n2. 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合\n3. 連携する外部サービスの停止や仕様変更が発生した場合\n4. その他、開発者が本アプリの提供が困難と判断した場合',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第5条（免責事項および非保証）'),
                    Text(
                      '1. 本アプリによるOCR（文字認識）結果、AIによる解析・整形結果などの出力内容はあくまで参考情報であり、開発者はその正確性、完全性、有用性、特定の目的への適合性について一切の保証を行いません。ユーザーは自己の責任において内容を確認のうえ利用するものとします。\n2. 開発者は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、エラーやバグ、権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。\n3. 開発者は、本アプリに関してユーザーに生じた損害について、開発者に故意または重過失がある場合を除き、責任を負わないものとします。\n4. 前項において開発者が責任を負う場合であっても、開発者の軽過失によるときは、通常生ずべき直接かつ現実の損害に限るものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第6条（利用規約の変更）'),
                    Text(
                      '開発者は、民法その他の法令に基づき、本規約を変更することがあります。本規約を変更する場合、開発者は変更後の内容および効力発生日を、アプリ内での表示その他適切な方法によりユーザーに周知するものとします。変更後も本アプリの利用を継続した場合は、変更後の規約に同意したものとみなします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第7条（準拠法・裁判管轄）'),
                    Text(
                      '本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、東京地方裁判所または東京簡易裁判所を第一審の専属的合意管轄裁判所とします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 32),

                    // ★TODO: アプリをリリースする日やご自身の情報に書き換えてください
                    Text(
                      '制定日: 2024年3月10日\n\n【お問い合わせ窓口】\n開発者: [あなたの名前 または 屋号]\nメールアドレス: [あなたのメールアドレス]',
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