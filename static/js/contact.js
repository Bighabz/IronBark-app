/* IronBark — contact.js */

(function () {
    const form = document.getElementById('contact-form');
    const status = document.getElementById('contact-status');
    if (!form) return;

    // Pre-fill message if ?interested= is present
    const params = new URLSearchParams(window.location.search);
    if (params.get('interested')) {
        const msg = form.querySelector('textarea[name="message"]');
        if (msg && !msg.value) {
            const name = params.get('interested').replace(/-/g, ' ');
            msg.value = `I'd like to learn more about your ${name} offering.`;
        }
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const submitBtn = form.querySelector('button[type="submit"]');
        const payload = Object.fromEntries(new FormData(form));
        status.textContent = '';
        submitBtn.disabled = true;
        submitBtn.textContent = 'SENDING…';

        try {
            const res = await window.IronBark.post('/api/contact', payload);
            if (res.ok) {
                form.reset();
                status.textContent = res.data.message || 'Message received.';
                status.style.color = 'var(--accent)';
            } else {
                status.textContent = res.data.error || 'Something went wrong. Please try again.';
                status.style.color = 'var(--amber)';
            }
        } catch (err) {
            status.textContent = 'Connection error. Please try again.';
            status.style.color = 'var(--amber)';
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = 'SEND MESSAGE <span class="arrow">→</span>';
        }
    });
})();
