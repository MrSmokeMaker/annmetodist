/**
 * Скрипт проверки целостности и полноты базы тем (topics.json).
 * Проверяет покрытие всех 7 классических методик, наличие тем для всех возрастов,
 * уникальность идентификаторов и корректность заполнения полей.
 */
const fs = require('fs');
const path = require('path');

const topicsPath = path.join(__dirname, '..', 'assets', 'data', 'topics.json');
const methodsPath = path.join(__dirname, '..', 'assets', 'data', 'methods.json');

console.log('--- Начинается валидация базы тем уроков (topics.json) ---');

let topics, methods;
try {
  topics = JSON.parse(fs.readFileSync(topicsPath, 'utf8'));
  console.log(`[OK] topics.json успешно загружен, всего тем: ${topics.length}`);
} catch (e) {
  console.error('[ERROR] Ошибка чтения topics.json:', e.message);
  process.exit(1);
}

try {
  methods = JSON.parse(fs.readFileSync(methodsPath, 'utf8'));
  console.log(`[OK] methods.json успешно загружен, методик: ${methods.length}`);
} catch (e) {
  console.error('[ERROR] Ошибка чтения methods.json:', e.message);
  process.exit(1);
}

const methodIds = new Set(methods.map(m => m.id));
const validAgeGroups = new Set(['preschool', 'grade_1', 'grade_2']);

const topicIds = new Set();
let errorCount = 0;
const coverage = {};

methods.forEach(m => {
  coverage[m.id] = { preschool: 0, grade_1: 0, grade_2: 0, total: 0 };
});

topics.forEach((t, idx) => {
  const prefix = `[Тема #${idx + 1} (${t.id || 'NO_ID'})]`;

  if (!t.id || typeof t.id !== 'string') {
    console.error(`${prefix} Отсутствует или некорректен id`);
    errorCount++;
  } else if (topicIds.has(t.id)) {
    console.error(`${prefix} Дублирующийся id: "${t.id}"`);
    errorCount++;
  } else {
    topicIds.add(t.id);
  }

  if (!t.methodId || !methodIds.has(t.methodId)) {
    console.error(`${prefix} Неизвестный methodId: "${t.methodId}"`);
    errorCount++;
  }

  if (!t.ageGroup || !validAgeGroups.has(t.ageGroup)) {
    console.error(`${prefix} Недопустимая возрастная группа: "${t.ageGroup}"`);
    errorCount++;
  }

  if (!t.title || typeof t.title !== 'string' || t.title.trim().length < 3) {
    console.error(`${prefix} Слишком короткое или пустое название (title)`);
    errorCount++;
  }

  if (t.methodId && t.ageGroup && coverage[t.methodId]) {
    coverage[t.methodId][t.ageGroup]++;
    coverage[t.methodId].total++;
  }
});

console.log('\n--- Охват тем по методикам и возрастам ---');
let hasMissingAges = false;
methods.forEach(m => {
  const stat = coverage[m.id];
  console.log(`• ${m.name} (${m.id}): Всего ${stat.total} [Дошкольники: ${stat.preschool}, 1 класс: ${stat.grade_1}, 2 класс: ${stat.grade_2}]`);
  if (stat.preschool === 0 || stat.grade_1 === 0 || stat.grade_2 === 0) {
    console.error(`[FAIL] Для методики "${m.id}" отсутствует покрытие для одного из возрастов!`);
    hasMissingAges = true;
    errorCount++;
  }
});

if (errorCount > 0 || hasMissingAges) {
  console.error(`\n[FAIL] Валидация завершилась с ${errorCount} ошибками!`);
  process.exit(1);
} else {
  console.log(`\n[SUCCESS] База тем полностью верифицирована! 100% методик покрыты для всех возрастов (всего тем: ${topics.length})`);
}
