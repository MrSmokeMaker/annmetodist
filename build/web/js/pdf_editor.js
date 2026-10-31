document.addEventListener('DOMContentLoaded', () => {
  const sidebar = document.getElementById('sidebar');
  const toggleBtn = document.getElementById('toggleSidebar');
  const canvas = document.getElementById('canvas');
  const saveBtn = document.getElementById('saveBtn');
  const exportBtn = document.getElementById('exportBtn');
  const bottomToolbar = document.getElementById('bottomToolbar');

  // Toggle sidebar
  toggleBtn.addEventListener('click', () => {
    sidebar.classList.toggle('closed');
    document.querySelector('.canvas-area').classList.toggle('closed');
  });

  // Simple element addition (demo only)
  bottomToolbar.addEventListener('click', e => {
    const action = e.target.closest('button')?.dataset?.action;
    if (!action) return;
    switch (action) {
      case 'addText':
        addTextBox();
        break;
      case 'addImage':
        addImageBox();
        break;
      case 'addShape':
        addShapeBox();
        break;
      case 'undo':
        // placeholder
        break;
      case 'redo':
        // placeholder
        break;
    }
  });

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
    canvas.appendChild(div);
  }

  function addImageBox() {
    const img = document.createElement('img');
    img.src = 'https://placekitten.com/200/150'; // placeholder
    img.style.position = 'absolute';
    img.style.left = '120px';
    img.style.top = '150px';
    img.style.maxWidth = '200px';
    img.style.border = '2px solid var(--accent-gold)';
    img.style.borderRadius = '4px';
    canvas.appendChild(img);
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
    canvas.appendChild(shape);
  }

  // Save / Export placeholders – in real app would invoke Flutter bridge
  saveBtn.addEventListener('click', () => {
    alert('Сохранение пока не реализовано – в реальном клиенте будет взаимодействие с бекендом.');
  });
  exportBtn.addEventListener('click', () => {
    alert('Экспорт PDF пока не реализован – будет использовать Flutter‑плагин.');
  });
});
