/* IronBark — chat.js
   AI-powered customer service chatbot.
   All traffic goes through /api/chat — no API keys in the browser. */

(function () {
    const launcher = document.getElementById('chat-launcher');
    const panel = document.getElementById('chat-panel');
    const closeBtn = document.getElementById('chat-close');
    const form = document.getElementById('chat-form');
    const input = document.getElementById('chat-input');
    const log = document.getElementById('chat-log');

    if (!launcher || !panel || !form || !input || !log) return;

    let opened = false;

    function addBubble(role, text) {
        const div = document.createElement('div');
        div.className = 'chat-bubble ' + role;
        div.textContent = text;
        log.appendChild(div);
        log.scrollTop = log.scrollHeight;
        return div;
    }

    function openPanel() {
        panel.classList.add('open');
        panel.setAttribute('aria-hidden', 'false');
        setTimeout(() => input.focus(), 200);
        if (!opened) {
            opened = true;
            addBubble('assistant',
                "Hey — I'm ClaWD, IronBark's AI support agent. Ask me anything about our services, products, compliance frameworks, or how we'd approach your environment.");
        }
    }

    function closePanel() {
        panel.classList.remove('open');
        panel.setAttribute('aria-hidden', 'true');
    }

    launcher.addEventListener('click', () => {
        if (panel.classList.contains('open')) closePanel();
        else openPanel();
    });
    closeBtn.addEventListener('click', closePanel);

    // Close on Esc
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && panel.classList.contains('open')) closePanel();
    });

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const msg = input.value.trim();
        if (!msg) return;
        addBubble('user', msg);
        input.value = '';
        input.disabled = true;

        const typing = addBubble('assistant typing', 'ClaWD is thinking…');

        try {
            const res = await window.IronBark.post('/api/chat', { message: msg });
            typing.remove();
            if (res.ok && res.data.reply) {
                addBubble('assistant', res.data.reply);
            } else {
                addBubble('assistant', res.data.error || 'Sorry — something went wrong. Try again in a moment.');
            }
        } catch (err) {
            typing.remove();
            addBubble('assistant', 'Connection error. Check your network and try again.');
        } finally {
            input.disabled = false;
            input.focus();
        }
    });
})();
