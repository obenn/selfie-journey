(() => {
  const form = document.getElementById('feedback-form');
  const message = document.getElementById('message');
  const error = document.getElementById('feedback-error');
  const submit = document.getElementById('submit-feedback');
  const success = document.getElementById('feedback-success');
  let submissionId = null;
  let submittedDraft = null;
  let pending = false;
  message.addEventListener('input', () => { document.getElementById('message-count').textContent = `${message.value.length.toLocaleString()} / 4,000`; });
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (pending || !form.reportValidity()) return;
    if (document.getElementById('website').value) return;
    const draft = { source: 'web', category: document.getElementById('category').value, message: message.value.trim() };
    const email = document.getElementById('contactEmail').value.trim();
    if (email) draft.contactEmail = email;
    if (!draft.message) { error.textContent = 'Add a little detail before sending your note.'; error.hidden = false; message.focus(); return; }
    const serialized = JSON.stringify(draft);
    if (serialized !== submittedDraft) { submissionId = crypto.randomUUID(); submittedDraft = serialized; }
    pending = true; submit.disabled = true; submit.firstElementChild.textContent = 'Sending your note…'; error.hidden = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000);
    try {
      const response = await fetch('/v1/feedback', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ...draft, submissionId }), signal: controller.signal, credentials: 'omit' });
      const result = await response.json().catch(() => null);
      if (!response.ok) throw new Error(response.status === 429 ? 'A few too many notes arrived at once. Please wait a little and try again. Your draft is still here.' : result?.error?.message || 'Your note could not be sent. Please try again in a moment.');
      if (!result?.receiptId) throw new Error('We couldn’t confirm your note was received. Please try again; the same note won’t be counted twice.');
      document.getElementById('receipt').textContent = `Reference: ${result.receiptId}`;
      form.hidden = true; success.hidden = false; success.focus();
    } catch (failure) {
      error.textContent = failure.name === 'AbortError' ? 'This is taking longer than expected. Please try again; your draft is safe here.' : failure instanceof TypeError ? 'We couldn’t connect. Check your connection and try again. Your draft is still here.' : failure.message;
      error.hidden = false;
    } finally { clearTimeout(timeout); pending = false; submit.disabled = false; submit.firstElementChild.textContent = 'Send your feedback'; }
  });
  document.getElementById('send-another').addEventListener('click', () => { form.reset(); submissionId = null; submittedDraft = null; error.hidden = true; success.hidden = true; form.hidden = false; document.getElementById('message-count').textContent = '0 / 4,000'; message.focus(); });
})();
