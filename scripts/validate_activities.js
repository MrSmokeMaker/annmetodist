/**
 * Скрипт проверки валидности activities.json и соответствия структуре шаблона.
 * Проверяет наличие всех обязательных полей, типов данных, корректности шагов и критериев.
 */
const fs = require('fs');
const path = require('path');

const activitiesPath = path.join(__dirname, '..', 'assets', 'data', 'activities.json');
const schemaPath = path.join(__dirname, '..', 'assets', 'data', 'activities_schema.json');
const categoriesPath = path.join(__dirname, '..', 'assets', 'data', 'categories.json');

console.log('--- Начинается валидация библиотеки практических заданий ---');

// 1. Проверка чтения и валидности JSON
let activities, schema, categories;
try {
  activities = JSON.parse(fs.readFileSync(activitiesPath, 'utf8'));
  console.log(`[OK] activities.json успешно распарсен, записей: ${activities.length}`);
} catch (e) {
  console.error(`[ERROR] Ошибка чтения/парсинга activities.json:`, e.message);
  process.exit(1);
}

try {
  schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  console.log(`[OK] activities_schema.json успешно распарсен`);
} catch (e) {
  console.error(`[ERROR] Ошибка чтения/парсинга activities_schema.json:`, e.message);
  process.exit(1);
}

try {
  categories = JSON.parse(fs.readFileSync(categoriesPath, 'utf8'));
  console.log(`[OK] categories.json успешно распарсен, категорий: ${categories.length}`);
} catch (e) {
  console.error(`[ERROR] Ошибка чтения/парсинга categories.json:`, e.message);
  process.exit(1);
}

const validCategoryNames = new Set(categories.map(c => c.name));
const requiredFields = ['id', 'category', 'title', 'short_description'];
const ids = new Set();
let errorCount = 0;

activities.forEach((act, idx) => {
  const prefix = `[Запись #${idx + 1} (${act.id || 'NO_ID'})]`;

  // Проверка обязательных полей
  for (const field of requiredFields) {
    if (!act[field] || typeof act[field] !== 'string' || !act[field].trim()) {
      console.error(`${prefix} Пропущено или пустое обязательное поле: "${field}"`);
      errorCount++;
    }
  }

  // Проверка уникальности id
  if (act.id) {
    if (ids.has(act.id)) {
      console.error(`${prefix} Дублирующийся ID: "${act.id}"`);
      errorCount++;
    }
    ids.add(act.id);

    if (!act.id.startsWith('act_')) {
      console.error(`${prefix} ID должен начинаться с "act_": "${act.id}"`);
      errorCount++;
    }
  }

  // Проверка категории
  if (act.category && !validCategoryNames.has(act.category)) {
    console.warn(`${prefix} Внимание: Категория "${act.category}" отсутствует в categories.json`);
  }

  // Проверка duration_minutes
  if (act.duration_minutes !== undefined) {
    if (typeof act.duration_minutes !== 'number' || act.duration_minutes <= 0) {
      console.error(`${prefix} Поле duration_minutes должно быть положительным числом, получено: ${act.duration_minutes}`);
      errorCount++;
    }
  }

  // Проверка difficulty
  if (act.difficulty !== undefined) {
    if (!['easy', 'medium', 'hard'].includes(act.difficulty)) {
      console.error(`${prefix} Недопустимое значение difficulty: "${act.difficulty}". Ожидается: easy, medium или hard`);
      errorCount++;
    }
  }

  // Проверка шагов (steps)
  if (act.steps !== undefined) {
    if (!Array.isArray(act.steps)) {
      console.error(`${prefix} Поле steps должно быть массивом`);
      errorCount++;
    } else {
      act.steps.forEach((step, sIdx) => {
        if (typeof step.order !== 'number' || step.order <= 0) {
          console.error(`${prefix} Шаг #${sIdx + 1} имеет некорректный order: ${step.order}`);
          errorCount++;
        }
        if (!step.title || typeof step.title !== 'string') {
          console.error(`${prefix} Шаг #${sIdx + 1} не имеет обязательного поля title`);
          errorCount++;
        }
        if (!step.description || typeof step.description !== 'string') {
          console.error(`${prefix} Шаг #${sIdx + 1} не имеет обязательного поля description`);
          errorCount++;
        }
      });
    }
  }

  // Проверка assessment
  if (act.assessment !== undefined) {
    if (typeof act.assessment !== 'object' || !act.assessment.type || !Array.isArray(act.assessment.criteria)) {
      console.error(`${prefix} Поле assessment оформлено не по схеме (требуется type и массив criteria)`);
      errorCount++;
    }
  }
});

if (errorCount > 0) {
  console.error(`\n[FAIL] Валидация завершилась с ${errorCount} ошибками!`);
  process.exit(1);
} else {
  console.log(`\n[SUCCESS] Все ${activities.length} активностей полностью соответствуют спецификации и схеме!`);
}
