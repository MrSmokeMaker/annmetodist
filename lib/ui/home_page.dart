import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conspect_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConspectProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Методист – генерация конспекта')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Тема/запрос',
                hintText: 'Введите запрос для генерации конспекта',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final prompt = _controller.text.trim();
                      if (prompt.isNotEmpty) {
                        await provider.generateConspect(prompt);
                      }
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Сгенерировать'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  provider.result,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
