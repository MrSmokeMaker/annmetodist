# Analysis of Practical Assignment Template (activities.json)

> [!NOTE] This document reviews the current JSON structure used for practical activities and proposes enhancements to make the template more flexible, maintainable, and useful for educators and developers.

---

## 1. Current Structure Overview

```json
[
  {
    "id": "act_finger_gym",
    "category": "Разминка",
    "title": "Пальчиковая гимнастика",
    "short_description": "Разогрев кистей, снятие гипертонуса пальцев перед работой.",
    "sample_text": "..."
  },
  ...
]
```

| Field | Purpose | Observations |
|-------|---------|--------------|
| **id** | Unique identifier (machine‑readable) | Uses `act_` prefix; good for stable referencing. |
| **category** | Human‑readable grouping (e.g., "Разминка") | No hierarchical taxonomy; categories are free‑form strings. |
| **title** | Short name displayed to users | Works well, but sometimes long. |
| **short_description** | One‑sentence summary | Mixed length; sometimes contains commas that could be split into bullet points. |
| **sample_text** | Detailed instructional script (often multi‑line) | Stored as a raw string with escaped newlines; not structured for reuse (e.g., separate steps, media links). |

### Strengths
- Simple and human‑readable.
- All required data is present in a single file, easy to load.

### Weaknesses
1. **Flat schema** – no explicit fields for duration, difficulty, materials, assessment, or learning objectives.
2. **`sample_text` unstructured** – mixing steps, notes, and formatting makes it hard to render in UI or generate PDFs.
3. **No validation** – typos in `category` or missing fields are not caught.
4. **Localization** – all strings are Russian; adding other languages would require duplication.
5. **Versioning / Auditing** – no `created_at`, `updated_at`, or author metadata.
6. **Reusability** – common step templates (e.g., “Учитель задает ритм…”) are repeated across activities.

---

## 2. Recommended Extensions

Below is a proposed enriched schema (still JSON) that keeps backward compatibility but adds optional fields.

```json
{
  "id": "act_finger_gym",
  "category": "Разминка",
  "title": "Пальчиковая гимнастика",
  "short_description": "Разогрев кистей, снятие гипертонуса пальцев перед работой.",
  "duration_minutes": 10,               // ⏱ Estimated time
  "difficulty": "easy",                // enum: easy|medium|hard
  "learning_objectives": [               // 📚 What the learner should achieve
    "Развить мелкую моторику кистей",
    "Снизить мышечный гипертонус"
  ],
  "materials": [                        // 📦 Items needed
    "Карточки с рисунками",
    "Тактильные мячики"
  ],
  "steps": [                             // Structured instruction list
    {
      "order": 1,
      "title": "Упражнение ‘Замочек’",
      "description": "Сцепление пальцев, волнообразные движения кистями.",
      "media": ["/assets/images/lock_exercise.png"]
    },
    {
      "order": 2,
      "title": "Упражнение ‘Колечки’",
      "description": "Поочередное касание большого пальца со всеми остальными с ускорением."
    },
    {
      "order": 3,
      "title": "Встряхивание",
      "description": "Расслабленные кисти со звуком ‘сбросили усталость’."
    }
  ],
  "assessment": {                        // 🎯 How to check mastery
    "type": "observation",
    "criteria": [
      "Все дети выполняют каждое движение без задержек",
      "Улыбка и активное участие"
    ]
  },
  "tags": ["моторика","разминка"],   // 🔖 For search/filtering
  "metadata": {                          // 📅 Optional audit info
    "created_at": "2026-10-01",
    "updated_at": "2026-10-20",
    "author": "Иван Иванов"
  },
  "localizations": {                     // 🌐 Multi‑language support (optional)
    "en": {
      "title": "Finger Gymnastics",
      "short_description": "Warm‑up for the hands…",
      "steps": [ ... ]
    }
  }
}
```

### Key Additions Explained
| New Field | Reason |
|-----------|--------|
| `duration_minutes` | Enables schedule planning and automatic lesson timing. |
| `difficulty` | Helps teachers select age‑appropriate activities. |
| `learning_objectives` | Aligns tasks with curriculum standards. |
| `materials` | Clarifies preparatory needs. |
| `steps` (array) | Provides a structured, render‑ready list; each step can reference media assets. |
| `assessment` | Gives explicit criteria for evaluating the activity. |
| `tags` | Improves searchability in UI tools. |
| `metadata` | Tracks provenance; useful for change‑log and CI checks. |
| `localizations` | Future‑proofs the repository for multilingual use. |

---

## 3. Migration Plan

1. **Create a JSON schema file** (`activities_schema.json`) that validates the new structure using [JSON Schema Draft‑07].
2. **Write a migration script** (Node.js or Python) that:
   - Reads the old `activities.json`.
   - Maps existing fields to the new shape (e.g., `sample_text` → single step with `order: 1`).
   - Populates optional fields with sensible defaults (`duration_minutes: 10`, `difficulty: "easy"`).
   - Saves the result to `activities_v2.json`.
3. **Update the application code** to read the new fields (UI will render `steps`, show duration, etc.). Keep a fallback for older format if needed.
4. **Add unit tests** ensuring every activity conforms to the schema.
5. **Document the format** in a new `ACTIVITIES.md` file (examples, field definitions, localization guidelines).

---

## 4. Immediate Quick Wins (No Code Change Required)
- **Standardise categories**: create an enumeration file (`categories.json`) and reference it in UI.
- **Split `sample_text` into bullet points** using a simple script to replace `\n- ` with markdown list items; store as Markdown.
- **Add a `duration` comment** at the end of each activity manually (e.g., `// Длительность: 10 мин`).
- **Introduce a `tags` array** (comma‑separated) for easier filtering.

---

## 5. Next Steps for You
1. **Choose a migration strategy** – full schema overhaul vs incremental additions.
2. **Decide on the level of localization** you need now.
3. **Allocate a file for the schema** (e.g., `e:\My Projects\Metodist\activities_schema.json`).
4. **If you need the migration script**, tell me the preferred language (Python/Node) and I’ll generate it.

---

**Feel free to request any artifacts (schema file, migration script, updated docs) or a walkthrough of integrating the new fields into your codebase.**