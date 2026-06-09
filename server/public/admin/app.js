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

  function renderDetails(ticket) {
    const grid = document.getElementById('ticket-details');
    const fields = [
      ['Ticket ID', ticket.ticketId],
      ['Customer', ticket.fullName],
      ['Email', ticket.userEmail],
      ['Salutation', ticket.salutation || '-'],
      ['Phone', ticket.contactNumber || '-'],
      ['Address', ticket.address || '-'],
      ['Car brand', ticket.carBrand === 'Others' ? ticket.carBrandOther : ticket.carBrand],
      ['Installed with RExharge', ticket.installedWithRexharge || '-'],
      ['Charger brand', chargerBrandLabel(ticket)],
      ['Serial number', ticket.chargerSerialNumber || '-'],
      ['Installation date', ticket.installationDate || '-'],
      ['Faulty component', ticket.faultyComponent || '-'],
      ['Describe issue', ticket.describeIssue || '-'],
      ['Issue type', ticket.issueType],
      ['Details', ticket.details || '-'],
      ['Source error code', ticket.sourceErrorCode || '-'],
      ['Created', ticket.createdAt],
      ['Updated', ticket.updatedAt],
    ];

    grid.innerHTML = fields.map(([label, value]) => `
      <div class="label">${label}</div><div>${value ?? '-'}</div>
    `).join('');
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
