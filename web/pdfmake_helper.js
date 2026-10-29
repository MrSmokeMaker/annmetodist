// PDF generation helper for worksheet and homework
// Supports Cyrillic via Nunito font loaded in custom_vfs_fonts.js

window.createWorksheetPdf = function(jsonStr) {
  try {
    const data = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;
    const isWorksheet = data.generationType === 'worksheet';
    const defaultTitle = isWorksheet ? 'Лист заданий' : 'Домашнее задание';
    const mainTitle = (data.topic && data.topic.trim()) || data.title || defaultTitle;
    const fileName = `${defaultTitle.replace(/\s+/g, '_')}_${(data.topic || '').replace(/[^a-zA-Zа-яА-Я0-9_]/g, '_').slice(0, 20)}_${Date.now()}.pdf`;

    // Vector icons (SVG)
    const iconMap = {
      star: '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpolygon points="12,2 15,11 24,11 17,17 19,26 12,21 5,26 7,17 0,11 9,11" fill="#6366F1"/\u003e\u003c/svg\u003e',
      pencil: '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.9959.9959 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="#8B5CF6"/\u003e\u003c/svg\u003e',
      check: '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="#10B981"/\u003e\u003c/svg\u003e',
      bookmark: '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2z" fill="#EC4899"/\u003e\u003c/svg\u003e',
      // custom icons for basic tasks
      'icon-dictation': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 4h16v2H4zM4 10h16v2H4zM4 16h16v2H4z" fill="currentColor"/\u003e\u003c/svg\u003e',
      'icon-copy': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M8 4h12v12H8zM6 6v12H4V6a2 2 0 012-2z" fill="none" stroke="currentColor" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-missing-letter': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M12 8v8M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/\u003e\u003c/svg\u003e',
      'icon-capital': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="16" text-anchor="middle" font-size="16" fill="currentColor"\u003eA\u003c/text\u003e\u003c/svg\u003e',
      'icon-transfer': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M6 12h12M12 6l6 6-6 6" stroke="currentColor" stroke-width="2" fill="none"/\u003e\u003c/svg\u003e',
      // placeholders for remaining task icons
      'icon-underline': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect width="24" height="24" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-soft-sign': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="12" cy="12" r="10" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-letter-y': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpolygon points="12,2 22,22 2,22" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-unscramble': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cline x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-make-word-from-syllables': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 4h16v16H4z" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-missing-syllable': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="6" y="6" width="12" height="12" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-make-sentence': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpolyline points="4,12 12,4 20,12" fill="none" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-count-sounds-letters': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e1\u003c/text\u003e\u003c/svg\u003e',
      'icon-find-mistake': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M2 12h20" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-one-many': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="8" cy="12" r="4" fill="#E5E7EB"/\u003e\u003ccircle cx="16" cy="12" r="4" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-finish-sentence': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cline x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-vocabulary-word': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="4" y="4" width="16" height="16" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      // math icons placeholders
      'icon-math-examples': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e+\u003c/text\u003e\u003c/svg\u003e',
      'icon-missing-number': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="8" y="8" width="8" height="8" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-compare-numbers': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="12" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e\u003c\u003e\u003c/text\u003e\u003c/svg\u003e',
      'icon-number-composition': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpolygon points="4,20 20,20 12,4" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-word-problem': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 4h16v16H4z" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-count-objects': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="12" cy="12" r="8" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-continue-sequence': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpolyline points="4,12 12,4 20,12" fill="none" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-chain-examples': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-math-dictation': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e✍\u003c/text\u003e\u003c/svg\u003e',
      'icon-odd-one-out': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="12" cy="12" r="10" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-color-by-number': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect width="24" height="24" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      // reading icons placeholders
      'icon-read-syllables': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e§\u003c/text\u003e\u003c/svg\u003e',
      'icon-match-word-picture': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="4" y="4" width="16" height="16" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-first-last-sound': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ctext x="12" y="12" text-anchor="middle" font-size="12" fill="#E5E7EB"\u003e🔊\u003c/text\u003e\u003c/svg\u003e',
      'icon-find-sound-word': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="12" cy="12" r="8" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-repeat-tongue-twister': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-finish-rhyme': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-describe-picture': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="2" y="2" width="20" height="20" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      // handwriting icons placeholders
      'icon-trace-elements': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 4h16v16H4z" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-complete-element': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cline x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/\u003e\u003c/svg\u003e',
      'icon-cell-pattern': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="4" y="4" width="16" height="16" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-graphic-dictation': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003cpath d="M4 4h16v16H4z" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      // preschool icons placeholders
      'icon-shadow-match': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003ccircle cx="12" cy="12" r="10" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
      'icon-find-pair': '\u003csvg width="20" height="20" viewBox="0 0 24 24"\u003e\u003crect x="6" y="6" width="12" height="12" fill="#E5E7EB"/\u003e\u003c/svg\u003e',
    };


    const count = parseInt(data.tasksCount, 10) || 5;
    const withAnswers = data.withAnswers === true;
    const ageGroupLabel = data.ageGroup === 'preschool' ? 'Дошкольники' : (data.ageGroup === 'grade_2' ? '2 класс' : '1 класс');
    const duration = data.duration || '45 мин';

    const docDefinition = {
      pageSize: 'A4',
      pageMargins: [48, 36, 30, 36],
      defaultStyle: {
        font: 'Nunito',
        fontSize: 11,
        color: '#1E293B',
        lineHeight: 1.3
      },
      styles: {
        typeBadge: {
          fontSize: 10,
          bold: true,
          color: '#6366F1'
        },
        docTitle: {
          fontSize: 20,
          bold: true,
          color: '#0F172A',
          margin: [0, 4, 0, 8]
        },
        metaText: {
          fontSize: 10,
          color: '#64748B'
        },
        sectionHeading: {
          fontSize: 14,
          bold: true,
          color: '#1E293B',
          margin: [0, 15, 0, 8]
        },
        taskNumber: {
          fontSize: 11,
          bold: true,
          color: '#4F46E5'
        },
        taskBody: {
          fontSize: 11,
          color: '#334155'
        },
        notesBox: {
          fontSize: 10,
          color: '#475569',
          italics: false
        }
      },
      content: [
        // Header Banner
        {
          columns: [
            {
              width: '*',
              stack: [
                { text: defaultTitle.toUpperCase(), style: 'typeBadge' },
                { text: mainTitle, style: 'docTitle' },
                {
                  text: `Возрастная группа: ${ageGroupLabel}   |   Рекомендуемое время: ${duration}`,
                  style: 'metaText'
                }
              ]
            },
            {
              width: 120,
              alignment: 'right',
              stack: [
                { text: 'Имя ученика: ________________', fontSize: 9, color: '#94A3B8', margin: [0, 8, 0, 6] },
                { text: 'Дата: ______________', fontSize: 9, color: '#94A3B8' }
              ]
            }
          ]
        },
        {
          canvas: [
            {
              type: 'line',
              x1: 0,
              y1: 12,
              x2: 515,
              y2: 12,
              lineWidth: 1.5,
              lineColor: '#E2E8F0'
            }
          ],
          margin: [0, 0, 0, 14]
        }
      ]
    };


    // Optional teacher notes in header
    if (data.notes && data.notes.trim()) {
      docDefinition.content.push({
        table: {
          widths: ['*'],
          body: [
            [
              {
                text: `Примечание: ${data.notes.trim()}`,
                style: 'notesBox',
                fillColor: '#F8FAFC',
                border: [false, false, false, false],
                margin: [8, 6, 8, 6]
              }
            ]
          ]
        },
        margin: [0, 0, 0, 14]
      });
    }

    // Tasks
    const renderers = {
      placeholder(taskPayload) {
        const taskText = typeof taskPayload.template === 'string' && taskPayload.template.trim()
          ? taskPayload.template.trim()
          : 'Выполните задание по теме занятия.';
        return [
          { text: taskText, style: 'taskBody', margin: [0, 0, 0, 4] },
          { text: 'Ответ: _______________________________________________', color: '#64748B', fontSize: 10 }
        ];
      },

      // Табличное задание (грибы, леса, моря)
      renderTableTask(taskPayload) {
        const params = taskPayload.params || {};
        const theme = params.theme || 'Таблица';
        const rows = Array.isArray(params.rows) ? params.rows : [];
        if (rows.length === 0) {
          return [{ text: 'Нет данных для таблицы', style: 'taskBody', margin: [0, 0, 0, 4] }];
        }
        const keys = Object.keys(rows[0]);
        const body = [];
        // Заголовок
        body.push(keys.map(k => ({ text: k.toUpperCase(), bold: true, fillColor: '#E8F5E9', fontSize: 9, margin: [4, 6] })));
        // Строки
        rows.forEach((row, i) => {
          body.push(keys.map(k => ({ text: String(row[k] ?? ''), fontSize: 9, margin: [4, 6] })));
        });
        return [
          { text: theme, style: 'taskHeading', margin: [0, 0, 0, 6] },
          {
            table: {
              widths: keys.map(() => '*'),
              body: body
            },
            layout: 'lightHorizontalLines',
            margin: [0, 0, 0, 8]
          },
          { text: '_______________________________________', color: '#64748B', fontSize: 10, margin: [0, 4, 0, 0] }
        ];
      },

      // Кроссворд клетками (без линий)
      renderCrosswordGrid(taskPayload) {
        const params = taskPayload.params || {};
        const gridSize = params.gridSize || 10;
        const cells = Array.isArray(params.cells) ? params.cells : [];
        const cluesAcross = Array.isArray(params.cluesAcross) ? params.cluesAcross : [];
        const cluesDown = Array.isArray(params.cluesDown) ? params.cluesDown : [];

        const gridRows = [];
        for (let r = 0; r < gridSize; r++) {
          const rowCells = [];
          for (let c = 0; c < gridSize; c++) {
            const idx = r * gridSize + c;
            const cell = idx < cells.length ? cells[idx] : null;
            const isBlack = cell && cell.black === true;
            const number = cell && cell.number != null ? cell.number : '';
            rowCells.push({
              text: isBlack ? '' : number,
              width: 18,
              height: 18,
              alignment: 'center',
              fontSize: number ? 6 : 10,
              fillColor: isBlack ? '#000000' : undefined,
              color: isBlack ? '#FFFFFF' : '#000000',
              border: [true, true, true, true],
              margin: [0, 0, 0, 0]
            });
          }
          gridRows.push(rowCells);
        }

        const content = [
          { text: 'Кроссворд клетками', style: 'taskHeading', margin: [0, 0, 0, 6] },
          {
            table: {
              widths: Array(gridSize).fill(18),
              body: gridRows
            },
            layout: {
              hLineWidth: () => 0.6,
              vLineWidth: () => 0.6,
              hLineColor: () => '#333333',
              vLineColor: () => '#333333'
            },
            margin: [0, 0, 0, 10]
          }
        ];

        if (cluesAcross.length > 0) {
          content.push({ text: 'По горизонтали:', bold: true, fontSize: 9, margin: [0, 2, 0, 2] });
          cluesAcross.forEach((clue, i) => {
            content.push({ text: `${i + 1}. ${clue}`, fontSize: 9, margin: [8, 1, 0, 1] });
          });
        }

        if (cluesDown.length > 0) {
          content.push({ text: 'По вертикали:', bold: true, fontSize: 9, margin: [0, 6, 0, 2] });
          cluesDown.forEach((clue, i) => {
            content.push({ text: `${i + 1}. ${clue}`, fontSize: 9, margin: [8, 1, 0, 1] });
          });
        }

        return content;
      },

      // Соединялка стрелками (matching)
      renderMatchingPairs(taskPayload) {
        const params = taskPayload.params || {};
        const leftCol = Array.isArray(params.leftCol) && params.leftCol.length > 0
          ? params.leftCol
          : ['Понятие 1', 'Понятие 2', 'Понятие 3', 'Понятие 4'];
        const rightCol = Array.isArray(params.rightCol) && params.rightCol.length > 0
          ? params.rightCol
          : ['Значение Б', 'Значение А', 'Значение Г', 'Значение В'];

        const rows = [];
        const maxLen = Math.max(leftCol.length, rightCol.length);
        for (let i = 0; i < maxLen; i++) {
          rows.push({
            columns: [
              { width: '45%', text: (leftCol[i] || '') + '  ○', alignment: 'right', bold: true, fontSize: 10, margin: [0, 3, 10, 3] },
              { width: '10%', text: '••••', alignment: 'center', color: '#CBD5E1', fontSize: 9, margin: [0, 3, 0, 3] },
              { width: '45%', text: '○  ' + (rightCol[i] || ''), alignment: 'left', fontSize: 10, margin: [10, 3, 0, 3] }
            ]
          });
        }

        return [
          { text: '🔗 Соедини пары стрелками:', bold: true, fontSize: 11, color: '#4338CA', margin: [0, 0, 0, 6] },
          {
            table: {
              widths: ['*'],
              body: [
                [{
                  fillColor: '#F8FAFC',
                  stack: rows,
                  margin: [6, 6, 6, 6]
                }]
              ]
            },
            layout: {
              hLineWidth: () => 0.8,
              vLineWidth: () => 0.8,
              hLineColor: () => '#E2E8F0',
              vLineColor: () => '#E2E8F0'
            }
          }
        ];
      },

      // Ловушка Незнайки (Bug Hunt)
      renderBugHunt(taskPayload) {
        const params = taskPayload.params || {};
        const character = params.character || 'Незнайка';
        const textWithErrors = params.textWithErrors || '«Жыраф пошол в лесную чащю за грибоми.»';

        return [
          { text: '🕵️‍♂️ ЛОВУШКА НЕЗНАЙКИ: найди и исправь 2 ошибки', bold: true, fontSize: 11, color: '#DC2626', margin: [0, 0, 0, 4] },
          {
            table: {
              widths: ['*'],
              body: [
                [{
                  fillColor: '#FEF2F2',
                  stack: [
                    { text: character + ' написал ответ с ошибками:', italics: true, fontSize: 9, color: '#991B1B', margin: [0, 0, 0, 4] },
                    { text: textWithErrors, bold: true, fontSize: 11, color: '#1E293B', margin: [4, 2, 4, 6] },
                    { text: 'Твой правильный ответ:', fontSize: 9, color: '#64748B', margin: [0, 2, 0, 2] },
                    { text: '___________________________________________________________', color: '#CBD5E1', fontSize: 11 },
                    { text: '___________________________________________________________', color: '#CBD5E1', fontSize: 11 }
                  ],
                  margin: [6, 6, 6, 6]
                }]
              ]
            },
            layout: {
              hLineWidth: () => 1,
              vLineWidth: () => 1,
              hLineColor: () => '#FCA5A5',
              vLineColor: () => '#FCA5A5'
            }
          }
        ];
      },

      // Числовой домик (Number House)
      renderNumberHouse(taskPayload) {
        const params = taskPayload.params || {};
        const targetNumber = params.targetNumber || 7;
        const floors = Array.isArray(params.floors) && params.floors.length > 0
          ? params.floors
          : [{ a: 1, b: null }, { a: null, b: 5 }, { a: 3, b: null }, { a: null, b: 3 }, { a: 5, b: null }];

        const tableBody = [
          [{ text: 'КРЫША:  ' + targetNumber, colSpan: 2, alignment: 'center', bold: true, fontSize: 13, fillColor: '#E0E7FF', color: '#3730A3' }, {}]
        ];

        floors.forEach(f => {
          tableBody.push([
            { text: f.a !== null && f.a !== undefined ? String(f.a) : '?', alignment: 'center', bold: true, fontSize: 11, fillColor: f.a === null ? '#FFFBEB' : '#FFFFFF', margin: [0, 3, 0, 3] },
            { text: f.b !== null && f.b !== undefined ? String(f.b) : '?', alignment: 'center', bold: true, fontSize: 11, fillColor: f.b === null ? '#FFFBEB' : '#FFFFFF', margin: [0, 3, 0, 3] }
          ]);
        });

        return [
          { text: '🏠 Числовой домик: засели жильцов (состав числа ' + targetNumber + ')', bold: true, fontSize: 11, color: '#4F46E5', margin: [0, 0, 0, 4] },
          {
            table: {
              widths: [80, 80],
              body: tableBody
            },
            layout: {
              hLineWidth: () => 1,
              vLineWidth: () => 1,
              hLineColor: () => '#C7D2FE',
              vLineColor: () => '#C7D2FE'
            },
            margin: [20, 4, 0, 4]
          }
        ];
      },

      // Секретный шифр (Cipher)
      renderCipherCode(taskPayload) {
        const params = taskPayload.params || {};
        const code = params.codedMessage || '15 • 1 • 20 • 6 • 14 • 1 • 20 • 10 • 12 • 1';
        const hint = params.hint || 'Ключ шифра: 1=А, 6=Е, 10=И, 12=К, 14=М, 15=О, 20=Т';

        return [
          { text: '🔍 Секретный шифр детектива: расшифруй слово', bold: true, fontSize: 11, color: '#0D9488', margin: [0, 0, 0, 4] },
          {
            table: {
              widths: ['*'],
              body: [
                [{
                  fillColor: '#F0FDFA',
                  stack: [
                    { text: hint, fontSize: 9, bold: true, color: '#115E59', margin: [0, 0, 0, 4] },
                    { text: 'Зашифрованный код: ' + code, bold: true, fontSize: 12, color: '#0F766E', margin: [0, 2, 0, 4] },
                    { text: 'Ответ: ____________________________________________________', color: '#0F766E', fontSize: 10, margin: [0, 4, 0, 2] }
                  ],
                  margin: [6, 6, 6, 6]
                }]
              ]
            },
            layout: {
              hLineWidth: () => 1,
              vLineWidth: () => 1,
              hLineColor: () => '#99F6E4',
              vLineColor: () => '#99F6E4'
            }
          }
        ];
      },

      // Корзинка слов для справок (Word Bank)
      renderWordBankFill(taskPayload) {
        const params = taskPayload.params || {};
        const words = Array.isArray(params.wordBank) && params.wordBank.length > 0
          ? params.wordBank
          : ['лисица', 'берёза', 'снегирь', 'тропинка'];
        const sentences = Array.isArray(params.sentences) && params.sentences.length > 0
          ? params.sentences
          : ['1. В лесу растёт белоствольная ______________.', '2. Рыжая ______________ заметает следы хвостом.'];

        return [
          { text: '🧺 Вставь подходящие слова из корзинки справок:', bold: true, fontSize: 11, color: '#D97706', margin: [0, 0, 0, 4] },
          {
            table: {
              widths: ['*'],
              body: [
                [{
                  fillColor: '#FFFBEB',
                  stack: [
                    { text: 'Слова для справок: [ ' + words.join('  •  ') + ' ]', bold: true, fontSize: 10, color: '#B45309', alignment: 'center', margin: [0, 2, 0, 4] }
                  ],
                  margin: [4, 4, 4, 4]
                }]
              ]
            },
            layout: {
              hLineWidth: () => 0.8,
              vLineWidth: () => 0.8,
              hLineColor: () => '#FDE68A',
              vLineColor: () => '#FDE68A'
            },
            margin: [0, 0, 0, 6]
          },
          {
            stack: sentences.map(s => ({ text: s, fontSize: 10, color: '#1E293B', margin: [4, 3, 0, 3] }))
          }
        ];
      },

      // Задание с буквами и разлиновкой
      renderLetterTask(taskPayload) {
        const params = taskPayload.params || {};
        const letter = params.letter || 'А';
        const words = Array.isArray(params.words) ? params.words : [];

        const content = [
          {
            columns: [
              { width: 40, text: letter, bold: true, fontSize: 24, alignment: 'center', margin: [0, 0, 0, 0] },
              { width: '*', text: `Буква «${letter}»`, bold: true, fontSize: 12, margin: [8, 4, 0, 0] }
            ]
          },
          { text: '', margin: [0, 4, 0, 0] },
          { text: letter, fontSize: 18, bold: true, margin: [0, 0, 0, 8], color: '#7B1FA2' },
          // Разлинованные линии для письма
          { text: '____________________________', color: '#9C27B0', fontSize: 14, margin: [0, 2, 0, 4] },
          { text: '____________________________', color: '#9C27B0', fontSize: 14, margin: [0, 2, 0, 4] },
          { text: '____________________________', color: '#9C27B0', fontSize: 14, margin: [0, 2, 0, 4] },
          { text: '____________________________', color: '#9C27B0', fontSize: 14, margin: [0, 2, 0, 0] }
        ];

        if (words.length > 0) {
          content.push({ text: 'Слова для практики:', bold: true, fontSize: 9, margin: [0, 6, 0, 2] });
          content.push({ text: words.slice(0, 4).join('   '), fontSize: 10, margin: [0, 0, 0, 0] });
        }

        return content;
      }
    };
    const icons = ['star', 'pencil', 'bookmark', 'check'];
    for (let i = 1; i <= count; i++) {
      // Retrieve task payload from data.tasks or use placeholder
      const taskPayload = (data.tasks && data.tasks[i - 1]) || { id: 'placeholder', params: {}, template: '' };
      const renderer = renderers[taskPayload.id] || renderers.placeholder;
      const taskContent = renderer(taskPayload);
      const iconKey = icons[(i - 1) % icons.length];
      const taskSvg = iconMap[iconKey] || iconMap['star'];
      docDefinition.content.push({
        margin: taskSpacing,
        unbreakable: true,
        table: {
          dontBreakRows: true,
          widths: [24, '*'],
          body: [
            [
              {
                svg: taskSvg,
                width: 18,
                height: 18,
                alignment: 'center',
                margin: [0, 2, 0, 0],
                border: [false, false, false, false]
              },
              {
                stack: taskContent,
                border: [false, false, false, false]
              }
            ]
          ]
        }
      });
    }

    // Блок детской формирующей самооценки
    docDefinition.content.push({
      margin: [0, 14, 0, 8],
      unbreakable: true,
      table: {
        widths: ['*'],
        body: [
          [{
            fillColor: '#F8FAFC',
            stack: [
              {
                columns: [
                  { width: '*', text: '⭐⭐⭐ КАК Я СПРАВИЛСЯ С ЗАДАНИЯМИ:', bold: true, fontSize: 10, color: '#334155' },
                  { width: 180, text: 'Отметка / подпись: ____________', alignment: 'right', fontSize: 9, color: '#64748B' }
                ]
              },
              {
                margin: [0, 6, 0, 2],
                columns: [
                  { width: '33%', text: '🙂  Отлично (всё сам)', fontSize: 9, color: '#1E293B' },
                  { width: '33%', text: '😐  Хорошо (были вопросы)', fontSize: 9, color: '#1E293B' },
                  { width: '34%', text: '🙁  Трудно (нужна помощь)', fontSize: 9, color: '#1E293B' }
                ]
              }
            ],
            margin: [8, 8, 8, 8]
          }]
        ]
      },
      layout: {
        hLineWidth: () => 1,
        vLineWidth: () => 1,
        hLineColor: () => '#CBD5E1',
        vLineColor: () => '#CBD5E1'
      }
    });

    // Parent feedback slip for homework
    if (isHomework && data.feedbackSlip !== false) {
      docDefinition.content.push({
        margin: [0, 12, 0, 10],
        unbreakable: true,
        stack: [
          {
            text: '✂ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
            alignment: 'center',
            fontSize: 8,
            color: '#94A3B8',
            margin: [0, 0, 0, 6]
          },
          {
            table: {
              widths: ['*'],
              body: [
                [{
                  fillColor: isEcoPrint ? undefined : '#F8FAFC',
                  borderColor: ['#CBD5E1', '#CBD5E1', '#CBD5E1', '#CBD5E1'],
                  border: [true, true, true, true],
                  stack: [
                    {
                      columns: [
                        { width: '*', text: '📋 ТАЛОН ОБРАТНОЙ СВЯЗИ УЧИТЕЛЮ (заполняется родителем)', bold: true, fontSize: 9.5, color: '#1E293B' },
                        { width: 120, text: 'Лист сдать учителю', alignment: 'right', italics: true, fontSize: 8.5, color: '#64748B' }
                      ]
                    },
                    {
                      margin: [0, 6, 0, 4],
                      columns: [
                        { width: '48%', text: '⏱ Время работы: [  ] до 15 мин  [  ] 15-25 мин  [  ] >30 мин', fontSize: 8.5, color: '#334155' },
                        { width: '52%', text: '💡 Сложность: [  ] Легко сам  [  ] С подсказкой  [  ] Трудно', fontSize: 8.5, color: '#334155' }
                      ]
                    },
                    {
                      columns: [
                        { width: '*', text: 'Вопрос учителю: __________________________________________________', fontSize: 8.5, color: '#475569' },
                        { width: 140, text: 'Подпись: ____________', alignment: 'right', fontSize: 8.5, color: '#475569' }
                      ],
                      margin: [0, 2, 0, 0]
                    }
                  ],
                  margin: [8, 8, 8, 8]
                }]
              ]
            }
          }
        ]
      });
    }

    // Answers page if requested
    if (withAnswers) {
      docDefinition.content.push({
        text: 'Ответы для учителя / самопроверки',
        style: 'sectionHeading',
        pageBreak: 'before',
        margin: [0, 10, 0, 14]
      });

      docDefinition.content.push({
        text: `Тема: «${mainTitle}» (${ageGroupLabel})`,
        style: 'metaText',
        margin: [0, 0, 0, 12]
      });

      const answersList = [];
      for (let i = 1; i <= count; i++) {
        answersList.push({
          margin: [0, 4, 0, 4],
          columns: [
            { width: 90, text: `Ответ к заданию ${i}:`, bold: true, color: '#4F46E5', fontSize: 10 },
            { width: '*', text: '___________________________________________________', color: '#9E9E9E', fontSize: 10 }
          ]
        });
      }
      docDefinition.content.push(answersList);
    }

    // Generate & download
    pdfMake.createPdf(docDefinition).download(fileName);

    // Call JS bridge to notify Flutter
    if (typeof window.onPdfGenerated === 'function') {
      window.onPdfGenerated(fileName);
    } else if (window.onPdfGenerated) {
      try {
        window.onPdfGenerated(fileName);
      } catch (err) {
        console.warn('Could not call window.onPdfGenerated:', err);
      }
    }

    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('onPdfGenerated', fileName);
    }

    return fileName;
  } catch (e) {
    console.error('Error generating PDF:', e);
    throw e;
  }
};