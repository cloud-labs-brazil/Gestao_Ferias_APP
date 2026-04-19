/**
 * components.js — Reusable UI Components for Gestão Férias Dashboard
 * All rendering functions return HTML strings
 */

const Components = (() => {

  // ─── Status Badge ─────────────────────────────────────────
  function statusBadge(status) {
    const map = {
      'APPROVED':  { cls: 'badge-approved',  label: 'Aprovado' },
      'PENDING':   { cls: 'badge-pending',   label: 'Pendente' },
      'REJECTED':  { cls: 'badge-rejected',  label: 'Rejeitado' },
      'CANCELLED': { cls: 'badge-cancelled', label: 'Cancelado' },
    };
    const m = map[status] || { cls: 'badge-cancelled', label: status };
    return `<span class="badge ${m.cls}">${m.label}</span>`;
  }

  // ─── Conflict Indicator ───────────────────────────────────
  function conflictBadge(hasConflict) {
    if (hasConflict) return `<span class="conflict-yes">⚠ Sim</span>`;
    return `<span class="conflict-no">—</span>`;
  }

  // ─── Holiday Type Badge ───────────────────────────────────
  function holidayTypeBadge(tipo) {
    const map = {
      'NATIONAL': { cls: 'holiday-national', label: 'Nacional' },
      'STATE':    { cls: 'holiday-state',    label: 'Estadual' },
      'COMPANY':  { cls: 'holiday-company',  label: 'Empresa' },
    };
    const m = map[tipo] || { cls: 'holiday-national', label: tipo };
    return `<span class="holiday-type ${m.cls}">${m.label}</span>`;
  }

  // ─── Format Date ──────────────────────────────────────────
  function formatDate(isoDate) {
    if (!isoDate) return '—';
    const [y, m, d] = isoDate.split('T')[0].split('-');
    return `${d}/${m}/${y}`;
  }

  function formatDateTime(isoDate) {
    if (!isoDate) return '—';
    const date = new Date(isoDate);
    return date.toLocaleDateString('pt-BR') + ' ' + date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  }

  function formatMonthYear(date) {
    const months = [
      'Janeiro','Fevereiro','Março','Abril','Maio','Junho',
      'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'
    ];
    return `${months[date.getMonth()]} ${date.getFullYear()}`;
  }

  // ─── Balance Bar ──────────────────────────────────────────
  function balanceBar(days, maxDays = 30) {
    const pct = Math.min(100, (days / maxDays) * 100);
    let cls = 'fill-high';
    if (pct <= 33) cls = 'fill-low';
    else if (pct <= 66) cls = 'fill-mid';
    return `
      <div class="balance-bar-track">
        <div class="balance-bar-fill ${cls}" style="width:${pct}%"></div>
      </div>
    `;
  }

  // ─── Expiry Warning ───────────────────────────────────────
  function expiryWarning(dateStr) {
    const exp = new Date(dateStr);
    const diff = Math.ceil((exp - new Date()) / (1000 * 60 * 60 * 24));
    if (diff <= 0) return `<span class="expiry-warning">⚠ Vencido</span>`;
    if (diff <= 30) return `<span class="expiry-warning">⚠ ${diff}d</span>`;
    if (diff <= 90) return `<span class="text-warning" style="font-size:var(--font-xs);font-weight:600;">${diff}d</span>`;
    return `<span class="text-muted" style="font-size:var(--font-xs);">${diff}d</span>`;
  }

  // ─── KPI Card ─────────────────────────────────────────────
  function kpiCard(icon, label, value, sub, colorClass = 'kpi-primary') {
    return `
      <div class="kpi-card ${colorClass}">
        <div class="kpi-header">
          <span class="kpi-label">${label}</span>
          <span class="kpi-icon">${icon}</span>
        </div>
        <div class="kpi-value" data-animate>${value}</div>
        <div class="kpi-sub">${sub}</div>
      </div>
    `;
  }

  // ─── Requests Table ───────────────────────────────────────
  function requestsTable(requests, showEmployee = true) {
    if (!requests.length) {
      return `<div class="empty-state"><div class="empty-state-icon">📋</div><div class="empty-state-text">Nenhuma solicitação encontrada</div></div>`;
    }
    return `
      <div class="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              ${showEmployee ? '<th>Colaborador</th>' : ''}
              <th>Início</th>
              <th>Fim</th>
              <th>Dias</th>
              <th>Status</th>
              <th>Conflito</th>
              <th>Criado em</th>
            </tr>
          </thead>
          <tbody>
            ${requests.map(r => `
              <tr>
                <td style="color:var(--text-muted);font-weight:600;">#${r.Id}</td>
                ${showEmployee ? `<td style="color:var(--text-primary);font-weight:500;">${DataStore.getEmployeeName(r.Email_Colaborador)}</td>` : ''}
                <td>${formatDate(r.Data_Inicio)}</td>
                <td>${formatDate(r.Data_Fim)}</td>
                <td style="font-weight:600;">${r.Total_Dias}</td>
                <td>${statusBadge(r.Status)}</td>
                <td>${conflictBadge(r.Tem_Conflito)}</td>
                <td class="text-muted">${formatDateTime(r.Data_Criacao)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  // ─── Balance Table ────────────────────────────────────────
  function balanceTable(saldos) {
    return `
      <div class="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Colaborador</th>
              <th>Departamento</th>
              <th>Saldo</th>
              <th style="width:200px;">Barra</th>
              <th>Período Aquisitivo</th>
              <th>Vencimento</th>
              <th>Alerta</th>
            </tr>
          </thead>
          <tbody>
            ${saldos.map(s => `
              <tr>
                <td style="color:var(--text-primary);font-weight:500;">${DataStore.getEmployeeName(s.Email_Colaborador)}</td>
                <td>${DataStore.getEmployeeDept(s.Email_Colaborador)}</td>
                <td style="font-weight:700;font-size:var(--font-md);">${s.Saldo_Dias}d</td>
                <td>${balanceBar(s.Saldo_Dias)}</td>
                <td class="text-muted">${s.Periodo_Aquisitivo}</td>
                <td>${formatDate(s.Data_Vencimento)}</td>
                <td>${expiryWarning(s.Data_Vencimento)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  // ─── Holiday Table ────────────────────────────────────────
  function holidayTable(feriados) {
    return `
      <div class="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Data</th>
              <th>Nome</th>
              <th>Tipo</th>
            </tr>
          </thead>
          <tbody>
            ${feriados.map(f => {
              const d = new Date(f.Data + 'T12:00:00');
              const dow = d.toLocaleDateString('pt-BR', { weekday: 'short' });
              const past = new Date(f.Data) < new Date() ? 'text-muted' : '';
              return `
                <tr class="${past}">
                  <td style="font-weight:600;">${formatDate(f.Data)} <span class="text-muted" style="font-weight:400;font-size:var(--font-xs);">(${dow})</span></td>
                  <td style="color:var(--text-primary);">${f.Nome}</td>
                  <td>${holidayTypeBadge(f.Tipo)}</td>
                </tr>
              `;
            }).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  // ─── Calendar Grid ────────────────────────────────────────
  function calendarGrid(year, month) {
    const dows = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    const events = DataStore.getCalendarEvents(year, month);
    const holidays = DataStore.getHolidaysForMonth(year, month);

    let html = '<div class="calendar-grid">';

    // Day-of-week headers
    dows.forEach(d => html += `<div class="calendar-dow">${d}</div>`);

    // Empty leading cells
    for (let i = 0; i < firstDay; i++) html += '<div class="calendar-cell empty"></div>';

    // Day cells
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(day).padStart(2,'0')}`;
      const isToday = dateStr === todayStr;
      const dayHolidays = holidays.filter(h => h.Data === dateStr);
      const isHoliday = dayHolidays.length > 0;
      const dayEvents = events.filter(e => e.Data_Inicio <= dateStr && e.Data_Fim >= dateStr);

      let cls = 'calendar-cell';
      if (isToday) cls += ' today';
      if (isHoliday) cls += ' holiday';

      html += `<div class="${cls}">`;
      html += `<div class="calendar-day-num">${day}</div>`;

      dayHolidays.forEach(h => {
        html += `<div class="calendar-holiday-tag" title="${h.Nome}">🎌 ${h.Nome}</div>`;
      });

      dayEvents.forEach(e => {
        const eCls = e.Status === 'APPROVED' ? 'event-approved' : 'event-pending';
        const firstName = e.employeeName.split(' ')[0];
        html += `<div class="calendar-event ${eCls}" title="${e.employeeName} (${e.department})">${firstName}</div>`;
      });

      html += '</div>';
    }

    html += '</div>';
    return html;
  }

  // ─── Public API ───────────────────────────────────────────
  return {
    statusBadge,
    conflictBadge,
    holidayTypeBadge,
    formatDate,
    formatDateTime,
    formatMonthYear,
    balanceBar,
    expiryWarning,
    kpiCard,
    requestsTable,
    balanceTable,
    holidayTable,
    calendarGrid
  };

})();
