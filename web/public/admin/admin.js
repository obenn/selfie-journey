(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const number = value => Number(value || 0).toLocaleString();
  const categories = { bug: 'Technical issue', idea: 'An idea for the journey', other: 'A little note' };
  const statuses = { new: 'New', reviewing: 'Reviewing', resolved: 'Resolved' };
  const events = { app_open: 'App opened', portrait_saved: 'Portrait saved', portrait_retake: 'Portrait retaken', camera_opened: 'Camera opened', camera_error: 'Camera issue', backup_completed: 'Backup completed', backup_error: 'Backup issue', export_completed: 'Film exported', export_error: 'Export issue', feedback_opened: 'Feedback opened' };
  const date = (value, options = { month: 'short', day: 'numeric' }) => new Intl.DateTimeFormat(undefined, { timeZone: 'UTC', ...options }).format(new Date(value));
  let overviewSequence = 0, listSequence = 0, detailSequence = 0, nextCursor = null, selectedFeedback = null, statusPending = false;
  let listItems = [], currentFilters = {}, lastFocusedRow = null;
  function element(tag, className, text) { const node = document.createElement(tag); if (className) node.className = className; if (text !== undefined) node.textContent = text; return node; }
  function setBusy(id, value) { $(id).setAttribute('aria-busy', String(value)); }
  function showError(id, error) {
    const node = $(id); node.replaceChildren(document.createTextNode(error.message || 'Something went wrong. Please try again.'));
    if (error.authentication) { const link = element('a', '', 'Sign in again'); link.href = '/'; node.append(document.createTextNode(' '), link); }
    node.hidden = false;
  }
  async function api(path, options = {}) {
    const controller = new AbortController(), timeout = setTimeout(() => controller.abort(), 20000);
    try {
      const response = await fetch(path, { ...options, credentials: 'same-origin', signal: controller.signal, headers: { Accept: 'application/json', ...options.headers } });
      const result = await response.json().catch(() => null);
      if ([401, 403].includes(response.status) || (response.redirected && !result)) { const error = new Error('Your private session has expired or this account does not have access.'); error.authentication = true; throw error; }
      if (!response.ok) throw new Error(result?.error?.message || 'The dashboard could not connect. Please try again shortly.');
      if (!result || typeof result !== 'object') throw new Error('The server returned an unexpected response. Try refreshing the dashboard.');
      return result;
    } catch (error) {
      if (error.name === 'AbortError') throw new Error('This is taking longer than expected. Check your connection and try again.');
      if (error instanceof TypeError) throw new Error('We couldn’t reach your workspace. Check your connection and try again.');
      throw error;
    } finally { clearTimeout(timeout); }
  }
  function empty(container, title, copy) { const state = element('div', 'empty-state'); const icon = element('span', '', '✉'); icon.setAttribute('aria-hidden', 'true'); state.append(icon, element('h3', '', title), element('p', '', copy)); container.replaceChildren(state); }
  function noData(id, copy) { $(id).replaceChildren(element('p', 'empty-copy', copy)); }
  function svgElement(tag, attributes = {}) { const node = document.createElementNS('http://www.w3.org/2000/svg', tag); Object.entries(attributes).forEach(([key, value]) => node.setAttribute(key, String(value))); return node; }
  function renderChart(daily) {
    const container = $('activity-chart'); container.replaceChildren();
    if (!daily.some(day => Number(day.events) > 0)) { noData('activity-chart', 'The story starts with the first event. Activity will appear here as the app is used with telemetry enabled.'); renderDailyTable(daily); return; }
    const width = 650, height = 255, left = 45, right = 13, top = 16, bottom = 32;
    const plotWidth = width - left - right, plotHeight = height - top - bottom;
    const highest = Math.max(...daily.map(day => Number(day.events) || 0));
    const max = Math.max(4, Math.ceil(highest / 4) * 4);
    const chart = svgElement('svg', { viewBox: `0 0 ${width} ${height}`, role: 'img', 'aria-labelledby': 'activity-title activity-description' });
    const title = svgElement('title', { id: 'activity-title' }); title.textContent = 'Daily app events';
    const description = svgElement('desc', { id: 'activity-description' }); description.textContent = `${number(daily.reduce((sum, day) => sum + Number(day.events || 0), 0))} app events over ${daily.length} days. Daily values are available in the table below.`;
    chart.append(title, description);
    for (let index = 0; index < 5; index++) {
      const y = top + index * plotHeight / 4;
      chart.append(svgElement('line', { x1: left, y1: y, x2: width - right, y2: y, class: 'chart-grid' }));
      const label = svgElement('text', { x: left - 10, y: y + 3, 'text-anchor': 'end', class: 'chart-label' });
      label.textContent = new Intl.NumberFormat(undefined, { notation: 'compact', maximumFractionDigits: 1 }).format(max - index * max / 4); chart.append(label);
    }
    const points = daily.map((day, index) => [left + index * plotWidth / Math.max(1, daily.length - 1), top + plotHeight - (Number(day.events) || 0) / max * plotHeight]);
    const area = `M ${left},${top + plotHeight} L ${points.map(point => point.join(',')).join(' L ')} L ${left + plotWidth},${top + plotHeight} Z`;
    chart.append(svgElement('path', { d: area, class: 'chart-area' }), svgElement('polyline', { points: points.map(point => point.join(',')).join(' '), class: 'chart-line' }));
    daily.forEach((day, index) => { const [x, y] = points[index]; const dot = svgElement('circle', { cx: x, cy: y, r: daily.length <= 7 ? 4 : 2.5, class: 'chart-dot' }); const tip = svgElement('title'); tip.textContent = `${date(day.date)}: ${number(day.events)} app events, ${number(day.feedback)} feedback`; dot.append(tip); chart.append(dot); });
    [0, Math.floor((daily.length - 1) / 2), daily.length - 1].forEach((index, labelIndex) => { const label = svgElement('text', { x: points[index][0], y: height - 6, 'text-anchor': ['start', 'middle', 'end'][labelIndex], class: 'chart-label' }); label.textContent = date(daily[index].date); chart.append(label); });
    container.append(chart); renderDailyTable(daily);
  }
  function renderDailyTable(daily) {
    const table = element('table', 'daily-table'), head = document.createElement('thead'), row = document.createElement('tr');
    ['Date (UTC)', 'App events', 'Feedback'].forEach(label => { const cell = element('th', '', label); cell.scope = 'col'; row.append(cell); }); head.append(row);
    const body = document.createElement('tbody'); daily.forEach(day => { const item = document.createElement('tr'); [date(day.date, { year: 'numeric', month: 'short', day: 'numeric' }), number(day.events), number(day.feedback)].forEach(value => item.append(element('td', '', value))); body.append(item); });
    table.append(head, body); $('daily-table').replaceChildren(table);
  }
  function renderEvents(items) {
    const node = $('event-list'); node.replaceChildren();
    if (!items.length) { noData('event-list', 'No app events in this date range yet. Feature activity will appear here when events arrive.'); return; }
    const max = Math.max(...items.map(item => Number(item.count)), 1);
    items.forEach(item => { const row = element('div', 'event-row'), progress = element('progress'); progress.max = max; progress.value = Number(item.count); progress.setAttribute('aria-label', `${events[item.name] || item.name}: ${number(item.count)}`); row.append(element('span', 'event-name', events[item.name] || item.name), element('span', 'event-count', number(item.count)), progress); node.append(row); });
  }
  function renderModes(items) {
    const node = $('mode-list'); node.replaceChildren();
    if (!items.length) { noData('mode-list', 'No telemetry received in this date range.'); return; }
    ['full', 'limited'].forEach(mode => { const item = element('div', 'mode-item'), dot = element('span', 'mode-dot'), copy = element('div'); dot.setAttribute('aria-hidden', 'true'); copy.append(element('strong', '', number(items.find(row => row.mode === mode)?.count)), element('small', '', mode === 'full' ? 'Full telemetry' : 'Limited telemetry')); item.append(dot, copy); node.append(item); });
  }
  function renderVersions(items) {
    const node = $('version-list'); node.replaceChildren();
    if (!items.length) { noData('version-list', 'No version information yet. Limited telemetry does not include app versions.'); return; }
    items.forEach(item => { const chip = element('div', 'version-item'); chip.append(element('strong', '', `v${item.version}`), document.createTextNode(`${number(item.count)} events`)); node.append(chip); });
  }
  async function loadOverview() {
    const sequence = ++overviewSequence; $('overview-error').hidden = true; $('refresh').disabled = true;
    ['metrics', 'activity-chart', 'event-list'].forEach(id => setBusy(id, true));
    try {
      const data = await api(`/api/admin/overview?days=${encodeURIComponent($('range').value)}`); if (sequence !== overviewSequence) return;
      document.querySelectorAll('[data-metric]').forEach(node => { node.textContent = number(data.totals[node.dataset.metric]); });
      $('installations-caption').textContent = `Full telemetry only · last ${Math.min(data.rangeDays, 30)} days`;
      renderChart(data.daily || []); renderEvents(data.eventCounts || []); renderModes(data.telemetryModes || []); renderVersions(data.versions || []);
      $('last-updated').textContent = `Updated ${new Intl.DateTimeFormat(undefined, { hour: 'numeric', minute: '2-digit' }).format(new Date())} · Overview uses UTC dates`;
    } catch (error) {
      if (sequence !== overviewSequence) return;
      showError('overview-error', error); document.querySelectorAll('[data-metric]').forEach(node => { node.textContent = '—'; });
      ['activity-chart', 'event-list', 'mode-list', 'version-list'].forEach(id => noData(id, 'Unable to load this information. Use refresh to try again.'));
      $('daily-table').replaceChildren(); $('last-updated').textContent = 'Overview unavailable · Try refreshing';
    } finally { if (sequence === overviewSequence) { $('refresh').disabled = false; ['metrics', 'activity-chart', 'event-list'].forEach(id => setBusy(id, false)); } }
  }
  function feedbackRow(item) {
    const row = element('button', 'feedback-row'); row.type = 'button'; row.setAttribute('aria-label', `${categories[item.category] || 'Feedback'}, ${statuses[item.status] || item.status}, ${date(item.createdAt)}: ${item.preview}`);
    const icon = element('span', `category-icon ${['bug', 'idea', 'other'].includes(item.category) ? item.category : 'other'}`, item.category === 'bug' ? '⌘' : item.category === 'idea' ? '✦' : '✉'); icon.setAttribute('aria-hidden', 'true');
    const content = element('div'), heading = element('div', 'feedback-row-heading'); heading.append(element('strong', '', categories[item.category] || 'Feedback'), element('span', `status-pill ${statuses[item.status] ? item.status : ''}`, statuses[item.status] || item.status));
    const meta = element('div', 'feedback-meta'); meta.append(element('span', '', item.source === 'ios' ? 'From the app' : 'From the website')); if (item.hasDiagnostics) meta.append(element('span', '', 'Diagnostic attachment'));
    content.append(heading, element('p', 'feedback-preview', item.preview), meta);
    const timestamp = element('span', 'feedback-date'), time = element('time', '', date(item.createdAt)); time.dateTime = item.createdAt; timestamp.append(time, element('span', '', '↗'));
    row.append(icon, content, timestamp); row.addEventListener('click', () => { lastFocusedRow = row; openDetail(item.id); }); return row;
  }
  async function loadFeedback(append = false) {
    const sequence = ++listSequence, cursor = append ? nextCursor : null;
    if (append && !cursor) return;
    if (!append) { currentFilters = { q: $('search').value.trim(), status: $('status-filter').value, category: $('category-filter').value }; nextCursor = null; listItems = []; empty($('feedback-list'), 'Opening the inbox…', 'Your feedback is on its way.'); }
    $('feedback-error').hidden = true; $('load-more').disabled = true; setBusy('feedback-list', true);
    try {
      const params = new URLSearchParams({ ...currentFilters, limit: '25' }); if (cursor) params.set('cursor', cursor);
      const data = await api(`/api/admin/feedback?${params}`); if (sequence !== listSequence) return;
      listItems = append ? [...listItems, ...data.items] : data.items; nextCursor = data.nextCursor;
      $('feedback-total').textContent = `${number(data.total)} ${Number(data.total) === 1 ? 'note' : 'notes'}`;
      if (!listItems.length) { const filtered = currentFilters.q || currentFilters.status !== 'all' || currentFilters.category !== 'all'; empty($('feedback-list'), filtered ? 'No notes match just yet.' : 'A quiet inbox, for now.', filtered ? 'Try another search or clear your filters to see more feedback.' : 'When someone sends a thought or reports an issue, it will land right here.'); }
      else $('feedback-list').replaceChildren(...listItems.map(feedbackRow));
      $('load-more').hidden = !nextCursor;
    } catch (error) { if (sequence !== listSequence) return; showError('feedback-error', error); if (!append) { empty($('feedback-list'), 'We couldn’t open the inbox.', 'Your feedback is still safe. Try the search button or refresh the dashboard.'); $('feedback-total').textContent = 'Unavailable'; } }
    finally { if (sequence === listSequence) { setBusy('feedback-list', false); $('load-more').disabled = false; } }
  }
  async function updateBadge() {
    try { const data = await api('/api/admin/feedback?status=new&limit=1'); $('inbox-badge').hidden = !Number(data.total); $('inbox-badge').textContent = Number(data.total) > 99 ? '99+' : number(data.total); } catch { $('inbox-badge').hidden = true; }
  }
  function renderDiagnostics(diagnostics) {
    const details = element('details', 'diagnostics'); details.append(element('summary', '', `Optional diagnostic attachment · ${number(diagnostics.events?.length)} events`));
    details.append(element('p', '', 'Predefined local event codes shared by the sender. Ages are approximate at submission. Attachments are removed after 30 days.'));
    const definitions = element('dl'); [['App version', diagnostics.appVersion], ['OS version', diagnostics.osVersion], ['Device class', diagnostics.deviceClass]].forEach(([label, value]) => { definitions.append(element('dt', '', label), element('dd', '', value)); }); details.append(definitions);
    if (diagnostics.events?.length) { const scroll = element('div', 'table-scroll'), table = element('table'), head = element('thead'), header = element('tr'); ['Event code', 'Age at submission'].forEach(label => { const th = element('th', '', label); th.scope = 'col'; header.append(th); }); head.append(header); const body = element('tbody'); diagnostics.events.forEach(event => { const row = element('tr'); row.append(element('td', '', event.code), element('td', '', `${number(event.ageSeconds)} seconds`)); body.append(row); }); table.append(head, body); scroll.append(table); details.append(scroll); }
    return details;
  }
  async function openDetail(id) {
    const sequence = ++detailSequence; selectedFeedback = null; $('detail-error').hidden = true; $('status-form').hidden = true; $('status-result').textContent = '';
    const heading = element('h2', '', 'Opening this note…'); heading.id = 'detail-title'; $('detail-content').replaceChildren(heading, element('p', 'empty-copy', 'Loading the full message.'));
    if (!$('feedback-dialog').open) $('feedback-dialog').showModal();
    try {
      const data = await api(`/api/admin/feedback/${encodeURIComponent(id)}`); if (sequence !== detailSequence || !$('feedback-dialog').open) return;
      selectedFeedback = data; const title = element('h2', '', categories[data.category] || 'A little note'); title.id = 'detail-title';
      const meta = element('div', 'detail-meta'); meta.append(element('span', `status-pill ${statuses[data.status] ? data.status : ''}`, statuses[data.status] || data.status), element('span', '', `${date(data.createdAt, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })} UTC`), element('span', '', data.source === 'ios' ? 'From the app' : 'From the website'));
      const content = $('detail-content'); content.replaceChildren(title, meta, element('p', 'detail-message', data.message));
      if (data.contactEmail) { const email = element('p', 'detail-email', 'Reply address: '), link = element('a', '', data.contactEmail); link.href = `mailto:${encodeURIComponent(data.contactEmail)}`; email.append(link); content.append(email); }
      else content.append(element('p', 'detail-email', 'The sender did not leave an email address.'));
      if (data.diagnostics) content.append(renderDiagnostics(data.diagnostics));
      content.append(element('p', 'detail-id', `REFERENCE ${data.id}`)); $('detail-status').value = data.status; $('status-form').hidden = false; $('save-status').disabled = false;
    } catch (error) { if (sequence !== detailSequence) return; heading.textContent = 'This note is unavailable.'; $('detail-content').replaceChildren(heading); showError('detail-error', error); }
  }
  $('status-form').addEventListener('submit', async event => {
    event.preventDefault(); if (statusPending || !selectedFeedback) return;
    const id = selectedFeedback.id, status = $('detail-status').value, sequence = detailSequence;
    statusPending = true; $('save-status').disabled = true; $('detail-status').disabled = true; $('detail-error').hidden = true; $('status-result').textContent = '';
    try {
      await api(`/api/admin/feedback/${encodeURIComponent(id)}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'SelfieJourneyAdmin' }, body: JSON.stringify({ status }) });
      if (sequence === detailSequence) { selectedFeedback.status = status; $('status-result').textContent = `Saved as ${statuses[status].toLowerCase()}.`; const pill = $('detail-content').querySelector('.status-pill'); pill.textContent = statuses[status]; pill.className = `status-pill ${status}`; }
      loadFeedback(); loadOverview(); updateBadge();
    } catch (error) { if (sequence === detailSequence) showError('detail-error', error); }
    finally { statusPending = false; $('save-status').disabled = false; $('detail-status').disabled = false; }
  });
  $('close-detail').addEventListener('click', () => $('feedback-dialog').close());
  $('feedback-dialog').addEventListener('close', () => { ++detailSequence; selectedFeedback = null; if (lastFocusedRow?.isConnected) lastFocusedRow.focus(); });
  $('range').addEventListener('change', loadOverview);
  $('refresh').addEventListener('click', () => { loadOverview(); loadFeedback(); updateBadge(); });
  $('feedback-filters').addEventListener('submit', event => { event.preventDefault(); loadFeedback(); });
  ['status-filter', 'category-filter'].forEach(id => $(id).addEventListener('change', () => loadFeedback()));
  $('load-more').addEventListener('click', () => loadFeedback(true));
  $('toggle-daily').addEventListener('click', () => { const hidden = !$('daily-table').hidden; $('daily-table').hidden = hidden; $('toggle-daily').setAttribute('aria-expanded', String(!hidden)); $('toggle-daily').textContent = hidden ? 'View daily values' : 'Hide daily values'; });
  function updateNavigation() { document.querySelectorAll('[data-section]').forEach(link => { const active = link.dataset.section === (location.hash === '#feedback' ? 'feedback' : 'overview'); link.classList.toggle('active', active); if (active) link.setAttribute('aria-current', 'location'); else link.removeAttribute('aria-current'); }); }
  window.addEventListener('hashchange', updateNavigation); updateNavigation(); loadOverview(); loadFeedback(); updateBadge();
})();
