// Flutterのマテリアルデザインに関するウィジェットを読み込む
import 'package:flutter/material.dart';
// ヘルスコネクト連携用パッケージ
import 'package:health/health.dart';

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

  // Healthパッケージのインスタンス
  final Health _health = Health();

  @override
  void initState() {
    super.initState();
  }

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
  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      // 1. 扱いたいデータタイプと権限を定義
      final types = [
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
      ];
      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
      ];

      try {
        // ヘルスコネクトのステータスを確認
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ヘルスコネクトの状態: $status')),
            );
          }
          // インストールやアップデートが必要な場合はストアへ誘導
          // 詳細なステータス判定でエラーが出るため、利用可能でない場合は一律でインストールを試みる
          await _health.installHealthConnect();
          return;
        }

        // 2. 権限のリクエスト（初回は許可ダイアログが表示されます）
        bool requested = await _health.requestAuthorization(types, permissions: permissions);

        if (requested) {
          final now = _selectedDate;
          
          // 3. 体重の保存
          double weight = double.parse(_weightController.text);
          bool successWeight = await _health.writeHealthData(
            value: weight,
            type: HealthDataType.WEIGHT,
            startTime: now,
            endTime: now,
          );

          // 4. 体脂肪率の保存（入力がある場合のみ）
          bool successFat = true;
          if (_fatController.text.isNotEmpty) {
            double fat = double.parse(_fatController.text);
            successFat = await _health.writeHealthData(
              value: fat,
              type: HealthDataType.BODY_FAT_PERCENTAGE,
              startTime: now,
              endTime: now,
            );
          }

          if (mounted) {
            final msg = (successWeight && successFat) ? 'ヘルスコネクトに保存しました！' : '保存に失敗しました';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

            // 保存成功時にフォームをクリアし、日時を現在に戻す
            if (successWeight && successFat) {
              _weightController.clear();
              _fatController.clear();
              setState(() {
                _selectedDate = DateTime.now();
              });
            }
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('権限が許可されませんでした')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.update),
                      tooltip: '現在日時に設定',
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                      },
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
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