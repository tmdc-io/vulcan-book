// Favicon switcher for light/dark mode
(function() {
  'use strict';

  // Get the favicon link element
  function getFaviconLink() {
    let link = document.querySelector("link[rel~='icon']");
    if (!link) {
      link = document.createElement('link');
      link.rel = 'icon';
      document.getElementsByTagName('head')[0].appendChild(link);
    }
    return link;
  }

  // Set favicon based on color scheme
  function setFavicon() {
    const link = getFaviconLink();
    const isDarkMode = document.documentElement.getAttribute('data-md-color-scheme') === 'slate' ||
                       window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    // Get base path (handles subdirectory deployments)
    const basePath = document.querySelector('base')?.getAttribute('href') || '';
    const faviconPath = isDarkMode 
      ? basePath + 'assets/images/D_logo_light-32px.png'
      : basePath + 'assets/images/D_logo_dark-32px.png';
    
    link.href = faviconPath;
  }

  // Set initial favicon
  setFavicon();

  // Listen for color scheme changes
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'data-md-color-scheme') {
        setFavicon();
      }
    });
  });

  // Observe the html element for color scheme changes
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-md-color-scheme']
  });

  // Also listen for system preference changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', setFavicon);
})();
