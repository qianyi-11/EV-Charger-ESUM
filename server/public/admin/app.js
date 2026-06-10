const AdminApp = (() => {
  const TOKEN_KEY = 'rexharge_admin_token';
  const ADMIN_EMAIL = 'admin@gmail.com';
  const ADMIN_PASSWORD = 'Law.1234';

  function getToken() {
    return localStorage.getItem(TOKEN_KEY);
  }

  function setToken(token) {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  }

  async function api(path, options = {}) {
    const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;

    const res = await fetch(path, { ...options, headers });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || 'Request failed');
    return data;
  }

  function showLogin() {
    document.getElementById('login-screen')?.classList.remove('hidden');
    document.getElementById('app')?.classList.add('hidden');
  }

  function showApp() {
    document.getElementById('login-screen')?.classList.add('hidden');
    document.getElementById('app')?.classList.remove('hidden');
  }

  function formatStatus(status) {
    if (status === 'in_progress') return 'In progress';
    if (status === 'complete') return 'Complete';
    return 'Open';
  }

  function statusClass(status) {
    return status || 'open';
  }

  function formatDateTime(iso) {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return { time: '-', date: '-' };
    const time = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const date = d.toLocaleDateString([], { day: '2-digit', month: 'short', year: 'numeric' });
    return { time, date };
  }

  function chargerBrandLabel(ticket) {
    if (ticket.chargerBrand === 'Others' && ticket.chargerBrandOther) return ticket.chargerBrandOther;
    return ticket.chargerBrand || '-';
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  async function loadAuthedImage(url) {
    const token = getToken();
    const res = await fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });
    if (!res.ok) throw new Error('Could not load image');
    const blob = await res.blob();
    return URL.createObjectURL(blob);
  }

  async function hydrateImages(root) {
    const images = root.querySelectorAll('img[data-auth-src]');
    for (const img of images) {
      try {
        img.src = await loadAuthedImage(img.dataset.authSrc);
      } catch {
        img.alt = 'Image unavailable';
      }
    }
  }

  async function loginWithCredentials(email, password) {
    const data = await api('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    if (data.user.role !== 'admin') {
      throw new Error('This account is not an admin.');
    }
    setToken(data.token);
    return true;
  }

  async function login() {
    const email = document.getElementById('login-email')?.value.trim() || ADMIN_EMAIL;
    const password = document.getElementById('login-password')?.value || ADMIN_PASSWORD;
    const errorEl = document.getElementById('login-error');
    if (errorEl) errorEl.textContent = '';

    try {
      await loginWithCredentials(email, password);
      showApp();
      return true;
    } catch (err) {
      if (errorEl) errorEl.textContent = err.message;
      return false;
    }
  }

  async function autoLoginAdmin() {
    await loginWithCredentials(ADMIN_EMAIL, ADMIN_PASSWORD);
    showApp();
  }

  function bindLogin(onSuccess) {
    document.getElementById('login-btn')?.addEventListener('click', async () => {
      const ok = await login();
      if (ok && onSuccess) onSuccess();
    });
    document.getElementById('logout-btn')?.addEventListener('click', () => {
      setToken(null);
      showLogin();
    });
  }

  async function ensureAdmin(onReady) {
    bindLogin(onReady);

    if (getToken()) {
      try {
        const data = await api('/api/auth/me');
        if (data.user.role === 'admin') {
          showApp();
          onReady();
          return;
        }
      } catch {
        setToken(null);
      }
    }

    try {
      await autoLoginAdmin();
      onReady();
    } catch {
      showLogin();
      const emailEl = document.getElementById('login-email');
      const passEl = document.getElementById('login-password');
      if (emailEl) emailEl.value = ADMIN_EMAIL;
      if (passEl) passEl.value = ADMIN_PASSWORD;
    }
  }

  async function loadMeta() {
    const data = await api('/api/tickets/meta');
    const issueSelect = document.getElementById('filter-issue');
    if (!issueSelect) return;
    issueSelect.innerHTML = '<option value="all">All issue types</option>';
    data.issueTypes.forEach((type) => {
      const opt = document.createElement('option');
      opt.value = type;
      opt.textContent = type;
      issueSelect.appendChild(opt);
    });
  }

  function updateStats(tickets) {
    document.getElementById('stat-open').textContent = tickets.filter((t) => t.status === 'open').length;
    document.getElementById('stat-progress').textContent = tickets.filter((t) => t.status === 'in_progress').length;
    document.getElementById('stat-complete').textContent = tickets.filter((t) => t.status === 'complete').length;
    document.getElementById('stat-total').textContent = tickets.length;
  }

  function renderRows(tickets) {
    const tbody = document.getElementById('ticket-rows');
    const empty = document.getElementById('empty-state');
    tbody.innerHTML = '';

    if (!tickets.length) {
      empty.classList.remove('hidden');
      return;
    }
    empty.classList.add('hidden');

    tickets.forEach((ticket) => {
      const { time, date } = formatDateTime(ticket.createdAt);
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${ticket.ticketId}</td>
        <td>${ticket.fullName}</td>
        <td>${ticket.issueType}</td>
        <td>${chargerBrandLabel(ticket)}</td>
        <td>${ticket.assignedEngineer || 'Unassigned'}</td>
        <td><span class="badge ${statusClass(ticket.status)}">${formatStatus(ticket.status)}</span></td>
        <td>${time}</td>
        <td>${date}</td>
      `;
      tr.addEventListener('click', () => {
        window.location.href = `/admin/ticket.html?id=${ticket.id}`;
      });
      tbody.appendChild(tr);
    });
  }

  async function refreshList() {
    const search = document.getElementById('search').value.trim();
    const status = document.getElementById('filter-status').value;
    const issueType = document.getElementById('filter-issue').value;
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (status !== 'all') params.set('status', status);
    if (issueType !== 'all') params.set('issueType', issueType);

    const data = await api(`/api/tickets?${params.toString()}`);
    updateStats(data.tickets);
    renderRows(data.tickets);
  }

  function initListPage() {
    ensureAdmin(async () => {
      await loadMeta();
      await refreshList();
      document.getElementById('search').addEventListener('input', refreshList);
      document.getElementById('filter-status').addEventListener('change', refreshList);
      document.getElementById('filter-issue').addEventListener('change', refreshList);
    });
  }

  function renderDetailsValue(label, value) {
    return `<div class="label">${label}</div><div>${escapeHtml(value ?? '-')}</div>`;
  }

  function renderIssueDetailsValue(label, value, ticket) {
    if (label !== 'Details') {
      return renderDetailsValue(label, value);
    }

    let detailsHtml = `<div>${escapeHtml(ticket.details || '-').replace(/\n/g, '<br>')}</div>`;
    if (ticket.isolatorPhotoUrl) {
      detailsHtml += `
        <div class="details-ebox">
          <div class="label" style="margin-top:8px;">Isolator photo</div>
          <img data-auth-src="${ticket.isolatorPhotoUrl}" alt="Isolator switch photo" class="ebox-shot" />
        </div>`;
    }
    if (ticket.evdbPhotoUrl) {
      detailsHtml += `
        <div class="details-ebox">
          <div class="label" style="margin-top:8px;">EVDB photo</div>
          <img data-auth-src="${ticket.evdbPhotoUrl}" alt="EVDB panel photo" class="ebox-shot" />
        </div>`;
    }
    if (ticket.eboxScreenshotUrl) {
      detailsHtml += `
        <div class="details-ebox">
          <div class="label" style="margin-top:8px;">e.Box screenshot</div>
          <img data-auth-src="${ticket.eboxScreenshotUrl}" alt="e.Box app screenshot" class="ebox-shot" />
        </div>`;
    }
    return `<div class="label">Details</div><div>${detailsHtml}</div>`;
  }

  function renderDetailsGrid(gridId, fields, ticket, { issueSection = false } = {}) {
    const grid = document.getElementById(gridId);
    if (!grid) return;
    grid.innerHTML = fields
      .map(([label, value]) =>
        issueSection
          ? renderIssueDetailsValue(label, value, ticket)
          : renderDetailsValue(label, value),
      )
      .join('');
    hydrateImages(grid);
  }

  function renderDetails(ticket) {
    renderDetailsGrid('user-details', [
      ['Customer', ticket.fullName],
      ['Email', ticket.userEmail],
      ['Salutation', ticket.salutation || '-'],
      ['Phone', ticket.contactNumber || '-'],
      ['Address', ticket.address || '-'],
      ['Car brand', ticket.carBrand === 'Others' ? ticket.carBrandOther : ticket.carBrand],
      ['Installed with RExharge', ticket.installedWithRexharge || '-'],
    ], ticket);

    renderDetailsGrid('charger-details', [
      ['Charger brand', chargerBrandLabel(ticket)],
      ['Serial number', ticket.chargerSerialNumber || '-'],
      ['Installation date', ticket.installationDate || '-'],
    ], ticket);

    renderDetailsGrid(
      'issue-details',
      [
        ['Ticket ID', ticket.ticketId],
        ['Faulty component', ticket.faultyComponent || '-'],
        ['Issue type', ticket.issueType],
        ['Details', ticket.details || '-'],
        ['Created', ticket.createdAt],
        ['Updated', ticket.updatedAt],
      ],
      ticket,
      { issueSection: true },
    );
  }

  function formatBubbleTime(iso) {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '';
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  function formatDateChip(iso) {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '';
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);

    const sameDay = (a, b) =>
      a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate();

    if (sameDay(d, today)) return 'Today';
    if (sameDay(d, yesterday)) return 'Yesterday';
    return d.toLocaleDateString([], { day: 'numeric', month: 'long', year: 'numeric' });
  }

  function dateKey(iso) {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '';
    return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  }

  function initialsFromName(name) {
    const parts = String(name || '?').trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return '?';
    if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
    return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
  }

  function setupWaHeader(ticket) {
    const nameEl = document.getElementById('wa-contact-name');
    const subEl = document.getElementById('wa-contact-sub');
    const avatarEl = document.getElementById('wa-avatar');
    if (nameEl) nameEl.textContent = ticket.fullName || 'Customer';
    if (subEl) subEl.textContent = ticket.userEmail || '';
    if (avatarEl) avatarEl.textContent = initialsFromName(ticket.fullName);
  }

  function autoResizeChatInput() {
    const input = document.getElementById('chat-input');
    if (!input) return;
    input.style.height = 'auto';
    input.style.height = `${Math.min(input.scrollHeight, 120)}px`;
  }

  async function renderChatMessages(messages) {
    const container = document.getElementById('chat-messages');
    if (!container) return;

    if (!messages.length) {
      container.innerHTML = '<p class="wa-empty">No messages yet. Send a message to start the conversation.</p>';
      return;
    }

    let html = '';
    let lastDate = '';

    messages.forEach((message) => {
      const chip = formatDateChip(message.createdAt);
      const key = dateKey(message.createdAt);
      if (key && key !== lastDate) {
        lastDate = key;
        html += `<div class="wa-date-chip"><span>${escapeHtml(chip)}</span></div>`;
      }

      const isOut = message.direction === 'admin';
      const attachment = message.attachmentUrl
        ? `<img data-auth-src="${message.attachmentUrl}" alt="Attachment" class="chat-attachment" />`
        : '';
      html += `
        <div class="wa-msg-row ${isOut ? 'out' : 'in'}">
          <div class="wa-bubble ${isOut ? 'out' : 'in'}">
            <span class="wa-bubble-text">${escapeHtml(message.body).replace(/\n/g, '<br>')}</span>
            ${attachment}
            <span class="wa-bubble-meta">
              <span class="wa-time">${formatBubbleTime(message.createdAt)}</span>
            </span>
          </div>
        </div>
      `;
    });

    container.innerHTML = html;
    await hydrateImages(container);
    container.scrollTop = container.scrollHeight;
  }

  async function loadChat(ticketId) {
    const data = await api(`/api/tickets/${ticketId}/messages`);
    await renderChatMessages(data.messages || []);
  }

  let chatPollTimer = null;

  function startChatPolling(ticketId) {
    stopChatPolling();
    chatPollTimer = setInterval(() => {
      loadChat(ticketId).catch(() => {});
    }, 8000);
  }

  function stopChatPolling() {
    if (chatPollTimer) {
      clearInterval(chatPollTimer);
      chatPollTimer = null;
    }
  }

  async function sendChatMessage(ticketId) {
    const input = document.getElementById('chat-input');
    const sendBtn = document.getElementById('chat-send-btn');
    const body = input?.value.trim() || '';
    const senderName = 'EVision Support';

    if (!body) return;

    if (sendBtn) sendBtn.disabled = true;

    try {
      await api(`/api/tickets/${ticketId}/messages`, {
        method: 'POST',
        body: JSON.stringify({ body, senderName }),
      });
      if (input) {
        input.value = '';
        autoResizeChatInput();
      }
      await loadChat(ticketId);
    } catch (err) {
      alert(err.message || 'Could not send message.');
    } finally {
      if (sendBtn) sendBtn.disabled = false;
      input?.focus();
    }
  }

  function bindChatComposer(ticketId) {
    const input = document.getElementById('chat-input');
    const sendBtn = document.getElementById('chat-send-btn');

    sendBtn?.addEventListener('click', () => sendChatMessage(ticketId));

    input?.addEventListener('input', autoResizeChatInput);

    input?.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendChatMessage(ticketId);
      }
    });
  }

  async function initDetailPage() {
    const params = new URLSearchParams(window.location.search);
    const ticketId = params.get('id');
    if (!ticketId) {
      window.location.href = '/admin';
      return;
    }

    ensureAdmin(async () => {
      const meta = await api('/api/tickets/meta');
      const engineerSelect = document.getElementById('assign-engineer');
      engineerSelect.innerHTML = meta.engineers.map((name) => `<option value="${name}">${name}</option>`).join('');

      const data = await api(`/api/tickets/${ticketId}`);
      const ticket = data.ticket;
      document.getElementById('page-title').textContent = `${ticket.ticketId} — ${ticket.issueType}`;
      document.getElementById('ticket-status').value = ticket.status;
      engineerSelect.value = ticket.assignedEngineer || 'Unassigned';
      renderDetails(ticket);
      setupWaHeader(ticket);
      bindChatComposer(ticketId);
      await loadChat(ticketId);
      startChatPolling(ticketId);

      document.getElementById('save-btn').addEventListener('click', async () => {
        const msg = document.getElementById('save-msg');
        msg.classList.add('hidden');
        try {
          const updated = await api(`/api/tickets/${ticketId}`, {
            method: 'PATCH',
            body: JSON.stringify({
              status: document.getElementById('ticket-status').value,
              assignedEngineer: document.getElementById('assign-engineer').value,
            }),
          });
          renderDetails(updated.ticket);
          msg.textContent = 'Ticket updated successfully.';
          msg.classList.remove('hidden');
        } catch (err) {
          msg.textContent = err.message;
          msg.classList.remove('hidden');
          msg.style.color = '#dc2626';
        }
      });
    });
  }

  return { initListPage, initDetailPage };
})();
