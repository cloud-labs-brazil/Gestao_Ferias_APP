/**
 * charts.js — Simple Canvas-based charts for Gestão Férias Dashboard
 * No external dependencies
 */

const Charts = (() => {

  const COLORS = {
    primary:  '#004E98',
    accent:   '#00B4D8',
    success:  '#10B981',
    warning:  '#F59E0B',
    danger:   '#EF4444',
    muted:    '#6B7280',
    info:     '#3B82F6',
    grid:     'rgba(255,255,255,0.04)',
    text:     '#94A3B8',
  };

  /**
   * Donut Chart
   */
  function drawDonut(canvasId, data, options = {}) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';
    ctx.scale(dpr, dpr);

    const w = rect.width;
    const h = rect.height;
    const cx = w / 2;
    const cy = h / 2;
    const radius = Math.min(cx, cy) - 20;
    const innerRadius = radius * 0.62;
    const total = data.reduce((s, d) => s + d.value, 0);

    let startAngle = -Math.PI / 2;
    data.forEach((d, i) => {
      const sliceAngle = (d.value / total) * Math.PI * 2;
      ctx.beginPath();
      ctx.arc(cx, cy, radius, startAngle, startAngle + sliceAngle);
      ctx.arc(cx, cy, innerRadius, startAngle + sliceAngle, startAngle, true);
      ctx.closePath();
      ctx.fillStyle = d.color;
      ctx.fill();
      startAngle += sliceAngle;
    });

    // Center text
    if (options.centerText) {
      ctx.fillStyle = '#F1F5F9';
      ctx.font = `800 ${Math.round(radius * 0.4)}px Inter, sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(options.centerText, cx, cy - 6);
      if (options.centerSub) {
        ctx.font = `500 ${Math.round(radius * 0.14)}px Inter, sans-serif`;
        ctx.fillStyle = COLORS.text;
        ctx.fillText(options.centerSub, cx, cy + radius * 0.22);
      }
    }

    // Legend below
    if (options.showLegend !== false) {
      const legendY = h - 16;
      const legendGap = w / (data.length + 1);
      data.forEach((d, i) => {
        const lx = legendGap * (i + 1);
        ctx.fillStyle = d.color;
        ctx.beginPath();
        ctx.arc(lx - 30, legendY, 4, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = COLORS.text;
        ctx.font = '500 11px Inter, sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText(`${d.label} (${d.value})`, lx - 23, legendY + 4);
      });
    }
  }

  /**
   * Horizontal Bar Chart
   */
  function drawHBars(canvasId, data) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';
    ctx.scale(dpr, dpr);

    const w = rect.width;
    const h = rect.height;
    const padding = { top: 10, right: 20, bottom: 10, left: 120 };
    const chartW = w - padding.left - padding.right;
    const chartH = h - padding.top - padding.bottom;
    const barH = Math.min(28, chartH / data.length - 8);
    const maxVal = Math.max(...data.map(d => d.value), 1);

    data.forEach((d, i) => {
      const y = padding.top + i * (chartH / data.length) + (chartH / data.length - barH) / 2;
      const barW = (d.value / maxVal) * chartW;

      // Background track
      ctx.fillStyle = COLORS.grid;
      ctx.beginPath();
      ctx.roundRect(padding.left, y, chartW, barH, 4);
      ctx.fill();

      // Bar fill
      const grad = ctx.createLinearGradient(padding.left, 0, padding.left + barW, 0);
      grad.addColorStop(0, d.color || COLORS.accent);
      grad.addColorStop(1, d.colorEnd || COLORS.primary);
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.roundRect(padding.left, y, barW, barH, 4);
      ctx.fill();

      // Value label
      ctx.fillStyle = '#F1F5F9';
      ctx.font = '600 12px Inter, sans-serif';
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      ctx.fillText(d.value, padding.left + barW + 8, y + barH / 2);

      // Category label
      ctx.fillStyle = COLORS.text;
      ctx.font = '500 12px Inter, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(d.label, padding.left - 10, y + barH / 2);
    });
  }

  /**
   * Mini Sparkline (for future KPI cards)
   */
  function drawSparkline(canvasId, values, color = COLORS.accent) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    canvas.width = canvas.offsetWidth * dpr;
    canvas.height = canvas.offsetHeight * dpr;
    ctx.scale(dpr, dpr);

    const w = canvas.offsetWidth;
    const h = canvas.offsetHeight;
    const max = Math.max(...values);
    const min = Math.min(...values);
    const range = max - min || 1;
    const step = w / (values.length - 1);

    ctx.beginPath();
    values.forEach((v, i) => {
      const x = i * step;
      const y = h - ((v - min) / range) * (h - 4) - 2;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    ctx.stroke();

    // Area
    ctx.lineTo(w, h);
    ctx.lineTo(0, h);
    ctx.closePath();
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, color.replace(')', ',0.15)').replace('rgb', 'rgba'));
    grad.addColorStop(1, 'transparent');
    ctx.fillStyle = grad;
    ctx.fill();
  }

  return { drawDonut, drawHBars, drawSparkline, COLORS };

})();
