// Enhanced PDF Editor (Mobbin‑inspired)
// Features: multi‑page, undo/redo, templates, theme switch, local storage, export via jsPDF+html2canvas

document.addEventListener('DOMContentLoaded', () => {
  // ==== State ==== //
  const state = {
    pages: [], // each page is a DOM element (container)
    currentPageIndex: 0,
    history: [], // {pagesSnapshot, description}
    historyIndex: -1,
    theme: 'light', // or 'dark'
  };

  // ==== Elements ==== //
  const sidebar = document.getElementById('sidebar');
  const toggleBtn = document.getElementById('toggleSidebar');
  const bottomToolbar = document.getElementById('bottomToolbar');
  const topBar = document.querySelector('.top-bar');
  const pageTabs = document.createElement('div'); // tabs container
  pageTabs.className = 'page-tabs';
  topBar.appendChild(pageTabs);

  const saveBtn = document.getElementById('saveBtn');
  const exportBtn = document.getElementById('exportBtn');

  // ==== Helpers ==== //
  const createPage = () => {
    const page = document.createElement('div');
    page.className = 'canvas-area page';
    page.id = `page-${state.pages.length}`;
    page.dataset.page = state.pages.length;
    page.style.position = 'relative';
    page.style.minHeight = '1122px'; // A4 at 96dpi ~ 1122px height
    page.style.minWidth = '794px'; // A4 width
    page.style.border = '1px solid var(--accent-gold)';
    page.style.background = 'var(--bg-page)';
    page.style.overflow = 'hidden';
    return page;
  };

  const renderTabs = () => {
    pageTabs.innerHTML = '';
    state.pages.forEach((p, i) => {
      const tab = document.createElement('button');
      tab.className = 'page-tab' + (i === state.currentPageIndex ? ' active' : '');
      tab.textContent = `Стр.${i + 1}`;
      tab.addEventListener('click', () => switchPage(i));
      pageTabs.appendChild(tab);
    });
    // New page button
    const newTab = document.createElement('button');
    newTab.className = 'page-tab new';
    newTab.textContent = '+';
    newTab.title = 'Новая страница';
    newTab.addEventListener('click', addNewPage);
    pageTabs.appendChild(newTab);
  };

  const switchPage = (index) => {
    if (index < 0 || index >= state.pages.length) return;
    // hide current
    const current = document.getElementById(`page-${state.currentPageIndex}`);
    if (current) current.style.display = 'none';
    // show new
    const target = document.getElementById(`page-${index}`);
    if (target) target.style.display = 'block';
    state.currentPageIndex = index;
    renderTabs();
  };

  const addNewPage = () => {
    const page = createPage();
    state.pages.push(page);
    document.body.appendChild(page);
    // hide all others, show new
    state.pages.forEach((p, i) => {
      p.style.display = i === state.pages.length - 1 ? 'block' : 'none';
    });
    state.currentPageIndex = state.pages.length - 1;
    pushHistory('Добавлена страница');
    renderTabs();
  };

  // ==== Undo/Redo ==== //
  const pushHistory = (desc) => {
    // truncate forward history
    if (state.historyIndex < state.history.length - 1) {
      state.history = state.history.slice(0, state.historyIndex + 1);
    }
    const snapshot = state.pages.map(p => p.innerHTML);
    state.history.push({pagesSnapshot: snapshot, description: desc});
    state.historyIndex++;
    // limit history size (e.g., 50)
    if (state.history.length > 50) {
      state.history.shift();
      state.historyIndex--;
    }
  };

  const restoreHistory = (index) => {
    const entry = state.history[index];
    if (!entry) return;
    state.pages.forEach((p, i) => {
      p.innerHTML = entry.pagesSnapshot[i] || '';
    });
    state.historyIndex = index;
  };

  const undo = () => {
    if (state.historyIndex <= 0) return;
    restoreHistory(state.historyIndex - 1);
  };

  const redo = () => {
    if (state.historyIndex >= state.history.length - 1) return;
    restoreHistory(state.historyIndex + 1);
  };

  // ==== Toolbar extensions ==== //
  const addExtraButtons = () => {
    const btnUndo = document.createElement('button');
    btnUndo.title = 'Отменить (Ctrl+Z)';
    btnUndo.innerHTML = '<span class="icon">↩️</span>';
    btnUndo.addEventListener('click', undo);
    bottomToolbar.appendChild(btnUndo);

    const btnRedo = document.createElement('button');
    btnRedo.title = 'Повторить (Ctrl+Y)';
    btnRedo.innerHTML = '<span class="icon">↪️</span>';
    btnRedo.addEventListener('click', redo);
    bottomToolbar.appendChild(btnRedo);

    const btnTheme = document.createElement('button');
    btnTheme.title = 'Сменить тему';
    btnTheme.innerHTML = '<span class="icon">🌓</span>';
    btnTheme.addEventListener('click', toggleTheme);
    bottomToolbar.appendChild(btnTheme);

    const btnTemplate = document.createElement('button');
    btnTemplate.title = 'Шаблоны страниц';
    btnTemplate.innerHTML = '<span class="icon">📄</span>';
    btnTemplate.addEventListener('click', openTemplatePanel);
    bottomToolbar.appendChild(btnTemplate);
  };

  // ==== Theme ==== //
  const toggleTheme = () => {
    state.theme = state.theme === 'light' ? 'dark' : 'light';
    document.documentElement.dataset.theme = state.theme;
    // Persist
    localStorage.setItem('pdfEditorTheme', state.theme);
  };

  // ==== Templates ==== //
  const templates = [
    {name: 'Титульный лист', html: '<h1 style="text-align:center;margin-top:200px;">Титульный лист</h1>'},
    {name: 'Таблица задач', html: '<table style="width:100%;border-collapse:collapse;" class="editable-table"><tr><th>№</th><th>Задание</th></tr><tr><td>1</td><td contenteditable="true"> </td></tr></table>'},
    {name: 'Сертификат', html: '<div style="border:4px solid var(--accent-gold);padding:40px;text-align:center;"> <h2>Сертификат</h2><p>Это сертификат, выданный ...</p></div>'},
  ];

  const openTemplatePanel = () => {
    const panel = document.createElement('div');
    panel.className = 'template-panel';
    panel.innerHTML = '<div class="panel-header"><span>Шаблоны страниц</span><button class="close">✖</button></div>';
    const list = document.createElement('div');
    list.className = 'template-list';
    templates.forEach(t => {
      const item = document.createElement('div');
      item.className = 'template-item';
      item.textContent = t.name;
      item.addEventListener('click', () => {
        const page = state.pages[state.currentPageIndex];
        page.insertAdjacentHTML('beforeend', t.html);
        pushHistory(`Добавлен шаблон «${t.name}»`);
        document.body.removeChild(panel);
      });
      list.appendChild(item);
    });
    panel.appendChild(list);
    document.body.appendChild(panel);
    panel.querySelector('.close').addEventListener('click', () => document.body.removeChild(panel));
  };

  // ==== Storage ==== //
  const saveProject = () => {
    const data = {
      pages: state.pages.map(p => p.innerHTML),
      theme: state.theme,
    };
    localStorage.setItem('pdfEditorProject', JSON.stringify(data));
    alert('Проект сохранён в браузере');
  };

  const loadProject = () => {
    const raw = localStorage.getItem('pdfEditorProject');
    if (!raw) return;
    const data = JSON.parse(raw);
    // clear existing pages
    state.pages.forEach(p => p.remove());
    state.pages = [];
    data.pages.forEach((html, i) => {
      const page = createPage();
      page.innerHTML = html;
      state.pages.push(page);
      document.body.appendChild(page);
    });
    state.currentPageIndex = 0;
    switchPage(0);
    if (data.theme) {
      state.theme = data.theme;
      document.documentElement.dataset.theme = data.theme;
    }
    renderTabs();
    pushHistory('Загружен сохранённый проект');
  };

  // ==== Export PDF (jsPDF + html2canvas) ==== //
  const exportPdf = async () => {
    // hide UI panels temporarily
    const uiElements = document.querySelectorAll('.top-bar, .page-tabs, .sidebar, .bottom-toolbar');
    uiElements.forEach(el => el.style.display = 'none');
    // capture each page sequentially
    const {jsPDF} = window.jspdf;
    const pdf = new jsPDF('p', 'pt', 'a4');
    for (let i = 0; i < state.pages.length; i++) {
      const page = state.pages[i];
      const canvas = await html2canvas(page, {scale: 2});
      const imgData = canvas.toDataURL('image/png');
      const imgProps = pdf.getImageProperties(imgData);
      const pdfWidth = pdf.internal.pageSize.getWidth();
      const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
      if (i > 0) pdf.addPage();
      pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
    }
    // restore UI
    uiElements.forEach(el => el.style.display = '');
    const now = new Date();
    const fname = `editor_${now.getFullYear()}${('0'+(now.getMonth()+1)).slice(-2)}${('0'+now.getDate()).slice(-2)}.pdf`;
    pdf.save(fname);
  };

  // ==== Init ==== //
  // Load persisted theme
  const persistedTheme = localStorage.getItem('pdfEditorTheme') || 'light';
  state.theme = persistedTheme;
  document.documentElement.dataset.theme = persistedTheme;

  // Init first page
  addNewPage();

  // Buttons
  addExtraButtons();

  // Save / Export bindings
  saveBtn.addEventListener('click', saveProject);
  exportBtn.addEventListener('click', exportPdf);

  // Sidebar toggle (unchanged)
  toggleBtn.addEventListener('click', () => {
    sidebar.classList.toggle('closed');
    document.querySelector('.canvas-area').classList.toggle('closed');
  });

  // Existing element addition (text, image, shape) – reuse old functions if present
  bottomToolbar.addEventListener('click', e => {
    const action = e.target.closest('button')?.dataset?.action;
    if (!action) return;
    switch (action) {
      case 'addText': addTextBox(); break;
      case 'addImage': addImageBox(); break;
      case 'addShape': addShapeBox(); break;
    }
  });

  // ---- Helper functions (unchanged from original) ---- //
  function addTextBox() {
    const div = document.createElement('div');
    div.contentEditable = true;
    div.className = 'editable-box';
    div.style.position = 'absolute';
    div.style.left = '100px';
    div.style.top = '100px';
    div.style.minWidth = '150px';
    div.style.minHeight = '30px';
    div.style.padding = '4px 8px';
    div.style.border = '1px solid var(--accent-blue)';
    div.style.borderRadius = '4px';
    div.style.background = 'rgba(255,255,255,0.9)';
    div.innerText = 'Текст';
    const page = state.pages[state.currentPageIndex];
    page.appendChild(div);
    pushHistory('Добавлен текстовый блок');
  }

  function addImageBox() {
    const img = document.createElement('img');
    img.src = 'https://placekitten.com/200/150';
    img.style.position = 'absolute';
    img.style.left = '120px';
    img.style.top = '150px';
    img.style.maxWidth = '200px';
    img.style.border = '2px solid var(--accent-gold)';
    img.style.borderRadius = '4px';
    const page = state.pages[state.currentPageIndex];
    page.appendChild(img);
    pushHistory('Добавлено изображение');
  }

  function addShapeBox() {
    const shape = document.createElement('div');
    shape.style.position = 'absolute';
    shape.style.left = '80px';
    shape.style.top = '200px';
    shape.style.width = '100px';
    shape.style.height = '100px';
    shape.style.background = 'var(--accent-gold)';
    shape.style.borderRadius = '8px';
    const page = state.pages[state.currentPageIndex];
    page.appendChild(shape);
    pushHistory('Добавлена фигура');
  }
});