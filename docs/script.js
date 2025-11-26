/**
 * Conduit Landing Page
 * Smooth interactions and animations
 */

document.addEventListener('DOMContentLoaded', () => {
    // ============================================
    // SMOOTH SCROLL
    // ============================================
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const target = document.querySelector(targetId);
            if (target) {
                const navHeight = document.querySelector('.navbar').offsetHeight;
                const targetPosition = target.offsetTop - navHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
                
                // Close mobile menu if open
                mobileMenu.classList.remove('active');
            }
        });
    });

    // ============================================
    // MOBILE MENU
    // ============================================
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const mobileMenu = document.querySelector('.mobile-menu');
    
    if (mobileMenuBtn && mobileMenu) {
        mobileMenuBtn.addEventListener('click', () => {
            mobileMenu.classList.toggle('active');
            mobileMenuBtn.classList.toggle('active');
        });
        
        // Close menu when clicking a link
        mobileMenu.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                mobileMenu.classList.remove('active');
                mobileMenuBtn.classList.remove('active');
            });
        });
    }

    // ============================================
    // NAVBAR SCROLL EFFECT
    // ============================================
    const navbar = document.querySelector('.navbar');
    let lastScroll = 0;
    
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 100) {
            navbar.style.background = 'rgba(10, 10, 12, 0.9)';
        } else {
            navbar.style.background = 'rgba(10, 10, 12, 0.6)';
        }
        
        lastScroll = currentScroll;
    }, { passive: true });

    // ============================================
    // INTERSECTION OBSERVER - FADE IN
    // ============================================
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -60px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Observe feature cards
    document.querySelectorAll('.feature-card').forEach(el => {
        el.classList.add('fade-in');
        observer.observe(el);
    });
    
    // Observe stat cards
    document.querySelectorAll('.stat-card').forEach((el, i) => {
        el.classList.add('fade-in');
        el.style.transitionDelay = `${i * 0.1}s`;
        observer.observe(el);
    });
    
    // Observe gallery items
    document.querySelectorAll('.gallery-item').forEach((el, i) => {
        el.classList.add('fade-in');
        el.style.transitionDelay = `${i * 0.1}s`;
        observer.observe(el);
    });
    
    // Observe section headers
    document.querySelectorAll('.section-header').forEach(el => {
        el.classList.add('fade-in');
        observer.observe(el);
    });

    // ============================================
    // PARALLAX ORBS (subtle effect)
    // ============================================
    const orbs = document.querySelectorAll('.orb');
    
    if (window.matchMedia('(prefers-reduced-motion: no-preference)').matches) {
        window.addEventListener('scroll', () => {
            const scrollY = window.pageYOffset;
            
            orbs.forEach((orb, i) => {
                const speed = (i + 1) * 0.03;
                orb.style.transform = `translateY(${scrollY * speed}px)`;
            });
        }, { passive: true });
    }

    // ============================================
    // DEVICE FRAME TILT ON MOUSE MOVE
    // ============================================
    const deviceFrame = document.querySelector('.device-frame');
    const heroSection = document.querySelector('.hero');
    
    if (deviceFrame && heroSection && window.matchMedia('(prefers-reduced-motion: no-preference)').matches) {
        heroSection.addEventListener('mousemove', (e) => {
            const rect = heroSection.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width - 0.5;
            const y = (e.clientY - rect.top) / rect.height - 0.5;
            
            const tiltX = y * 10;
            const tiltY = -x * 10;
            
            deviceFrame.style.transform = `perspective(1000px) rotateX(${tiltX}deg) rotateY(${tiltY}deg) scale(1.02)`;
        });
        
        heroSection.addEventListener('mouseleave', () => {
            deviceFrame.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale(1)';
        });
    }

    // ============================================
    // GALLERY DRAG SCROLL
    // ============================================
    const galleryTrack = document.querySelector('.gallery-track');
    
    if (galleryTrack) {
        let isDown = false;
        let startX;
        let scrollLeft;
        
        galleryTrack.addEventListener('mousedown', (e) => {
            isDown = true;
            galleryTrack.style.cursor = 'grabbing';
            startX = e.pageX - galleryTrack.offsetLeft;
            scrollLeft = galleryTrack.scrollLeft;
        });
        
        galleryTrack.addEventListener('mouseleave', () => {
            isDown = false;
            galleryTrack.style.cursor = 'grab';
        });
        
        galleryTrack.addEventListener('mouseup', () => {
            isDown = false;
            galleryTrack.style.cursor = 'grab';
        });
        
        galleryTrack.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();
            const x = e.pageX - galleryTrack.offsetLeft;
            const walk = (x - startX) * 1.5;
            galleryTrack.scrollLeft = scrollLeft - walk;
        });
        
        // Set initial cursor
        galleryTrack.style.cursor = 'grab';
    }

    // ============================================
    // CTA RING ANIMATION RESET
    // ============================================
    const ctaSection = document.querySelector('.cta-section');
    const ctaRings = document.querySelectorAll('.cta-ring');
    
    if (ctaSection && ctaRings.length) {
        const ctaObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Reset animation when section comes into view
                    ctaRings.forEach(ring => {
                        ring.style.animation = 'none';
                        ring.offsetHeight; // Trigger reflow
                        ring.style.animation = null;
                    });
                }
            });
        }, { threshold: 0.3 });
        
        ctaObserver.observe(ctaSection);
    }

    // ============================================
    // BUTTON RIPPLE EFFECT
    // ============================================
    document.querySelectorAll('.btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            
            ripple.style.cssText = `
                position: absolute;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                pointer-events: none;
                transform: scale(0);
                animation: ripple 0.6s ease-out;
                left: ${e.clientX - rect.left}px;
                top: ${e.clientY - rect.top}px;
                width: 0;
                height: 0;
            `;
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);
            
            setTimeout(() => ripple.remove(), 600);
        });
    });

    // Add ripple keyframes
    const style = document.createElement('style');
    style.textContent = `
        @keyframes ripple {
            to {
                width: 200px;
                height: 200px;
                margin-left: -100px;
                margin-top: -100px;
                opacity: 0;
                transform: scale(1);
            }
        }
    `;
    document.head.appendChild(style);

    // ============================================
    // PRELOAD IMAGES
    // ============================================
    const preloadImages = [
        'screenshots/1.png',
        'screenshots/2.png',
        'screenshots/3.png',
        'screenshots/4.png'
    ];
    
    preloadImages.forEach(src => {
        const img = new Image();
        img.src = src;
    });

    // ============================================
    // FETCH GITHUB STATS
    // ============================================
    const formatNumber = (num) => {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1).replace(/\.0$/, '') + 'M';
        }
        if (num >= 1000) {
            return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
        }
        return num.toString();
    };

    const starsElement = document.getElementById('github-stars');
    const downloadsElement = document.getElementById('github-downloads');
    
    // Fetch repo stats (stars)
    if (starsElement) {
        fetch('https://api.github.com/repos/cogwheel0/conduit')
            .then(response => response.json())
            .then(data => {
                if (data.stargazers_count !== undefined) {
                    starsElement.textContent = formatNumber(data.stargazers_count);
                    starsElement.classList.add('loaded');
                }
            })
            .catch(() => {
                starsElement.textContent = '★';
            });
    }

    // Fetch releases (downloads)
    if (downloadsElement) {
        fetch('https://api.github.com/repos/cogwheel0/conduit/releases')
            .then(response => response.json())
            .then(releases => {
                if (Array.isArray(releases)) {
                    const totalDownloads = releases.reduce((total, release) => {
                        return total + release.assets.reduce((assetTotal, asset) => {
                            return assetTotal + (asset.download_count || 0);
                        }, 0);
                    }, 0);
                    
                    if (totalDownloads > 0) {
                        downloadsElement.textContent = formatNumber(totalDownloads);
                    } else {
                        // If no GitHub downloads, show a generic indicator
                        downloadsElement.textContent = 'New';
                    }
                    downloadsElement.classList.add('loaded');
                }
            })
            .catch(() => {
                downloadsElement.textContent = '↓';
            });
    }

    console.log('✨ Conduit landing page initialized');
});
