// Mermaid Diagram Zoom Functionality
// Enables double-click zoom on Mermaid diagrams with pan and navigation

(function() {
    'use strict';
    
    function initMermaidZoom() {
        // Wait for Mermaid to render diagrams
        const checkMermaid = setInterval(function() {
            const mermaidDiagrams = document.querySelectorAll('.mermaid:not(.mermaid-zoom-processed)');
            
            if (mermaidDiagrams.length === 0) {
                return;
            }
            
            mermaidDiagrams.forEach(function(diagram) {
                // Mark as processed
                diagram.classList.add('mermaid-zoom-processed');
                
                // Skip if already wrapped
                if (diagram.parentElement && diagram.parentElement.classList.contains('mermaid-zoom-wrapper')) {
                    return;
                }
                
                // Create a wrapper div for zoom functionality
                const wrapper = document.createElement('div');
                wrapper.className = 'mermaid-zoom-wrapper';
                
                // Create container for the diagram
                const diagramContainer = document.createElement('div');
                diagramContainer.className = 'mermaid-zoom-container';
                
                // Wrap the diagram
                diagram.parentNode.insertBefore(wrapper, diagram);
                wrapper.appendChild(diagramContainer);
                diagramContainer.appendChild(diagram);
                
                // Add zoom overlay indicator
                const zoomIndicator = document.createElement('div');
                zoomIndicator.className = 'mermaid-zoom-indicator';
                zoomIndicator.innerHTML = '🔍 Double-click to zoom';
                wrapper.appendChild(zoomIndicator);
                
                // Add navigation controls
                const navControls = document.createElement('div');
                navControls.className = 'mermaid-zoom-controls';
                navControls.innerHTML = `
                    <button class="zoom-control-btn" data-action="zoom-out">➖</button>
                    <button class="zoom-control-btn" data-action="zoom-in">➕</button>
                    <button class="zoom-control-btn" data-action="reset">🔄</button>
                    <button class="zoom-control-btn" data-action="close">✕</button>
                `;
                wrapper.appendChild(navControls);
                
                // State management
                let isZoomed = false;
                let isDragging = false;
                let startX = 0;
                let startY = 0;
                let scrollLeft = 0;
                let scrollTop = 0;
                let currentScale = 1.5;
                
                // Pan functionality
                function startDrag(e) {
                    if (!isZoomed) return;
                    isDragging = true;
                    diagramContainer.style.cursor = 'grabbing';
                    startX = e.pageX - diagramContainer.offsetLeft;
                    startY = e.pageY - diagramContainer.offsetTop;
                    scrollLeft = diagramContainer.scrollLeft;
                    scrollTop = diagramContainer.scrollTop;
                }
                
                function drag(e) {
                    if (!isDragging || !isZoomed) return;
                    e.preventDefault();
                    const x = e.pageX - diagramContainer.offsetLeft;
                    const y = e.pageY - diagramContainer.offsetTop;
                    const walkX = (x - startX) * 2;
                    const walkY = (y - startY) * 2;
                    diagramContainer.scrollLeft = scrollLeft - walkX;
                    diagramContainer.scrollTop = scrollTop - walkY;
                }
                
                function stopDrag() {
                    isDragging = false;
                    if (isZoomed) {
                        diagramContainer.style.cursor = 'grab';
                    }
                }
                
                // Mouse events for panning
                diagramContainer.addEventListener('mousedown', startDrag);
                document.addEventListener('mousemove', drag);
                document.addEventListener('mouseup', stopDrag);
                
                // Touch events for mobile
                let touchStartX = 0;
                let touchStartY = 0;
                
                diagramContainer.addEventListener('touchstart', function(e) {
                    if (!isZoomed) return;
                    touchStartX = e.touches[0].clientX;
                    touchStartY = e.touches[0].clientY;
                }, { passive: true });
                
                diagramContainer.addEventListener('touchmove', function(e) {
                    if (!isZoomed) return;
                    e.preventDefault();
                    const touchX = e.touches[0].clientX;
                    const touchY = e.touches[0].clientY;
                    const diffX = touchStartX - touchX;
                    const diffY = touchStartY - touchY;
                    diagramContainer.scrollLeft += diffX * 2;
                    diagramContainer.scrollTop += diffY * 2;
                    touchStartX = touchX;
                    touchStartY = touchY;
                }, { passive: false });
                
                // Zoom functions
                function zoomIn() {
                    if (!isZoomed) {
                        openZoom();
                    } else {
                        currentScale = Math.min(currentScale + 0.3, 3);
                        applyZoom();
                    }
                }
                
                function zoomOut() {
                    if (isZoomed) {
                        currentScale = Math.max(currentScale - 0.3, 0.8);
                        if (currentScale <= 0.8) {
                            closeZoom();
                        } else {
                            applyZoom();
                        }
                    }
                }
                
                function resetZoom() {
                    if (isZoomed) {
                        currentScale = 1.5;
                        applyZoom();
                        // Center the diagram
                        diagramContainer.scrollTo({
                            left: (diagramContainer.scrollWidth - diagramContainer.clientWidth) / 2,
                            top: (diagramContainer.scrollHeight - diagramContainer.clientHeight) / 2,
                            behavior: 'smooth'
                        });
                    }
                }
                
                function applyZoom() {
                    diagram.style.transform = `scale(${currentScale})`;
                    diagram.style.transformOrigin = 'center center';
                }
                
                function openZoom() {
                    isZoomed = true;
                    currentScale = 1.5;
                    wrapper.classList.add('zoomed');
                    diagramContainer.style.cursor = 'grab';
                    zoomIndicator.innerHTML = '🔍 Drag to pan | Arrow keys to navigate | ESC to close';
                    zoomIndicator.style.opacity = '1';
                    zoomIndicator.style.position = 'fixed';
                    zoomIndicator.style.top = '20px';
                    zoomIndicator.style.right = '20px';
                    navControls.style.display = 'flex';
                    
                    applyZoom();
                    
                    // Center the diagram
                    setTimeout(function() {
                        diagramContainer.scrollTo({
                            left: (diagramContainer.scrollWidth - diagramContainer.clientWidth) / 2,
                            top: (diagramContainer.scrollHeight - diagramContainer.clientHeight) / 2,
                            behavior: 'auto'
                        });
                    }, 100);
                    
                    // Prevent body scroll when zoomed
                    document.body.style.overflow = 'hidden';
                }
                
                function closeZoom() {
                    isZoomed = false;
                    currentScale = 1.5;
                    wrapper.classList.remove('zoomed');
                    diagram.style.transform = '';
                    diagram.style.transformOrigin = '';
                    diagramContainer.style.cursor = '';
                    zoomIndicator.innerHTML = '🔍 Double-click to zoom';
                    zoomIndicator.style.opacity = '0';
                    zoomIndicator.style.position = 'absolute';
                    zoomIndicator.style.top = '10px';
                    zoomIndicator.style.right = '10px';
                    navControls.style.display = 'none';
                    
                    // Restore body scroll
                    document.body.style.overflow = '';
                }
                
                // Double-click zoom functionality
                wrapper.addEventListener('dblclick', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    if (!isZoomed) {
                        openZoom();
                    } else {
                        closeZoom();
                    }
                });
                
                // Control buttons
                navControls.addEventListener('click', function(e) {
                    // Prevent double-click from propagating to wrapper
                    e.stopPropagation();
                    
                    const button = e.target.closest('.zoom-control-btn');
                    if (!button) return;
                    
                    const action = button.getAttribute('data-action');
                    if (!action) return;
                    
                    e.preventDefault();
                    
                    switch(action) {
                        case 'zoom-in':
                            zoomIn();
                            break;
                        case 'zoom-out':
                            zoomOut();
                            break;
                        case 'reset':
                            resetZoom();
                            break;
                        case 'close':
                            closeZoom();
                            break;
                    }
                });
                
                // Prevent double-click on buttons from closing zoom
                navControls.addEventListener('dblclick', function(e) {
                    e.stopPropagation();
                    e.preventDefault();
                });
                
                // Keyboard navigation
                function handleKeydown(e) {
                    if (!isZoomed) return;
                    
                    const scrollAmount = 50;
                    
                    switch(e.key) {
                        case 'Escape':
                            e.preventDefault();
                            closeZoom();
                            break;
                        case 'ArrowLeft':
                            e.preventDefault();
                            diagramContainer.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
                            break;
                        case 'ArrowRight':
                            e.preventDefault();
                            diagramContainer.scrollBy({ left: scrollAmount, behavior: 'smooth' });
                            break;
                        case 'ArrowUp':
                            e.preventDefault();
                            diagramContainer.scrollBy({ top: -scrollAmount, behavior: 'smooth' });
                            break;
                        case 'ArrowDown':
                            e.preventDefault();
                            diagramContainer.scrollBy({ top: scrollAmount, behavior: 'smooth' });
                            break;
                        case '+':
                        case '=':
                            e.preventDefault();
                            zoomIn();
                            break;
                        case '-':
                        case '_':
                            e.preventDefault();
                            zoomOut();
                            break;
                        case '0':
                            e.preventDefault();
                            resetZoom();
                            break;
                    }
                }
                
                document.addEventListener('keydown', handleKeydown);
                
                // Close on click outside when zoomed
                wrapper.addEventListener('click', function(e) {
                    if (isZoomed && e.target === wrapper) {
                        closeZoom();
                    }
                });
                
                // Prevent double-click from selecting text
                wrapper.addEventListener('selectstart', function(e) {
                    if (isZoomed) {
                        e.preventDefault();
                    }
                });
            });
        }, 500);
        
        // Stop checking after 10 seconds
        setTimeout(function() {
            clearInterval(checkMermaid);
        }, 10000);
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMermaidZoom);
    } else {
        initMermaidZoom();
    }
    
    // Re-initialize after Mermaid renders (for dynamic content)
    if (typeof window.mermaid !== 'undefined') {
        const originalRun = window.mermaid.run;
        window.mermaid.run = function() {
            const result = originalRun.apply(this, arguments);
            setTimeout(initMermaidZoom, 100);
            return result;
        };
    }
})();

