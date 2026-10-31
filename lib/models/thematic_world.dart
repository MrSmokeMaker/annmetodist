import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

enum ThematicWorldType {
  space,
  forest,
  detective,
  workshop,
  meadow,
}

class ThematicWorld {
  final ThematicWorldType type;
  final String id;
  final String title;
  final String mascotName;
  final String mascotRole;
  final String missionBadge;
  final int primaryColorHex;
  final int secondaryColorHex;
  final int accentColorHex;
  final String bannerPrompt;
  final String mascotPrompt;

  const ThematicWorld({
    required this.type,
    required this.id,
    required this.title,
    required this.mascotName,
    required this.mascotRole,
    required this.missionBadge,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.bannerPrompt,
    required this.mascotPrompt,
  });

  Color get primaryColor => Color(primaryColorHex);
  Color get secondaryColor => Color(secondaryColorHex);
  Color get accentColor => Color(accentColorHex);

  PdfColor get pdfPrimary => PdfColor.fromInt(primaryColorHex);
  PdfColor get pdfSecondary => PdfColor.fromInt(secondaryColorHex);
  PdfColor get pdfAccent => PdfColor.fromInt(accentColorHex);

  // 1. Космос и вычисления
  static const space = ThematicWorld(
    type: ThematicWorldType.space,
    id: 'space',
    title: 'Звёздная Одиссея',
    mascotName: 'Лисёнок Астро',
    mascotRole: 'Командир экспедиции',
    missionBadge: 'КОСМИЧЕСКАЯ МИССИЯ',
    primaryColorHex: 0xFF1E1B4B, // Deep Indigo
    secondaryColorHex: 0xFF312E81,
    accentColorHex: 0xFFF59E0B, // Golden star
    bannerPrompt: 'панорамная горизонтальная шапка для детского учебного листа, космос, звезды, полумесяц, ракета, планеты, советская книжная акварель 4:1, чистый фон, без текста',
    mascotPrompt: 'милый рыжий лисенок космонавт в белом круглом скафандре с флажком, улыбается, советский мультипликационный стиль, белый фон, изолированно',
  );

  // 2. Сказочный лес и грамота
  static const forest = ThematicWorld(
    type: ThematicWorldType.forest,
    id: 'forest',
    title: 'Заповедный лес Грамотеев',
    mascotName: 'Сова-Профессор Филя',
    mascotRole: 'Хранитель живого слова',
    missionBadge: 'ТАЙНА ЖИВОГО СЛОВА',
    primaryColorHex: 0xFF064E3B, // Forest Emerald
    secondaryColorHex: 0xFF047857,
    accentColorHex: 0xFFD97706, // Amber
    bannerPrompt: 'горизонтальная панорамная иллюстрация для шапки детского листа, сказочный дубовый лес, солнечные лучи, мох, цветы, советская книжная акварель 4:1, без текста',
    mascotPrompt: 'мудрая добрая сова в круглых очках держит гусиное перо и свиток, лесной учитель, советская книжная графика, белый фон, изолированно',
  );

  // 3. Детективное агентство и поиск ловушек
  static const detective = ThematicWorld(
    type: ThematicWorldType.detective,
    id: 'detective',
    title: 'Агентство Незнайкиных Ошибок',
    mascotName: 'Енот-Следопыт Шерлок',
    mascotRole: 'Главный сыщик ловушек',
    missionBadge: 'ДЕТЕКТИВНОЕ РАССЛЕДОВАНИЕ',
    primaryColorHex: 0xFF451A03, // Warm Chocolate
    secondaryColorHex: 0xFF78350F,
    accentColorHex: 0xFFEAB308, // Gold
    bannerPrompt: 'панорамный горизонтальный фон детского листа заданий, детективный столик, лупа, компас, старинные свитки, отпечатки следов, теплая винтажная акварель 4:1, без текста',
    mascotPrompt: 'дружелюбный енот сыщик в клетчатой кепке с большой лупой в лапках, улыбается, ищет подсказки, книжная графика для детей, чистый белый фон, изолированно',
  );

