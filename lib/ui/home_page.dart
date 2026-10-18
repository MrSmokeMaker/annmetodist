import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/conspect_provider.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _hasCheckedCredentials = false;
  bool _hasCredentials = true;

  final List<String> _quickPresets = [
    'Русский язык: правописание безударных гласных в корне (2 класс)',
    'Математика: состав числа 10, методика Пчелко (1 класс)',
    'Чистописание: элементы строчных букв, метод Боголюбова',
    'Литературное чтение: звуковой анализ по Редозубову',
  ];

  @override
  void initState() {
    super.initState();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final provider = context.read<ConspectProvider>();
    final ok = await provider.hasCredentials();
    if (mounted) {
      setState(() {
        _hasCredentials = ok;
        _hasCheckedCredentials = true;
      });
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    _checkCredentials();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConspectProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Методист — Генератор конспектов'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки API YandexGPT',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasCheckedCredentials && !_hasCredentials) ...[
                Card(
                  color: Colors.amber.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.amber.shade400),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API-ключ или Folder ID не заполнены.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openSettings,
                          child: const Text('Настроить'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Тема урока или методический запрос',
                  hintText: 'Например: Урок математики во 2 классе на тему...',
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPresets.map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        label: Text(
                          preset.length > 30
                              ? '${preset.substring(0, 30)}...'
                              : preset,
                          style: const TextStyle(fontSize: 12),
                        ),
                        tooltip: preset,
                        onPressed: () {
                          setState(() {
                            _controller.text = preset;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: provider.isLoading ||
                              _controller.text.trim().isEmpty
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              await provider.generateConspect(
                                _controller.text.trim(),
                              );
                            },
                      icon: provider.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        provider.isLoading
                            ? 'Генерация...'
                            : 'Сгенерировать конспект',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (provider.hasResult) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Скопировать конспект',
                      onPressed: () async {
                        await provider.copyToClipboard();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Конспект скопирован в буфер обмена'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Очистить',
                      onPressed: () {
                        provider.clearResult();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: provider.isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Составляем конспект урока с помощью YandexGPT...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : provider.errorMessage != null
                          ? Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      provider.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _openSettings,
                                      icon: const Icon(Icons.settings),
                                      label: const Text('Открыть настройки'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : provider.hasResult
                              ? Markdown(
                                  data: provider.result,
                                  selectable: true,
                                )
                              : const Center(
                                  child: Text(
                                    'Введите тему урока или выберите шаблон выше и нажмите «Сгенерировать конспект».',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
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
