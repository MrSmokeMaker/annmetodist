const fs = require('fs');
const methods = require('../assets/data/methods.json');
const topics = require('../assets/data/topics.json');

const byMethod = {};
methods.forEach(m => byMethod[m.id] = { name: m.name, subject: m.subject, topics: [] });
topics.forEach(t => {
  if (byMethod[t.methodId]) {
    byMethod[t.methodId].topics.push(t);
  }
});

let out = '# Полный реестр 173 тем приложения «Методист»\n\n';
for (const mId in byMethod) {
  const m = byMethod[mId];
  out += `## ${m.subject}: ${m.name} (${m.topics.length} тем)\n\n`;
  const ages = { preschool: 'Дошкольники (4–6 лет)', grade_1: '1 класс', grade_2: '2 класс' };
  for (const ageKey in ages) {
    const list = m.topics.filter(t => t.ageGroup === ageKey);
    if (list.length > 0) {
      out += `### ${ages[ageKey]} (${list.length} тем)\n`;
      list.forEach((t, i) => {
        out += `${i + 1}. **${t.title}** (id: \`${t.id}\`)\n`;
      });
      out += '\n';
    }
  }
}
fs.writeFileSync('docs/all_173_topics_register.md', out, 'utf8');
console.log('Saved docs/all_173_topics_register.md, bytes:', out.length);
