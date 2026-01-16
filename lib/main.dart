// Flutterのマテリアルデザインに関するウィジェットを読み込む
import 'package:flutter/material.dart';

// アプリケーションが起動する一番最初の場所
void main() {
  // MyAppウィジェットを画面に表示する命令
  runApp(const MyApp());
}

// アプリの本体となるウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // このウィジェットが画面にどう表示されるかを定義する場所
  @override
  Widget build(BuildContext context) {
    // マテリアルデザインのアプリを作るための基本設定
    return MaterialApp(
      title: 'Health Connect App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF21B0B9)),
        useMaterial3: true,
      ),
      home: const HealthInputScreen(),
    );
  }
}

// 入力画面（状態を持つウィジェット）
class HealthInputScreen extends StatefulWidget {
  const HealthInputScreen({super.key});

  @override
  State<HealthInputScreen> createState() => _HealthInputScreenState();
}

class _HealthInputScreenState extends State<HealthInputScreen> {
  // フォームの状態を管理するキー
  final _formKey = GlobalKey<FormState>();
  // 入力された値を管理するコントローラー
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  // 日付の初期値
  DateTime _selectedDate = DateTime.now();

  // 画面が破棄されるときにコントローラーも破棄する
  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  // 日付と時刻を選択する処理
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // 保存ボタンが押されたときの処理
  void _saveData() {
    if (_formKey.currentState!.validate()) {
      // TODO: ここでヘルスコネクトへの保存処理を行う
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存処理を実行します（未実装）')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康データ入力')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // 日付選択行
              ListTile(
                title: Text("日時: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              // 体重入力
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: '体重 (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '体重を入力してください';
                  }
                  return null;
                },
              ),
              // 体脂肪率入力
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(labelText: '体脂肪率 (%)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              // 保存ボタン
              ElevatedButton(
                onPressed: _saveData,
                child: const Text('ヘルスコネクトに保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}