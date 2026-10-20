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
  star: '<svg width="20" height="20" viewBox="0 0 24 24"><polygon points="12,2 15,11 24,11 17,17 19,26 12,21 5,26 7,17 0,11 9,11" fill="#6366F1"/></svg>',
  pencil: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.9959.9959 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="#8B5CF6"/></svg>',
  check: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="#10B981"/></svg>',
  bookmark: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2z" fill="#EC4899"/></svg>',
  // custom icons for basic tasks
  'icon-dictation': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v2H4zM4 10h16v2H4zM4 16h16v2H4z" fill="currentColor"/></svg>',
  'icon-copy': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M8 4h12v12H8zM6 6v12H4V6a2 2 0 012-2z" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  'icon-missing-letter': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M12 8v8M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>',
  'icon-capital': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="16" fill="currentColor">A</text></svg>',
  'icon-transfer': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M6 12h12M12 6l6 6-6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg>',
  // placeholders for remaining task icons
  'icon-underline': '<svg width="20" height="20" viewBox="0 0 24 24"><rect width="24" height="24" fill="#E5E7EB"/></svg>',
  'icon-soft-sign': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#E5E7EB"/></svg>',
  'icon-letter-y': '<svg width="20" height="20" viewBox="0 0 24 24"><polygon points="12,2 22,22 2,22" fill="#E5E7EB"/></svg>',
  'icon-unscramble': '<svg width="20" height="20" viewBox="0 0 24 24"><line x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-make-word-from-syllables': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v16H4z" fill="#E5E7EB"/></svg>',
  'icon-missing-syllable': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="6" y="6" width="12" height="12" fill="#E5E7EB"/></svg>',
  'icon-make-sentence': '<svg width="20" height="20" viewBox="0 0 24 24"><polyline points="4,12 12,4 20,12" fill="none" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-count-sounds-letters': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB">1</text></svg>',
  'icon-find-mistake': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M2 12h20" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-one-many': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="8" cy="12" r="4" fill="#E5E7EB"/><circle cx="16" cy="12" r="4" fill="#E5E7EB"/></svg>',
  'icon-finish-sentence': '<svg width="20" height="20" viewBox="0 0 24 24"><line x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-vocabulary-word': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" fill="#E5E7EB"/></svg>',
  // math icons placeholders
  'icon-math-examples': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB">+</text></svg>',
  'icon-missing-number': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="8" y="8" width="8" height="8" fill="#E5E7EB"/></svg>',
  'icon-compare-numbers': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="12" text-anchor="middle" font-size="12" fill="#E5E7EB"><></text></svg>',
  'icon-number-composition': '<svg width="20" height="20" viewBox="0 0 24 24"><polygon points="4,20 20,20 12,4" fill="#E5E7EB"/></svg>',
  'icon-word-problem': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v16H4z" fill="#E5E7EB"/></svg>',
  'icon-count-objects': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8" fill="#E5E7EB"/></svg>',
  'icon-continue-sequence': '<svg width="20" height="20" viewBox="0 0 24 24"><polyline points="4,12 12,4 20,12" fill="none" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-chain-examples': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-math-dictation': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB">✍</text></svg>',
  'icon-odd-one-out': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#E5E7EB"/></svg>',
  'icon-color-by-number': '<svg width="20" height="20" viewBox="0 0 24 24"><rect width="24" height="24" fill="#E5E7EB"/></svg>',
  // reading icons placeholders
  'icon-read-syllables': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="12" fill="#E5E7EB">§</text></svg>',
  'icon-match-word-picture': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" fill="#E5E7EB"/></svg>',
  'icon-first-last-sound': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="12" text-anchor="middle" font-size="12" fill="#E5E7EB">🔊</text></svg>',
  'icon-find-sound-word': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8" fill="#E5E7EB"/></svg>',
  'icon-repeat-tongue-twister': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-finish-rhyme': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 12h16" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-describe-picture': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="2" y="2" width="20" height="20" fill="#E5E7EB"/></svg>',
  // handwriting icons placeholders
  'icon-trace-elements': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v16H4z" fill="#E5E7EB"/></svg>',
  'icon-complete-element': '<svg width="20" height="20" viewBox="0 0 24 24"><line x1="4" y1="12" x2="20" y2="12" stroke="#E5E7EB" stroke-width="2"/></svg>',
  'icon-cell-pattern': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" fill="#E5E7EB"/></svg>',
  'icon-graphic-dictation': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v16H4z" fill="#E5E7EB"/></svg>',
  // preschool icons placeholders
  'icon-shadow-match': '<svg width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#E5E7EB"/></svg>',
  'icon-find-pair': '<svg width="20" height="20" viewBox="0 0 24 24"><rect x="6" y="6" width="12" height="12" fill="#E5E7EB"/></svg>',
};
  star: '<svg width="20" height="20" viewBox="0 0 24 24"><polygon points="12,2 15,11 24,11 17,17 19,26 12,21 5,26 7,17 0,11 9,11" fill="#6366F1"/></svg>',
  pencil: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.9959.9959 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="#8B5CF6"/></svg>',
  check: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="#10B981"/></svg>',
  bookmark: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2z" fill="#EC4899"/></svg>',
  // custom icons for basic tasks
  'icon-dictation': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M4 4h16v2H4zM4 10h16v2H4zM4 16h16v2H4z" fill="currentColor"/></svg>',
  'icon-copy': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M8 4h12v12H8zM6 6v12H4V6a2 2 0 012-2z" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  'icon-missing-letter': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M12 8v8M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>',
  'icon-capital': '<svg width="20" height="20" viewBox="0 0 24 24"><text x="12" y="16" text-anchor="middle" font-size="16" fill="currentColor">A</text></svg>',
  'icon-transfer': '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M6 12h12M12 6l6 6-6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg>',
};
      star: '<svg width="20" height="20" viewBox="0 0 24 24"><polygon points="12,2 15,11 24,11 17,17 19,26 12,21 5,26 7,17 0,11 9,11" fill="#6366F1"/></svg>',
      pencil: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.9959.9959 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="#8B5CF6"/></svg>',
      check: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="#10B981"/></svg>',
      bookmark: '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M17 3H7c-1.1 0-1.99.9-1.99 2L5 21l7-3 7 3V5c0-1.1-.9-2-2-2z" fill="#EC4899"/></svg>'
    };

    const count = parseInt(data.tasksCount, 10) || 5;
    const withAnswers = data.withAnswers === true;
    const ageGroupLabel = data.ageGroup === 'preschool' ? 'Дошкольники' : (data.ageGroup === 'grade_2' ? '2 класс' : '1 класс');
    const duration = data.duration || '45 мин';

    const docDefinition = {
      pageSize: 'A4',
      pageMargins: [40, 45, 40, 45],
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
    const icons = ['star', 'pencil', 'bookmark', 'check'];
    for (let i = 1; i <= count; i++) {
      // Retrieve task payload from data.tasks or use placeholder
      const taskPayload = (data.tasks && data.tasks[i - 1]) || { id: 'placeholder', params: {}, template: '' };
      const renderer = renderers[taskPayload.id] || renderers['placeholder'];
      const taskContent = renderer(taskPayload);
      const iconKey = icons[(i - 1) % icons.length];
      const taskSvg = iconMap[iconKey] || iconMap['star'];
      docDefinition.content.push({
        margin: [0, 6, 0, 8],
        table: {
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
            { width: '*', text: `Ключевое решение и правильный вариант ответа для задания ${i}.`, fontSize: 10, color: '#334155' }
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
