// Please see documentation at https://docs.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

document.addEventListener('DOMContentLoaded', function () {
    // ==========================================================================
    // AUTO-SCROLL ANIMATIONS (STAGGERED CASCADE)
    // ==========================================================================

    // 1. Select elements to animate
    // Note: We target 'tbody tr' specifically for the "one by one" effect in lists
    // IMPORTANT: Exclude modal elements to prevent interaction issues
    const animatedElements = document.querySelectorAll('.card:not(.modal-content), .table tbody tr:not(.modal *), h1, h2, h3, .list-group-item:not(.modal *), .alert:not(.modal *), .row > div:not(.modal *)');

    // 2. Add base class (opacity: 0) - but never to modal elements
    animatedElements.forEach(el => {
        // Skip if element is inside a modal
        if (!el.closest('.modal')) {
            el.classList.add('reveal-on-scroll');
        }
    });

    // 3. Stagger Queue System
    // User wants "one by one" appearance. If 10 rows appear at once, we queue them.
    const animationQueue = [];

    // Process one item from the queue every 100ms for a satisfying cascade
    setInterval(() => {
        if (animationQueue.length > 0) {
            const el = animationQueue.shift(); // Get next element
            if (el) {
                el.classList.add('is-visible');
            }
        }
    }, 100); // 100ms delay between each item

    // 4. Configure Observer
    const observerOptions = {
        threshold: 0.1, // Trigger when 10% visible
        rootMargin: "0px 0px -20px 0px" // Trigger slightly before bottom
    };

    const appearOnScroll = new IntersectionObserver(function (entries, appearOnScroll) {
        entries.forEach(entry => {
            if (!entry.isIntersecting) {
                // When scrolling UP/OUT:
                // Remove class immediately so it can replay later.
                entry.target.classList.remove('is-visible');

                // Also update queue to avoid ghost animations if user scrolls wildly
                const queueIndex = animationQueue.indexOf(entry.target);
                if (queueIndex > -1) {
                    animationQueue.splice(queueIndex, 1);
                }
            } else {
                // When scrolling DOWN/IN:
                // Don't show immediately. Add to stagger queue.
                if (!entry.target.classList.contains('is-visible') && !animationQueue.includes(entry.target)) {
                    animationQueue.push(entry.target);
                }
            }
        });
    }, observerOptions);

    // 5. Start Observing
    animatedElements.forEach(el => {
        appearOnScroll.observe(el);
    });
});
