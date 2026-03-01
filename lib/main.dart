import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AI Scan MVP')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // ネイティブカメラの起動テスト
              const channel = MethodChannel('com.example.app/camera'); // MainActivity.ktのチャンネル名に合わせる
              try {
                // is_product_list フラグなどは一旦適当に渡すか、ネイティブ側で調整
                final result = await channel.invokeMethod('startNativeCamera', {'is_product_list': false});
                print("撮影結果: $result");
              } catch (e) {
                print("エラー: $e");
              }
            },
            child: const Text('カメラ起動'),
          ),
        ),
      ),
    );
  }
}