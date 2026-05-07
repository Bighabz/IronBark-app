/* IronBark — main.js
   Shared utilities + mobile nav toggle. */

(function () {
    // Expose CSRF helper globally
    window.IronBark = window.IronBark || {};
    window.IronBark.csrf = function () {
        const m = document.querySelector('meta[name="csrf-token"]');
        return m ? m.getAttribute('content') : '';
    };
    window.IronBark.post = async function (url, body) {
        const res = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.IronBark.csrf()
            },
            body: JSON.stringify(body || {})
        });
        const data = await res.json().catch(() => ({}));
        return { ok: res.ok, status: res.status, data };
    };

    // Mobile nav
    const toggle = document.querySelector('.nav-toggle');
    const links = document.querySelector('.nav-links');
    if (toggle && links) {
        toggle.addEventListener('click', () => {
            const open = links.classList.toggle('open');
            toggle.setAttribute('aria-expanded', String(open));
        });
    }

    // Catalog search keyboard shortcut on desktop (⌘K / Ctrl+K)
    document.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
            const search = document.getElementById('catalog-search');
            if (search) {
                e.preventDefault();
                search.focus();
            }
        }
    });
})();
