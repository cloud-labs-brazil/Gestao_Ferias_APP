/**
 * app.js — SPA Router & View Rendering for Gestão Férias Dashboard
 */

const App = (() => {

  // ─── State ────────────────────────────────────────────────
  let currentView = 'dashboard';
  let calendarDate = new Date();
  let requestFilter = 'ALL';
  let searchQuery = '';

  // ─── Router ───────────────────────────────────────────────
  function navigate(viewId) {
    currentView = viewId;

    // Update active nav
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const activeNav = document.querySelector(`.nav-item[data-view="${viewId}"]`);
    if (activeNav) activeNav.classList.add('active');

    // Update header
    const titles = {
      dashboard:  { title: 'Dashboard',               sub: 'Visão geral de férias' },
      requests:   { title: 'Solicitações',             sub: 'Todas as solicitações de férias' },
      balances:   { title: 'Saldos',                   sub: 'Saldo de férias por colaborador' },
      calendar:   { title: 'Calendário',               sub: 'Calendário da equipe' },
      holidays:   { title: 'Feriados',                 sub: 'Feriados 2026' },
    };
    const t = titles[viewId] || titles.dashboard;
    document.getElementById('header-title').textContent = t.title;
    document.getElementById('header-subtitle').textContent = t.sub;

    // Show view
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    const viewEl = document.getElementById(`view-${viewId}`);
    if (viewEl) viewEl.classList.add('active');

    renderView(viewId);
    closeSidebar();
  }

  // ─── View Renderers ───────────────────────────────────────

  function renderView(viewId) {
    switch (viewId) {
      case 'dashboard': renderDashboard(); break;
      case 'requests':  renderRequests();  break;
      case 'balances':  renderBalances();  break;
      case 'calendar':  renderCalendar();  break;
      case 'holidays':  renderHolidays();  break;
    }
  }

  // ─── DASHBOARD VIEW ───────────────────────────────────────
  function renderDashboard() {
    const stats = DataStore.getStats();
    const container = document.getElementById('view-dashboard');

    // KPIs
    const kpiHtml = `
      <div class="kpi-grid">
        ${Components.kpiCard('👥', 'Colaboradores Ativos', stats.activeEmployees, 'Cadastrados no sistema', 'kpi-primary')}
        ${Components.kpiCard('📋', 'Total Solicitações', stats.totalRequests, `${stats.pending} pendentes`, 'kpi-info')}
        ${Components.kpiCard('⏳', 'Pendentes', stats.pending, 'Aguardando aprovação', 'kpi-warning')}
        ${Components.kpiCard('✅', 'Aprovadas', stats.approved, `${stats.totalDaysUsed} dias alocados`, 'kpi-success')}
        ${Components.kpiCard('⚠️', 'Com Conflito', stats.withConflicts, 'Sobreposição de período', 'kpi-danger')}
        ${Components.kpiCard('📊', 'Saldo Médio', stats.avgBalance + 'd', `${stats.expiringBalances} vencendo em 90d`, 'kpi-muted')}
      </div>
    `;

    // Charts section
    const chartsHtml = `
      <div class="section-grid">
        <div class="card">
          <div class="card-header">
            <span class="card-title">Solicitações por Status</span>
          </div>
          <div class="card-body">
            <div class="chart-container"><canvas id="chart-status-donut"></canvas></div>
          </div>
        </div>
        <div class="card">
          <div class="card-header">
            <span class="card-title">Colaboradores por Departamento</span>
          </div>
          <div class="card-body">
            <div class="chart-container"><canvas id="chart-dept-bars"></canvas></div>
          </div>
        </div>
      </div>
    `;

    // Recent requests
    const recentRequests = [...DataStore.solicitacoes]
      .sort((a, b) => new Date(b.Data_Criacao) - new Date(a.Data_Criacao))
      .slice(0, 5);

    const tableHtml = `
      <div class="section-full">
        <div class="card">
          <div class="card-header">
            <span class="card-title">Solicitações Recentes</span>
            <a href="#" onclick="App.navigate('requests'); return false;" style="font-size:var(--font-sm);">Ver todas →</a>
          </div>
          <div class="card-body">
            ${Components.requestsTable(recentRequests)}
          </div>
        </div>
      </div>
    `;

    container.innerHTML = kpiHtml + chartsHtml + tableHtml;

    // Draw charts after DOM is ready
    requestAnimationFrame(() => {
      Charts.drawDonut('chart-status-donut', [
        { label: 'Aprovadas', value: stats.approved, color: Charts.COLORS.success },
        { label: 'Pendentes', value: stats.pending,  color: Charts.COLORS.warning },
        { label: 'Rejeitadas', value: stats.rejected, color: Charts.COLORS.danger },
        { label: 'Canceladas', value: stats.cancelled, color: Charts.COLORS.muted },
      ], {
        centerText: stats.totalRequests.toString(),
        centerSub: 'solicitações'
      });

      const deptStats = DataStore.getDepartmentStats();
      const deptData = Object.entries(deptStats).map(([name, d]) => ({
        label: name,
        value: d.total,
        color: Charts.COLORS.accent,
        colorEnd: Charts.COLORS.primary,
      }));
      Charts.drawHBars('chart-dept-bars', deptData);
    });
  }

  // ─── REQUESTS VIEW ────────────────────────────────────────
  function renderRequests() {
    const container = document.getElementById('view-requests');

    // Filter bar
    const filterHtml = `
      <div class="card-header" style="border:none; padding-left:0; padding-right:0;">
        <div class="filter-bar">
          <button class="filter-btn ${requestFilter === 'ALL'       ? 'active' : ''}" onclick="App.filterRequests('ALL')">Todas</button>
          <button class="filter-btn ${requestFilter === 'PENDING'   ? 'active' : ''}" onclick="App.filterRequests('PENDING')">Pendentes</button>
          <button class="filter-btn ${requestFilter === 'APPROVED'  ? 'active' : ''}" onclick="App.filterRequests('APPROVED')">Aprovadas</button>
          <button class="filter-btn ${requestFilter === 'REJECTED'  ? 'active' : ''}" onclick="App.filterRequests('REJECTED')">Rejeitadas</button>
          <button class="filter-btn ${requestFilter === 'CANCELLED' ? 'active' : ''}" onclick="App.filterRequests('CANCELLED')">Canceladas</button>
        </div>
        <div class="search-wrapper">
          <input type="text" class="search-input" placeholder="Buscar colaborador..." id="request-search" value="${searchQuery}" oninput="App.searchRequests(this.value)">
        </div>
      </div>
    `;

    let filtered = [...DataStore.solicitacoes];
    if (requestFilter !== 'ALL') filtered = filtered.filter(r => r.Status === requestFilter);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter(r => {
        const name = DataStore.getEmployeeName(r.Email_Colaborador).toLowerCase();
        return name.includes(q) || r.Email_Colaborador.includes(q);
      });
    }
    filtered.sort((a, b) => new Date(b.Data_Criacao) - new Date(a.Data_Criacao));

    const stats = {
      total: filtered.length,
      pending: filtered.filter(r => r.Status === 'PENDING').length,
    };

    const summaryHtml = `
      <div style="font-size:var(--font-sm);color:var(--text-muted);margin-bottom:var(--space-4);">
        Mostrando ${stats.total} solicitações ${stats.pending > 0 ? `(${stats.pending} pendentes)` : ''}
      </div>
    `;

    const tableHtml = `
      <div class="card">
        <div class="card-body">
          ${Components.requestsTable(filtered)}
        </div>
      </div>
    `;

    container.innerHTML = filterHtml + summaryHtml + tableHtml;
  }

  function filterRequests(status) {
    requestFilter = status;
    renderRequests();
  }

  function searchRequests(query) {
    searchQuery = query;
    renderRequests();
  }

  // ─── BALANCES VIEW ────────────────────────────────────────
  function renderBalances() {
    const container = document.getElementById('view-balances');
    const stats = DataStore.getStats();
    const dist = DataStore.getBalanceDistribution();

    const kpiHtml = `
      <div class="kpi-grid" style="margin-bottom:var(--space-6);">
        ${Components.kpiCard('📊', 'Saldo Médio', stats.avgBalance + 'd', 'Média dos colaboradores', 'kpi-primary')}
        ${Components.kpiCard('⚠️', 'Vencendo em 90d', stats.expiringBalances, 'Precisam agendar férias', 'kpi-warning')}
        ${Components.kpiCard('🟢', '21-30 dias', dist['21-30'], 'Saldo alto', 'kpi-success')}
        ${Components.kpiCard('🔴', '0-10 dias', dist['0-10'], 'Saldo baixo', 'kpi-danger')}
      </div>
    `;

    const sortedSaldos = [...DataStore.saldos].sort((a, b) => {
      const da = new Date(a.Data_Vencimento);
      const db = new Date(b.Data_Vencimento);
      return da - db;
    });

    const tableHtml = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">Saldo por Colaborador</span>
          <span style="font-size:var(--font-sm);color:var(--text-muted);">Ordenado por vencimento</span>
        </div>
        <div class="card-body">
          ${Components.balanceTable(sortedSaldos)}
        </div>
      </div>
    `;

    container.innerHTML = kpiHtml + tableHtml;
  }

  // ─── CALENDAR VIEW ────────────────────────────────────────
  function renderCalendar() {
    const container = document.getElementById('view-calendar');
    const year = calendarDate.getFullYear();
    const month = calendarDate.getMonth();

    const navHtml = `
      <div class="calendar-nav">
        <button onclick="App.calendarPrev()">◀</button>
        <span class="calendar-month-label">${Components.formatMonthYear(calendarDate)}</span>
        <button onclick="App.calendarNext()">▶</button>
        <button onclick="App.calendarToday()" style="width:auto;padding:0 16px;font-size:var(--font-sm);font-family:var(--font-family);font-weight:500;">Hoje</button>
      </div>
    `;

    const legendHtml = `
      <div class="legend mb-6">
        <div class="legend-item"><div class="legend-dot" style="background:var(--success)"></div>Aprovado</div>
        <div class="legend-item"><div class="legend-dot" style="background:var(--warning)"></div>Pendente</div>
        <div class="legend-item"><div class="legend-dot" style="background:var(--danger)"></div>Feriado</div>
        <div class="legend-item"><div class="legend-dot" style="background:var(--accent)"></div>Hoje</div>
      </div>
    `;

    const calHtml = Components.calendarGrid(year, month);

    container.innerHTML = navHtml + legendHtml + calHtml;
  }

  function calendarPrev() {
    calendarDate.setMonth(calendarDate.getMonth() - 1);
    renderCalendar();
  }

  function calendarNext() {
    calendarDate.setMonth(calendarDate.getMonth() + 1);
    renderCalendar();
  }

  function calendarToday() {
    calendarDate = new Date();
    renderCalendar();
  }

  // ─── HOLIDAYS VIEW ───────────────────────────────────────
  function renderHolidays() {
    const container = document.getElementById('view-holidays');
    const feriados = DataStore.feriados;

    const kpiHtml = `
      <div class="kpi-grid" style="margin-bottom:var(--space-6);">
        ${Components.kpiCard('🎌', 'Total Feriados', feriados.length, 'Ano 2026', 'kpi-primary')}
        ${Components.kpiCard('🇧🇷', 'Nacionais', feriados.filter(f => f.Tipo === 'NATIONAL').length, '', 'kpi-info')}
        ${Components.kpiCard('🏛️', 'Estaduais', feriados.filter(f => f.Tipo === 'STATE').length, '', 'kpi-warning')}
        ${Components.kpiCard('🏢', 'Empresa', feriados.filter(f => f.Tipo === 'COMPANY').length, '', 'kpi-success')}
      </div>
    `;

    const tableHtml = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">Feriados 2026</span>
        </div>
        <div class="card-body">
          ${Components.holidayTable(feriados)}
        </div>
      </div>
    `;

    container.innerHTML = kpiHtml + tableHtml;
  }

  // ─── Sidebar Toggle ───────────────────────────────────────
  function toggleSidebar() {
    document.querySelector('.sidebar').classList.toggle('open');
    document.querySelector('.sidebar-overlay').classList.toggle('active');
  }

  function closeSidebar() {
    document.querySelector('.sidebar').classList.remove('open');
    document.querySelector('.sidebar-overlay').classList.remove('active');
  }

  // ─── Init ─────────────────────────────────────────────────
  async function init() {
    // Set header date
    const dateEl = document.getElementById('header-date');
    if (dateEl) {
      const now = new Date();
      dateEl.textContent = now.toLocaleDateString('pt-BR', {
        weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
      });
    }

    // Bind nav clicks
    document.querySelectorAll('.nav-item[data-view]').forEach(item => {
      item.addEventListener('click', () => navigate(item.dataset.view));
    });

    // Try loading live SharePoint data (replaces mock arrays if on SP)
    if (typeof SPConnector !== 'undefined') {
      await SPConnector.init();
    }

    // Set pending badge (uses live or mock data, whichever loaded)
    const pending = DataStore.solicitacoes.filter(s => s.Status === 'PENDING').length;
    const badge = document.getElementById('pending-badge');
    if (badge) badge.textContent = pending;

    // Set alerts badge
    const unread = DataStore.alertas.filter(a => !a.Lido).length;
    const alertBadge = document.getElementById('alerts-badge');
    if (alertBadge) {
      if (unread > 0) alertBadge.textContent = unread;
      else alertBadge.style.display = 'none';
    }

    // Initial render
    navigate('dashboard');

    // Redraw charts on resize
    let resizeTimer;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => {
        if (currentView === 'dashboard') renderDashboard();
      }, 200);
    });
  }

  // ─── Public API ───────────────────────────────────────────
  return {
    init,
    navigate,
    filterRequests,
    searchRequests,
    calendarPrev,
    calendarNext,
    calendarToday,
    toggleSidebar,
    closeSidebar,
  };

})();

// Boot
document.addEventListener('DOMContentLoaded', App.init);
