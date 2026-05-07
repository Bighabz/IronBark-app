/* IronBark — status.js
   Engagement status lookup with AI-written summary. */

(function () {
    const form = document.getElementById('status-form');
    const msg = document.getElementById('status-msg');
    const result = document.getElementById('status-result');
    if (!form) return;

    function fmtDate(iso) {
        if (!iso) return '—';
        try {
            const d = new Date(iso);
            if (isNaN(d)) return iso;
            return d.toLocaleDateString(undefined, {
                year: 'numeric', month: 'short', day: 'numeric',
                hour: '2-digit', minute: '2-digit'
            });
        } catch { return iso; }
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = Object.fromEntries(new FormData(form));
        const submitBtn = form.querySelector('button[type="submit"]');
        msg.textContent = '';
        submitBtn.disabled = true;
        submitBtn.textContent = 'LOOKING UP…';
        result.hidden = true;

        try {
            const res = await window.IronBark.post('/api/status', payload);
            if (res.ok && res.data.engagement) {
                const e = res.data.engagement;
                document.getElementById('r-code').textContent = e.engagement_code;
                document.getElementById('r-company').textContent = e.client_company;
                document.getElementById('r-service').textContent = e.service_type;
                document.getElementById('r-last').textContent = fmtDate(e.last_scan_at);
                document.getElementById('r-next').textContent = fmtDate(e.next_scan_at);
                document.getElementById('r-crit').textContent = e.findings_critical;
                document.getElementById('r-high').textContent = e.findings_high;
                document.getElementById('r-med').textContent = e.findings_medium;
                document.getElementById('r-low').textContent = e.findings_low;
                document.getElementById('r-summary').textContent = e.ai_summary || '—';

                const statusBadge = document.getElementById('r-status');
                statusBadge.textContent = (e.status || '').replace('_', ' ').toUpperCase();
                statusBadge.className = 'status-badge mono ' + (e.status || '');

                const pct = parseInt(e.remediation_percent, 10) || 0;
                document.getElementById('r-pct').textContent = pct + '%';
                // Trigger transition after display
                const fill = document.getElementById('r-fill');
                fill.style.width = '0%';
                result.hidden = false;
                setTimeout(() => { fill.style.width = pct + '%'; }, 50);

                msg.textContent = '';
                result.scrollIntoView({ behavior: 'smooth', block: 'start' });
            } else {
                msg.textContent = res.data.error || 'No matching engagement found.';
                msg.style.color = 'var(--amber)';
            }
        } catch (err) {
            msg.textContent = 'Connection error. Please try again.';
            msg.style.color = 'var(--amber)';
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = 'LOOK UP STATUS →';
        }
    });
})();
