/**
 * sp-connector.js — SharePoint REST API Connector for Gestão Férias Dashboard
 * 
 * When hosted on SharePoint, replaces mock data in DataStore with live SP list data.
 * Falls back to mock data when running locally (file:// or localhost).
 * 
 * Uses same-origin SharePoint REST API — no extra auth needed when hosted on SP.
 */

const SPConnector = (() => {

  // ═══════════════════════════════════════════════════════════
  // Configuration
  // ═══════════════════════════════════════════════════════════
  const SP_SITE_URL = 'https://indra365.sharepoint.com/sites/Grp_T_DN_Arquitetura_Solucoes_Multi_Praticas_QA';

  const LIST_NAMES = {
    colaboradores:  'Colaboradores_Aprovadores',
    solicitacoes:   'Solicitacoes_Ferias',
    saldos:         'Saldo_Ferias',
    feriados:       'Feriados',
    alertas:        'Alertas_Ferias',
  };

  // Field mappings: SP Internal Name → Dashboard property name
  const FIELD_MAP = {
    colaboradores: {
      'Email':          'Email',
      'NomeCompleto':   'Nome',
      'EmailGestor':    'Email_Gestor',
      'NomeGestor':     'Nome_Gestor',
      'Departamento':   'Departamento',
      'DataAdmissao':   'Data_Admissao',
      'Ativo':          'Ativo',
    },
    solicitacoes: {
      'ID':                 'Id',
      'ColaboradorEmail':   'Email_Colaborador',
      'DataInicio':         'Data_Inicio',
      'DataFim':            'Data_Fim',
      'DiasUteis':          'Total_Dias',
      'Status':             'Status',
      'AprovadorEmail':     'Email_Aprovador',
      'TemConflito':        'Tem_Conflito',
      'Observacoes':        'Observacoes',
      'Created':            'Data_Criacao',
      'DataAprovacao':      'Data_Aprovacao',
    },
    saldos: {
      'ColaboradorEmail':       'Email_Colaborador',
      'SaldoDisponivel':        'Saldo_Dias',
      'PeriodoAquisitivo':      'Periodo_Aquisitivo',
      'DataVencimento':         'Data_Vencimento',
    },
    feriados: {
      'DataFeriado':  'Data',
      'Title':        'Nome',
      'TipoFeriado':  'Tipo',
    },
    alertas: {
      'ID':                   'Id',
      'TipoAlerta':           'Tipo',
      'ColaboradorEmail':     'Email_Colaborador',
      'Mensagem':             'Mensagem',
      'Created':              'Data_Criacao',
      'Lido':                 'Lido',
    },
  };

  // ═══════════════════════════════════════════════════════════
  // Detection: Are we running on SharePoint?
  // ═══════════════════════════════════════════════════════════
  function isOnSharePoint() {
    return window.location.hostname.includes('sharepoint.com');
  }

  // ═══════════════════════════════════════════════════════════
  // SP REST API helpers
  // ═══════════════════════════════════════════════════════════
  async function getRequestDigest() {
    const resp = await fetch(`${SP_SITE_URL}/_api/contextinfo`, {
      method: 'POST',
      headers: { 'Accept': 'application/json;odata=nometadata' },
      credentials: 'include',
    });
    const data = await resp.json();
    return data.FormDigestValue;
  }

  async function fetchListItems(listName, selectFields, topCount = 500) {
    const selectParam = selectFields ? `&$select=${selectFields.join(',')}` : '';
    const url = `${SP_SITE_URL}/_api/web/lists/getbytitle('${listName}')/items?$top=${topCount}${selectParam}`;

    const resp = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json;odata=nometadata',
      },
      credentials: 'include',
    });

    if (!resp.ok) {
      console.error(`[SPConnector] Failed to fetch ${listName}: ${resp.status} ${resp.statusText}`);
      return null;
    }

    const data = await resp.json();
    return data.value || [];
  }

  function mapFields(items, fieldMap) {
    return items.map(item => {
      const mapped = {};
      for (const [spField, dashField] of Object.entries(fieldMap)) {
        let value = item[spField];
        // Normalize dates to ISO string (YYYY-MM-DD)
        if (dashField.includes('Data_') || dashField === 'Data') {
          if (value) {
            value = value.split('T')[0];
          }
        }
        // Normalize booleans
        if (typeof value === 'string' && (value.toLowerCase() === 'true' || value.toLowerCase() === 'false')) {
          value = value.toLowerCase() === 'true';
        }
        mapped[dashField] = value !== undefined ? value : null;
      }
      return mapped;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // Load all data from SharePoint
  // ═══════════════════════════════════════════════════════════
  async function loadAllData() {
    console.log('[SPConnector] Loading data from SharePoint REST API...');
    const startTime = Date.now();

    try {
      // Fetch all lists in parallel
      const [rawColab, rawSolic, rawSaldo, rawFeriado, rawAlerta] = await Promise.all([
        fetchListItems(LIST_NAMES.colaboradores, Object.keys(FIELD_MAP.colaboradores)),
        fetchListItems(LIST_NAMES.solicitacoes, Object.keys(FIELD_MAP.solicitacoes)),
        fetchListItems(LIST_NAMES.saldos, Object.keys(FIELD_MAP.saldos)),
        fetchListItems(LIST_NAMES.feriados, Object.keys(FIELD_MAP.feriados)),
        fetchListItems(LIST_NAMES.alertas, Object.keys(FIELD_MAP.alertas)),
      ]);

      // Check for failures (fall back to mock if any list fails)
      if (!rawColab || !rawSolic || !rawSaldo || !rawFeriado || !rawAlerta) {
        console.warn('[SPConnector] One or more lists failed to load. Falling back to mock data.');
        return false;
      }

      // Map SP fields to dashboard format
      const colaboradores = mapFields(rawColab, FIELD_MAP.colaboradores);
      const solicitacoes = mapFields(rawSolic, FIELD_MAP.solicitacoes);
      const saldos = mapFields(rawSaldo, FIELD_MAP.saldos);
      const feriados = mapFields(rawFeriado, FIELD_MAP.feriados);
      const alertas = mapFields(rawAlerta, FIELD_MAP.alertas);

      // Replace DataStore arrays
      DataStore.colaboradores.length = 0;
      DataStore.colaboradores.push(...colaboradores);

      DataStore.solicitacoes.length = 0;
      DataStore.solicitacoes.push(...solicitacoes);

      DataStore.saldos.length = 0;
      DataStore.saldos.push(...saldos);

      DataStore.feriados.length = 0;
      DataStore.feriados.push(...feriados);

      DataStore.alertas.length = 0;
      DataStore.alertas.push(...alertas);

      const elapsed = Date.now() - startTime;
      console.log(`[SPConnector] ✅ Loaded ${colaboradores.length} employees, ${solicitacoes.length} requests, ${saldos.length} balances, ${feriados.length} holidays, ${alertas.length} alerts in ${elapsed}ms`);

      return true;
    } catch (err) {
      console.error('[SPConnector] Error loading SP data:', err);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Write operations (for future submit/cancel/approve)
  // ═══════════════════════════════════════════════════════════
  async function createListItem(listName, values) {
    const digest = await getRequestDigest();
    const url = `${SP_SITE_URL}/_api/web/lists/getbytitle('${listName}')/items`;

    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/json;odata=nometadata',
        'Content-Type': 'application/json;odata=nometadata',
        'X-RequestDigest': digest,
      },
      body: JSON.stringify(values),
      credentials: 'include',
    });

    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Create failed (${resp.status}): ${errText}`);
    }
    return await resp.json();
  }

  async function updateListItem(listName, itemId, values) {
    const digest = await getRequestDigest();
    const url = `${SP_SITE_URL}/_api/web/lists/getbytitle('${listName}')/items(${itemId})`;

    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'application/json;odata=nometadata',
        'Content-Type': 'application/json;odata=nometadata',
        'X-RequestDigest': digest,
        'X-HTTP-Method': 'MERGE',
        'If-Match': '*',
      },
      body: JSON.stringify(values),
      credentials: 'include',
    });

    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`Update failed (${resp.status}): ${errText}`);
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // Initialize: auto-detect and load
  // ═══════════════════════════════════════════════════════════
  async function init() {
    if (!isOnSharePoint()) {
      console.log('[SPConnector] Not on SharePoint — using mock data from data.js');
      return false;
    }

    console.log('[SPConnector] Detected SharePoint environment. Loading live data...');
    const success = await loadAllData();

    if (success) {
      // Add a live data indicator to the UI
      const indicator = document.createElement('div');
      indicator.className = 'live-data-badge';
      indicator.innerHTML = '🟢 LIVE DATA';
      indicator.style.cssText = 'position:fixed;bottom:12px;right:12px;background:rgba(0,200,80,0.15);color:#00c850;padding:6px 14px;border-radius:20px;font-size:11px;font-weight:700;letter-spacing:1px;z-index:9999;backdrop-filter:blur(8px);border:1px solid rgba(0,200,80,0.3);';
      document.body.appendChild(indicator);
    }

    return success;
  }

  return {
    isOnSharePoint,
    loadAllData,
    createListItem,
    updateListItem,
    init,
    SP_SITE_URL,
    LIST_NAMES,
  };

})();
