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
                      'この利用規約（以下、「本規約」といいます。）は、Harusaki（以下、「開発者」といいます。）が提供するアプリケーション「AI Scan Excel」（以下、「本アプリ」といいます。）の利用条件を定めるものです。ユーザーは、本規約に同意のうえ、本アプリを利用するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 24),
                    
                    _SectionTitle(title: '第1条（適用）'),
                    Text(
                      '1. 本規約は、ユーザーと開発者との間の本アプリの利用に関わる一切の関係に適用されます。\n2. 開発者が本アプリ内その他で掲載する利用上の注意、ガイドラインその他のルールは、本規約の一部を構成するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第2条（利用条件）'),
                    Text(
                      '1. ユーザーは、自己の責任において本アプリを利用するものとします。\n2. ユーザーは、本アプリの利用にあたり、適用される法令、公序良俗および本規約を遵守するものとします。\n3. 本アプリの利用に必要な端末、通信環境その他の利用環境は、ユーザーの費用と責任において準備するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第3条（禁止事項）'),
                    Text(
                      'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。\n1. 法令または公序良俗に違反する行為\n2. 犯罪行為に関連する行為\n3. 本アプリまたはこれに関連するシステム、ネットワーク等に不正にアクセスし、またはその運営を妨害する行為\n4. 本アプリのソースコード、プログラム、構造等を解析することを目的としたリバースエンジニアリング、逆コンパイル、逆アセンブルその他これらに類する行為\n5. 本アプリを不正な目的で利用する行為\n6. 本アプリを利用して第三者の権利または利益を侵害する行為\n7. 虚偽の情報を入力し、または送信する行為\n8. 本アプリの機能を利用して取得した結果を、違法または不適切な目的で使用する行為\n9. 本アプリが利用する外部サービスに対して、過度なリクエスト送信その他不正または過剰な利用を行う行為\n10. 開発者、他のユーザーまたは第三者に不利益、損害、不快感を与える行為\n11. 前各号のほか、開発者が不適切と判断する行為',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第4条（外部サービスの利用）'),
                    Text(
                      '1. 本アプリは、機能提供のためにGoogle LLCその他の第三者が提供する外部サービスを利用する場合があります。\n2. 外部サービスの利用にあたっては、当該外部サービス提供者の利用規約、プライバシーポリシーその他の条件が適用される場合があります。\n3. 開発者は、外部サービスの内容、継続性、可用性等について保証するものではありません。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第5条（知的財産権）'),
                    Text(
                      '1. 本アプリに関する著作権、商標権その他一切の知的財産権は、開発者または正当な権利者に帰属します。\n2. ユーザーは、法令により認められる範囲を超えて、本アプリまたは本アプリに含まれる情報を複製、転載、改変、販売、再配布、二次利用その他これらに類する行為をしてはなりません。\n3. ユーザーが本アプリを通じて取得した解析結果その他の情報については、ユーザー自身がその利用の適法性および妥当性を確認したうえで利用するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第6条（本アプリの停止、中断または終了）'),
                    Text(
                      '開発者は、以下のいずれかに該当する場合、ユーザーに事前に通知することなく、本アプリの全部または一部の提供を停止、中断または終了することができます。\n1. 本アプリにかかるシステムの保守、点検、更新または障害対応を行う場合\n2. 通信回線、外部サービス、端末環境等に起因して本アプリの提供が困難となった場合\n3. 天災地変、火災、停電、戦争、騒乱、労働争議その他の不可抗力により本アプリの提供が困難となった場合\n4. その他、開発者が本アプリの提供継続が困難または不適切と判断した場合',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第7条（本アプリの内容および結果について）'),
                    Text(
                      '1. 本アプリによるOCR結果、表抽出結果、解析結果、整形結果その他一切の出力は、参考情報として提供されるものであり、その正確性、完全性、有用性、継続性、再現性または特定目的への適合性を保証するものではありません。\n2. ユーザーは、前項の結果を自己の責任において確認し、利用するものとします。\n3. 本アプリは、医療、法律、税務、会計その他高度な正確性または専門的判断が求められる用途のために設計されたものではありません。必要に応じて、ユーザー自身の判断または専門家の助言を得て利用するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第8条（免責）'),
                    Text(
                      '1. 開発者は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、目的適合性、セキュリティ上の欠陥、エラーやバグ、権利侵害等を含みますが、これらに限られません。）がないことを保証するものではありません。\n2. 開発者は、本アプリの利用または利用不能によりユーザーに生じた損害について、開発者に故意または重過失がある場合を除き、責任を負わないものとします。\n3. 前項に基づき開発者が責任を負う場合であっても、開発者の軽過失によるときは、通常生ずべき直接かつ現実の損害に限って責任を負うものとします。\n4. 開発者は、外部サービスに起因してユーザーに生じた損害について、開発者に故意または重過失がある場合を除き、責任を負わないものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第9条（利用規約の変更）'),
                    Text(
                      '開発者は、民法その他の法令に基づき、本規約を変更することがあります。\n本規約を変更する場合、変更後の内容および効力発生日を、本アプリ内への表示その他適切な方法により周知します。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第10条（連絡・通知）'),
                    Text(
                      '本アプリに関する開発者からユーザーへの連絡または通知は、本アプリ内への表示その他開発者が適当と判断する方法によって行います。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第11条（権利義務の譲渡禁止）'),
                    Text(
                      'ユーザーは、開発者の書面による事前の承諾なく、本規約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し、承継させ、または担保に供することはできません。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第12条（分離可能性）'),
                    Text(
                      '本規約のいずれかの条項またはその一部が法令等により無効または執行不能と判断された場合であっても、その他の条項および無効または執行不能と判断された部分以外の部分は、引き続き完全に効力を有するものとします。',
                      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 16),

                    _SectionTitle(title: '第13条（準拠法および裁判管轄）'),
                    Text(
                      '1. 本規約の解釈にあたっては、日本法を準拠法とします。\n2. 本アプリに関してユーザーと開発者との間に紛争が生じた場合には、開発者の住所地を管轄する地方裁判所または簡易裁判所を第一審の専属的合意管轄裁判所とします。',
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