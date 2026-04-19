/**
 * data.js — Mock Data Store for Gestão Férias Dashboard
 * Mirrors the SharePoint list schemas defined in GEMINI.md
 */

const DataStore = (() => {

  // ═══════════════════════════════════════════════════════════
  // Colaboradores_Aprovadores
  // ═══════════════════════════════════════════════════════════
  const colaboradores = [
    { Email: 'ana.silva@minsait.com',      Nome: 'Ana Silva',        Email_Gestor: 'carlos.souza@minsait.com',   Nome_Gestor: 'Carlos Souza',    Departamento: 'Engenharia',     Data_Admissao: '2022-03-15', Ativo: true },
    { Email: 'bruno.costa@minsait.com',    Nome: 'Bruno Costa',      Email_Gestor: 'carlos.souza@minsait.com',   Nome_Gestor: 'Carlos Souza',    Departamento: 'Engenharia',     Data_Admissao: '2021-07-20', Ativo: true },
    { Email: 'carla.mendes@minsait.com',   Nome: 'Carla Mendes',     Email_Gestor: 'fernanda.lima@minsait.com',  Nome_Gestor: 'Fernanda Lima',   Departamento: 'Produto',        Data_Admissao: '2023-01-10', Ativo: true },
    { Email: 'daniel.rocha@minsait.com',   Nome: 'Daniel Rocha',     Email_Gestor: 'carlos.souza@minsait.com',   Nome_Gestor: 'Carlos Souza',    Departamento: 'Engenharia',     Data_Admissao: '2020-11-02', Ativo: true },
    { Email: 'elena.martins@minsait.com',  Nome: 'Elena Martins',    Email_Gestor: 'fernanda.lima@minsait.com',  Nome_Gestor: 'Fernanda Lima',   Departamento: 'Produto',        Data_Admissao: '2022-08-15', Ativo: true },
    { Email: 'fabio.santos@minsait.com',   Nome: 'Fábio Santos',     Email_Gestor: 'gustavo.alves@minsait.com',  Nome_Gestor: 'Gustavo Alves',   Departamento: 'Dados',          Data_Admissao: '2021-04-01', Ativo: true },
    { Email: 'gabriela.dias@minsait.com',  Nome: 'Gabriela Dias',    Email_Gestor: 'gustavo.alves@minsait.com',  Nome_Gestor: 'Gustavo Alves',   Departamento: 'Dados',          Data_Admissao: '2023-06-20', Ativo: true },
    { Email: 'henrique.nunes@minsait.com', Nome: 'Henrique Nunes',   Email_Gestor: 'gustavo.alves@minsait.com',  Nome_Gestor: 'Gustavo Alves',   Departamento: 'Dados',          Data_Admissao: '2022-02-10', Ativo: true },
    { Email: 'isabela.teixeira@minsait.com', Nome: 'Isabela Teixeira', Email_Gestor: 'fernanda.lima@minsait.com', Nome_Gestor: 'Fernanda Lima',   Departamento: 'Produto',        Data_Admissao: '2021-09-12', Ativo: true },
    { Email: 'joao.ferreira@minsait.com',  Nome: 'João Ferreira',    Email_Gestor: 'carlos.souza@minsait.com',   Nome_Gestor: 'Carlos Souza',    Departamento: 'Engenharia',     Data_Admissao: '2020-05-18', Ativo: true },
    { Email: 'carlos.souza@minsait.com',   Nome: 'Carlos Souza',     Email_Gestor: 'diretor@minsait.com',        Nome_Gestor: 'Diretor',         Departamento: 'Engenharia',     Data_Admissao: '2019-01-10', Ativo: true },
    { Email: 'fernanda.lima@minsait.com',  Nome: 'Fernanda Lima',    Email_Gestor: 'diretor@minsait.com',        Nome_Gestor: 'Diretor',         Departamento: 'Produto',        Data_Admissao: '2019-06-03', Ativo: true },
    { Email: 'gustavo.alves@minsait.com',  Nome: 'Gustavo Alves',    Email_Gestor: 'diretor@minsait.com',        Nome_Gestor: 'Diretor',         Departamento: 'Dados',          Data_Admissao: '2019-03-22', Ativo: true },
    { Email: 'larissa.oliveira@minsait.com', Nome: 'Larissa Oliveira', Email_Gestor: 'carlos.souza@minsait.com', Nome_Gestor: 'Carlos Souza',    Departamento: 'Engenharia',     Data_Admissao: '2023-09-01', Ativo: true },
    { Email: 'marcos.pereira@minsait.com', Nome: 'Marcos Pereira',   Email_Gestor: 'fernanda.lima@minsait.com',  Nome_Gestor: 'Fernanda Lima',   Departamento: 'Produto',        Data_Admissao: '2022-11-15', Ativo: true },
    { Email: 'natalia.gomes@minsait.com',  Nome: 'Natália Gomes',    Email_Gestor: 'gustavo.alves@minsait.com',  Nome_Gestor: 'Gustavo Alves',   Departamento: 'Dados',          Data_Admissao: '2024-01-08', Ativo: true },
  ];

  // ═══════════════════════════════════════════════════════════
  // Solicitacoes_Ferias
  // ═══════════════════════════════════════════════════════════
  const solicitacoes = [
    { Id: 1,  Email_Colaborador: 'ana.silva@minsait.com',       Data_Inicio: '2026-06-01', Data_Fim: '2026-06-15', Total_Dias: 11, Status: 'APPROVED',  Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-10T09:30:00', Data_Aprovacao: '2026-04-12T14:00:00' },
    { Id: 2,  Email_Colaborador: 'bruno.costa@minsait.com',     Data_Inicio: '2026-07-10', Data_Fim: '2026-07-25', Total_Dias: 12, Status: 'PENDING',   Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: true,  Observacoes: 'Conflito com Daniel', Data_Criacao: '2026-04-15T10:15:00', Data_Aprovacao: null },
    { Id: 3,  Email_Colaborador: 'carla.mendes@minsait.com',    Data_Inicio: '2026-08-01', Data_Fim: '2026-08-20', Total_Dias: 15, Status: 'APPROVED',  Email_Aprovador: 'fernanda.lima@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-08T11:00:00', Data_Aprovacao: '2026-04-10T16:30:00' },
    { Id: 4,  Email_Colaborador: 'daniel.rocha@minsait.com',    Data_Inicio: '2026-07-15', Data_Fim: '2026-07-30', Total_Dias: 12, Status: 'PENDING',   Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: true,  Observacoes: 'Conflito com Bruno', Data_Criacao: '2026-04-14T08:45:00', Data_Aprovacao: null },
    { Id: 5,  Email_Colaborador: 'elena.martins@minsait.com',   Data_Inicio: '2026-09-01', Data_Fim: '2026-09-12', Total_Dias: 9,  Status: 'APPROVED',  Email_Aprovador: 'fernanda.lima@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-05T14:20:00', Data_Aprovacao: '2026-04-07T10:00:00' },
    { Id: 6,  Email_Colaborador: 'fabio.santos@minsait.com',    Data_Inicio: '2026-06-20', Data_Fim: '2026-07-05', Total_Dias: 12, Status: 'REJECTED',  Email_Aprovador: 'gustavo.alves@minsait.com',  Tem_Conflito: false, Observacoes: 'Projeto critico em andamento', Data_Criacao: '2026-04-02T09:00:00', Data_Aprovacao: null },
    { Id: 7,  Email_Colaborador: 'gabriela.dias@minsait.com',   Data_Inicio: '2026-10-05', Data_Fim: '2026-10-18', Total_Dias: 10, Status: 'APPROVED',  Email_Aprovador: 'gustavo.alves@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-11T16:30:00', Data_Aprovacao: '2026-04-13T09:15:00' },
    { Id: 8,  Email_Colaborador: 'henrique.nunes@minsait.com',  Data_Inicio: '2026-05-20', Data_Fim: '2026-06-05', Total_Dias: 13, Status: 'APPROVED',  Email_Aprovador: 'gustavo.alves@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-03-28T10:00:00', Data_Aprovacao: '2026-03-30T11:30:00' },
    { Id: 9,  Email_Colaborador: 'isabela.teixeira@minsait.com', Data_Inicio: '2026-11-01', Data_Fim: '2026-11-15', Total_Dias: 11, Status: 'PENDING',  Email_Aprovador: 'fernanda.lima@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-18T13:00:00', Data_Aprovacao: null },
    { Id: 10, Email_Colaborador: 'joao.ferreira@minsait.com',   Data_Inicio: '2026-12-15', Data_Fim: '2026-12-30', Total_Dias: 12, Status: 'PENDING',   Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: false, Observacoes: 'Natal + Ano Novo', Data_Criacao: '2026-04-17T15:45:00', Data_Aprovacao: null },
    { Id: 11, Email_Colaborador: 'larissa.oliveira@minsait.com', Data_Inicio: '2026-06-10', Data_Fim: '2026-06-14', Total_Dias: 5,  Status: 'CANCELLED', Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: false, Observacoes: 'Cancelada pelo colaborador', Data_Criacao: '2026-03-20T09:30:00', Data_Aprovacao: null },
    { Id: 12, Email_Colaborador: 'marcos.pereira@minsait.com',  Data_Inicio: '2026-07-01', Data_Fim: '2026-07-10', Total_Dias: 8,  Status: 'APPROVED',  Email_Aprovador: 'fernanda.lima@minsait.com',  Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-01T10:00:00', Data_Aprovacao: '2026-04-03T14:30:00' },
    { Id: 13, Email_Colaborador: 'ana.silva@minsait.com',       Data_Inicio: '2026-12-01', Data_Fim: '2026-12-10', Total_Dias: 8,  Status: 'PENDING',   Email_Aprovador: 'carlos.souza@minsait.com',   Tem_Conflito: false, Observacoes: '',                Data_Criacao: '2026-04-19T08:00:00', Data_Aprovacao: null },
    { Id: 14, Email_Colaborador: 'natalia.gomes@minsait.com',   Data_Inicio: '2026-08-10', Data_Fim: '2026-08-22', Total_Dias: 9,  Status: 'PENDING',   Email_Aprovador: 'gustavo.alves@minsait.com',  Tem_Conflito: true,  Observacoes: 'Conflito com Carla', Data_Criacao: '2026-04-18T17:00:00', Data_Aprovacao: null },
  ];

  // ═══════════════════════════════════════════════════════════
  // Saldo_Ferias
  // ═══════════════════════════════════════════════════════════
  const saldos = [
    { Email_Colaborador: 'ana.silva@minsait.com',        Saldo_Dias: 19, Periodo_Aquisitivo: '15/03/2025 - 14/03/2026', Data_Vencimento: '2027-03-14' },
    { Email_Colaborador: 'bruno.costa@minsait.com',      Saldo_Dias: 30, Periodo_Aquisitivo: '20/07/2025 - 19/07/2026', Data_Vencimento: '2027-07-19' },
    { Email_Colaborador: 'carla.mendes@minsait.com',     Saldo_Dias: 15, Periodo_Aquisitivo: '10/01/2025 - 09/01/2026', Data_Vencimento: '2027-01-09' },
    { Email_Colaborador: 'daniel.rocha@minsait.com',     Saldo_Dias: 18, Periodo_Aquisitivo: '02/11/2025 - 01/11/2026', Data_Vencimento: '2027-11-01' },
    { Email_Colaborador: 'elena.martins@minsait.com',    Saldo_Dias: 21, Periodo_Aquisitivo: '15/08/2025 - 14/08/2026', Data_Vencimento: '2027-08-14' },
    { Email_Colaborador: 'fabio.santos@minsait.com',     Saldo_Dias: 30, Periodo_Aquisitivo: '01/04/2025 - 31/03/2026', Data_Vencimento: '2027-03-31' },
    { Email_Colaborador: 'gabriela.dias@minsait.com',    Saldo_Dias: 20, Periodo_Aquisitivo: '20/06/2025 - 19/06/2026', Data_Vencimento: '2027-06-19' },
    { Email_Colaborador: 'henrique.nunes@minsait.com',   Saldo_Dias: 17, Periodo_Aquisitivo: '10/02/2025 - 09/02/2026', Data_Vencimento: '2026-08-09' },
    { Email_Colaborador: 'isabela.teixeira@minsait.com', Saldo_Dias: 19, Periodo_Aquisitivo: '12/09/2025 - 11/09/2026', Data_Vencimento: '2027-09-11' },
    { Email_Colaborador: 'joao.ferreira@minsait.com',    Saldo_Dias: 12, Periodo_Aquisitivo: '18/05/2025 - 17/05/2026', Data_Vencimento: '2026-11-17' },
    { Email_Colaborador: 'carlos.souza@minsait.com',     Saldo_Dias: 25, Periodo_Aquisitivo: '10/01/2025 - 09/01/2026', Data_Vencimento: '2027-01-09' },
    { Email_Colaborador: 'fernanda.lima@minsait.com',    Saldo_Dias: 22, Periodo_Aquisitivo: '03/06/2025 - 02/06/2026', Data_Vencimento: '2027-06-02' },
    { Email_Colaborador: 'gustavo.alves@minsait.com',    Saldo_Dias: 28, Periodo_Aquisitivo: '22/03/2025 - 21/03/2026', Data_Vencimento: '2027-03-21' },
    { Email_Colaborador: 'larissa.oliveira@minsait.com', Saldo_Dias: 30, Periodo_Aquisitivo: '01/09/2025 - 31/08/2026', Data_Vencimento: '2027-08-31' },
    { Email_Colaborador: 'marcos.pereira@minsait.com',   Saldo_Dias: 22, Periodo_Aquisitivo: '15/11/2025 - 14/11/2026', Data_Vencimento: '2027-11-14' },
    { Email_Colaborador: 'natalia.gomes@minsait.com',    Saldo_Dias: 30, Periodo_Aquisitivo: '08/01/2025 - 07/01/2026', Data_Vencimento: '2027-01-07' },
  ];

  // ═══════════════════════════════════════════════════════════
  // Feriados
  // ═══════════════════════════════════════════════════════════
  const feriados = [
    { Data: '2026-01-01', Nome: 'Confraternizacao Universal',         Tipo: 'NATIONAL' },
    { Data: '2026-02-16', Nome: 'Carnaval',                          Tipo: 'NATIONAL' },
    { Data: '2026-02-17', Nome: 'Carnaval (Terca)',                  Tipo: 'NATIONAL' },
    { Data: '2026-04-03', Nome: 'Sexta-Feira Santa',                 Tipo: 'NATIONAL' },
    { Data: '2026-04-21', Nome: 'Tiradentes',                        Tipo: 'NATIONAL' },
    { Data: '2026-05-01', Nome: 'Dia do Trabalho',                   Tipo: 'NATIONAL' },
    { Data: '2026-06-04', Nome: 'Corpus Christi',                    Tipo: 'NATIONAL' },
    { Data: '2026-07-09', Nome: 'Revolucao Constitucionalista (SP)', Tipo: 'STATE' },
    { Data: '2026-09-07', Nome: 'Independencia do Brasil',           Tipo: 'NATIONAL' },
    { Data: '2026-10-12', Nome: 'Nossa Sra. Aparecida',              Tipo: 'NATIONAL' },
    { Data: '2026-11-02', Nome: 'Finados',                           Tipo: 'NATIONAL' },
    { Data: '2026-11-15', Nome: 'Proclamacao da Republica',          Tipo: 'NATIONAL' },
    { Data: '2026-11-20', Nome: 'Consciencia Negra',                 Tipo: 'NATIONAL' },
    { Data: '2026-12-24', Nome: 'Vespera de Natal (Empresa)',        Tipo: 'COMPANY' },
    { Data: '2026-12-25', Nome: 'Natal',                             Tipo: 'NATIONAL' },
    { Data: '2026-12-31', Nome: 'Vespera de Ano Novo (Empresa)',     Tipo: 'COMPANY' },
  ];

  // ═══════════════════════════════════════════════════════════
  // Alertas_Ferias
  // ═══════════════════════════════════════════════════════════
  const alertas = [
    { Id: 1, Tipo: 'EXPIRING_BALANCE', Email_Colaborador: 'henrique.nunes@minsait.com', Mensagem: 'Saldo vence em menos de 90 dias', Data_Criacao: '2026-04-18T08:00:00', Lido: false },
    { Id: 2, Tipo: 'EXPIRING_BALANCE', Email_Colaborador: 'joao.ferreira@minsait.com',  Mensagem: 'Saldo vence em menos de 90 dias', Data_Criacao: '2026-04-18T08:00:00', Lido: false },
    { Id: 3, Tipo: 'CONFLICT',         Email_Colaborador: 'bruno.costa@minsait.com',    Mensagem: 'Conflito detectado com Daniel Rocha', Data_Criacao: '2026-04-15T10:15:00', Lido: true },
  ];

  // ═══════════════════════════════════════════════════════════
  // Helper Functions
  // ═══════════════════════════════════════════════════════════

  function getEmployeeName(email) {
    const emp = colaboradores.find(e => e.Email === email);
    return emp ? emp.Nome : email;
  }

  function getEmployeeDept(email) {
    const emp = colaboradores.find(e => e.Email === email);
    return emp ? emp.Departamento : '---';
  }

  function getStats() {
    const active = colaboradores.filter(c => c.Ativo).length;
    const total = solicitacoes.length;
    const pending = solicitacoes.filter(s => s.Status === 'PENDING').length;
    const approved = solicitacoes.filter(s => s.Status === 'APPROVED').length;
    const rejected = solicitacoes.filter(s => s.Status === 'REJECTED').length;
    const cancelled = solicitacoes.filter(s => s.Status === 'CANCELLED').length;
    const withConflicts = solicitacoes.filter(s => s.Tem_Conflito && s.Status !== 'CANCELLED').length;
    const totalDaysUsed = solicitacoes.filter(s => s.Status === 'APPROVED').reduce((sum, s) => sum + s.Total_Dias, 0);
    const avgBalance = Math.round(saldos.reduce((sum, s) => sum + s.Saldo_Dias, 0) / saldos.length);
    const now = new Date();
    const in90 = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
    const expiringBalances = saldos.filter(s => new Date(s.Data_Vencimento) <= in90).length;

    return {
      activeEmployees: active,
      totalRequests: total,
      pending,
      approved,
      rejected,
      cancelled,
      withConflicts,
      totalDaysUsed,
      avgBalance,
      expiringBalances,
    };
  }

  function getDepartmentStats() {
    const depts = {};
    colaboradores.filter(c => c.Ativo).forEach(c => {
      if (!depts[c.Departamento]) depts[c.Departamento] = { total: 0, pending: 0 };
      depts[c.Departamento].total++;
    });
    solicitacoes.filter(s => s.Status === 'PENDING').forEach(s => {
      const dept = getEmployeeDept(s.Email_Colaborador);
      if (depts[dept]) depts[dept].pending++;
    });
    return depts;
  }

  function getBalanceDistribution() {
    const dist = { '0-10': 0, '11-20': 0, '21-30': 0 };
    saldos.forEach(s => {
      if (s.Saldo_Dias <= 10) dist['0-10']++;
      else if (s.Saldo_Dias <= 20) dist['11-20']++;
      else dist['21-30']++;
    });
    return dist;
  }

  function getCalendarEvents(year, month) {
    const monthStr = `${year}-${String(month + 1).padStart(2, '0')}`;
    return solicitacoes
      .filter(s => s.Status === 'APPROVED' || s.Status === 'PENDING')
      .filter(s => s.Data_Inicio.startsWith(monthStr) || s.Data_Fim.startsWith(monthStr) ||
        (s.Data_Inicio < monthStr + '-01' && s.Data_Fim > monthStr + '-31'))
      .map(s => ({
        ...s,
        employeeName: getEmployeeName(s.Email_Colaborador),
        department: getEmployeeDept(s.Email_Colaborador),
      }));
  }

  function getHolidaysForMonth(year, month) {
    const monthStr = `${year}-${String(month + 1).padStart(2, '0')}`;
    return feriados.filter(f => f.Data.startsWith(monthStr));
  }

  // Get report of all vacations in the next N days (default 90)
  function getNext90DaysReport(days = 90) {
    const now = new Date();
    const horizon = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
    const nowStr = now.toISOString().split('T')[0];
    const horizonStr = horizon.toISOString().split('T')[0];

    return solicitacoes
      .filter(s => s.Status !== 'CANCELLED' && s.Status !== 'REJECTED')
      .filter(s => {
        // Vacation overlaps the [now, horizon] window
        return s.Data_Fim >= nowStr && s.Data_Inicio <= horizonStr;
      })
      .map(s => ({
        ...s,
        employeeName: getEmployeeName(s.Email_Colaborador),
        department: getEmployeeDept(s.Email_Colaborador),
      }))
      .sort((a, b) => a.Data_Inicio.localeCompare(b.Data_Inicio));
  }

  // Get department-level vacation summary for managers
  function getDepartmentVacationSummary() {
    const now = new Date();
    const in90 = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
    const nowStr = now.toISOString().split('T')[0];
    const in90Str = in90.toISOString().split('T')[0];

    const depts = {};
    colaboradores.filter(c => c.Ativo).forEach(c => {
      if (!depts[c.Departamento]) {
        depts[c.Departamento] = { headcount: 0, approved: [], pending: [], conflicts: 0, totalDaysOut: 0 };
      }
      depts[c.Departamento].headcount++;
    });

    solicitacoes
      .filter(s => (s.Status === 'APPROVED' || s.Status === 'PENDING'))
      .filter(s => s.Data_Fim >= nowStr && s.Data_Inicio <= in90Str)
      .forEach(s => {
        const dept = getEmployeeDept(s.Email_Colaborador);
        if (!depts[dept]) return;
        const entry = { name: getEmployeeName(s.Email_Colaborador), start: s.Data_Inicio, end: s.Data_Fim, days: s.Total_Dias, status: s.Status };
        if (s.Status === 'APPROVED') {
          depts[dept].approved.push(entry);
          depts[dept].totalDaysOut += s.Total_Dias;
        } else {
          depts[dept].pending.push(entry);
        }
        if (s.Tem_Conflito) depts[dept].conflicts++;
      });

    return depts;
  }

  return {
    colaboradores,
    solicitacoes,
    saldos,
    feriados,
    alertas,
    getEmployeeName,
    getEmployeeDept,
    getStats,
    getDepartmentStats,
    getBalanceDistribution,
    getCalendarEvents,
    getHolidaysForMonth,
    getNext90DaysReport,
    getDepartmentVacationSummary,
  };

})();
