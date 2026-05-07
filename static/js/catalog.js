/* IronBark — catalog.js
   Smart Product Catalog: filter, search, and AI-powered recommendations. */

(function () {
    const grid = document.getElementById('catalog-grid');
    const search = document.getElementById('catalog-search');
    const filterBtns = document.querySelectorAll('.filter-btn');
    if (!grid) return;

    const cards = Array.from(grid.querySelectorAll('.catalog-card'));

    let activeFilter = 'all';
    let query = '';

    function applyFilters() {
        const q = query.toLowerCase().trim();
        cards.forEach(card => {
            const kindMatch = activeFilter === 'all' || card.dataset.kind === activeFilter;
            const searchMatch = !q || (card.dataset.search || '').includes(q);
            card.classList.toggle('hidden', !(kindMatch && searchMatch));
        });
    }

    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeFilter = btn.dataset.filter;
            applyFilters();
        });
    });

    if (search) {
        search.addEventListener('input', (e) => {
            query = e.target.value;
            applyFilters();
        });
    }

    // "Explain for my use case" — AI-powered recommendation
    grid.addEventListener('click', async (e) => {
        const explainBtn = e.target.closest('.explain-btn');
        const cancelBtn = e.target.closest('.explain-cancel');
        const submitBtn = e.target.closest('.explain-submit');

        if (explainBtn) {
            const card = explainBtn.closest('.catalog-card');
            const panel = card.querySelector('.explain-panel');
            panel.hidden = false;
            const formEl = panel.querySelector('.explain-form');
            const result = panel.querySelector('.explain-result');
            formEl.hidden = false;
            result.hidden = true;
            panel.querySelector('textarea').focus();
        }

        if (cancelBtn) {
            const panel = cancelBtn.closest('.explain-panel');
            panel.hidden = true;
        }

        if (submitBtn) {
            const card = submitBtn.closest('.catalog-card');
            const slug = card.dataset.slug;
            const panel = card.querySelector('.explain-panel');
            const textarea = panel.querySelector('textarea');
            const formEl = panel.querySelector('.explain-form');
            const result = panel.querySelector('.explain-result');
            const resultText = result.querySelector('.explain-text');

            const context = textarea.value.trim();
            if (!context) {
                textarea.focus();
                return;
            }

            submitBtn.disabled = true;
            submitBtn.textContent = 'Analyzing…';

            try {
                const res = await window.IronBark.post('/api/ai/recommend', { slug, context });
                if (res.ok && res.data.recommendation) {
                    formEl.hidden = true;
                    result.hidden = false;
                    resultText.textContent = res.data.recommendation;
                } else {
                    alert(res.data.error || 'The AI assistant is unavailable. Please try again shortly.');
                }
            } catch (err) {
                alert('Connection error. Please try again.');
            } finally {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Ask IronBark AI';
            }
        }
    });

    // Deep link to #slug on load
    if (window.location.hash) {
        const target = document.querySelector(window.location.hash);
        if (target && target.classList.contains('catalog-card')) {
            setTimeout(() => target.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100);
        }
    }

    // Pre-fill contact from ?interested=slug
    const params = new URLSearchParams(window.location.search);
    if (params.get('interested')) {
        const msg = document.querySelector('textarea[name="message"]');
        if (msg && !msg.value) {
            msg.value = `I'm interested in learning more about your ${params.get('interested').replace(/-/g, ' ')} offering.`;
        }
    }
})();