  // 4. Инженерная мастерская и геометрия
  static const workshop = ThematicWorld(
    type: ThematicWorldType.workshop,
    id: 'workshop',
    title: 'Мастерская Точных Механизмов',
    mascotName: 'Бобрёнок-Инженер Винтик',
    mascotRole: 'Мастер точных чертежей',
    missionBadge: 'ИНЖЕНЕРНЫЙ ЧЕРТЁЖ',
    primaryColorHex: 0xFF1E3A8A, // Blueprint Blue
    secondaryColorHex: 0xFF1D4ED8,
    accentColorHex: 0xFFFACC15, // Tool Yellow
    bannerPrompt: 'панорамная горизонтальная шапка рабочего листа, мастерская юного инженера, чертежи на миллиметровке, деревянные линейки, шестеренки, кубики, светлый фон 4:1, без текста',
    mascotPrompt: 'веселый бобренок строитель с деревянной линейкой и карандашом, в рабочем жилетике, улыбается, советский мультипликационный стиль, чистый белый фон, изолированно',
  );

  // 5. Солнечная полянка малышей (дошкольники)
  static const meadow = ThematicWorld(
    type: ThematicWorldType.meadow,
    id: 'meadow',
    title: 'Солнечная Полянка Малышей',
    mascotName: 'Медвежонок Миша и Пчёлка',
    mascotRole: 'Весёлые друзья-помощники',
    missionBadge: 'СОЛНЕЧНЫЕ ОТКРЫТИЯ',
    primaryColorHex: 0xFF0284C7, // Sky Cyan
    secondaryColorHex: 0xFF0369A1,
    accentColorHex: 0xFFF43F5E, // Rose
    bannerPrompt: 'детская яркая панорамная иллюстрация для шапки, зеленая полянка, ромашки, земляника, радуга и белые пушистые облака, солнце, мягкие пастельные тона 4:1, без текста',
    mascotPrompt: 'добрый пушистый медвежонок с воздушным шариком и маленькая улыбающаяся пчелка, стиль детских книг, яркие сочные цвета, чистый белый фон, изолированно',
  );

  static const List<ThematicWorld> allWorlds = [
    space,
    forest,
    detective,
    workshop,
    meadow,
  ];

  static ThematicWorld fromId(String? id) {
    if (id == null) return space;
    return allWorlds.firstWhere(
      (w) => w.id == id,
      orElse: () => space,
    );
  }

  String mascotEncouragement(String materialTypeName) {
    switch (type) {
      case ThematicWorldType.space:
        return 'Полный вперёд к космическим открытиям!';
      case ThematicWorldType.forest:
        return 'Слово за словом — и тайна откроется!';
      case ThematicWorldType.detective:
        return 'Найди все ловушки и раскрой секрет!';
      case ThematicWorldType.workshop:
        return 'Точный расчёт — верный результат!';
      case ThematicWorldType.meadow:
        return 'Учимся весело, играем дружно!';
    }
  }

  /// Интеллектуальный роутер: автоматически определяет наилучший мир для любой темы
  static ThematicWorld fromTopic({
    required String topic,
    required String subject,
    required String ageGroup,
    String? methodId,
  }) {
    final tLower = topic.toLowerCase();
    final sLower = subject.toLowerCase();
    final aLower = ageGroup.toLowerCase();
    final mLower = (methodId ?? '').toLowerCase();

    // 1. Дошкольники (4-5 лет) -> Мир малышей
    if (aLower.contains('дошкол') || aLower.contains('preschool') || aLower.contains('4-5') || aLower.contains('5-6')) {
      return meadow;
    }

    // 2. Геометрия, чертежи, доли, смысл умножения/деления -> Мастерская инженера
    if (anyWord(tLower, ['отрез', 'чертеж', 'периметр', 'линейк', 'сантиметр', 'дециметр', 'умножен', 'делен', 'геометрич', 'фигур'])) {
      return workshop;
    }

    // 3. Орфографические ловушки, проверка ошибок, корень, парные согласные, ТРИЗ -> Детективное агентство
    if (anyWord(tLower, ['ловушк', 'ошибк', 'парные согласн', 'безударн', 'непроизносим', 'корен', 'приставк', 'правописан', 'триз', 'правило'])) {
      return detective;
    }

    // 4. Чтение, звуки, буквы, чистописание, словарные слова -> Заповедный лес
    if (sLower.contains('чтен') ||
        sLower.contains('русск') ||
        sLower.contains('чистопис') ||
        mLower.contains('redozubov') ||
        mLower.contains('kostin') ||
        mLower.contains('mazina') ||
        mLower.contains('bogolyubov') ||
        mLower.contains('kosinova') ||
        anyWord(tLower, ['звук', 'букв', 'слог', 'ударен', 'каллиграф', 'текст', 'изложен'])) {
      return forest;
    }

    // 5. Математика, счет, задачи, шифровки -> Звёздная Одиссея
    return space;
  }

  static bool anyWord(String text, List<String> words) {
    for (final w in words) {
      if (text.contains(w)) return true;
    }
    return false;
  }
}
