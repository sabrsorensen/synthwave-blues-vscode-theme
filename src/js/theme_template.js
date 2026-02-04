(function () {
  //====================================
  // Theme replacement CSS (Glow styles)
  //====================================
  const tokenReplacements = {
    /* replace neon red - entities, classes, language vars, support */
    'd64a53': "color: #ff3341; text-shadow: 0 0 2px #ff4a00, 0 0 3px #fc1f2c[NEON_BRIGHTNESS], 0 0 5px #fc1f2c[NEON_BRIGHTNESS];",
    /* replace yellow - keywords, storage types, operators */
    'fede5d': "color: #f9faaa; text-shadow: 0 0 2px #f9faaa, 0 0 3px #f39f05[NEON_BRIGHTNESS], 0 0 5px #f39f05[NEON_BRIGHTNESS], 0 0 8px #f39f05[NEON_BRIGHTNESS];",
    /* replace green - HTML tags, CSS props, exports, template expressions */
    '72f1b8': "color: #72f1b8; text-shadow: 0 0 2px #100c0f, 0 0 10px #257c55[NEON_BRIGHTNESS], 0 0 35px #212724[NEON_BRIGHTNESS];",
    /* replace neon blue - functions, escape chars, tag brackets, CSS #id */
    '36f9f6': "color: #3688f6; text-shadow: 0 0 2px #001716, 0 0 3px #36bbf9[NEON_BRIGHTNESS], 0 0 5px #36bbf9[NEON_BRIGHTNESS], 0 0 8px #36bbf9[NEON_BRIGHTNESS];",
    /* replace light blue - variables, object keys, headings */
    '7ed0ff': "color: #15f4ee; text-shadow: 0 0 2px #001716, 0 0 3px #03edf9[NEON_BRIGHTNESS], 0 0 5px #03edf9[NEON_BRIGHTNESS], 0 0 8px #03edf9[NEON_BRIGHTNESS];",
    /* replace coral - constants, numbers, regex, link descriptions */
    'f97e72': "color: #f97e72; text-shadow: 0 0 2px #100c0f, 0 0 5px #f74a3a[NEON_BRIGHTNESS], 0 0 8px #f97e72[NEON_BRIGHTNESS];",
    /* replace turquoise/cyan - strings, quoted strings */
    '4ce9d9': "color: #4ce9d9; text-shadow: 0 0 2px #00fff7, 0 0 5px #03edf9[NEON_BRIGHTNESS], 0 0 8px #4ce9d9[NEON_BRIGHTNESS];",
    /* replace cyan - JS/Dart/Go numerics, markdown emphasis */
    '2ee2fa': "color: #2ee2fa; text-shadow: 0 0 2px #001716, 0 0 5px #0bc5e0[NEON_BRIGHTNESS], 0 0 8px #2ee2fa[NEON_BRIGHTNESS];",
    /* replace gold - tag attributes */
    'ffd940': "color: #ffd940; text-shadow: 0 0 2px #100c0f, 0 0 5px #e6b800[NEON_BRIGHTNESS], 0 0 8px #ffd940[NEON_BRIGHTNESS];"
  };

  //=============================
  // Helper functions
  //=============================

  /**
   * @summary Check if the style element exists and that it has synthwave '84 color content
   * @param {HTMLElement} tokensEl the style tag
   * @param {object} replacements key/value pairs of colour hex and the glow styles to replace them with
   * @returns {boolean}
   */
  const themeStylesExist = (tokensEl, replacements) => {
    return tokensEl.innerText !== '' &&
      Object.keys(replacements).every(color => {
        return tokensEl.innerText.toLowerCase().includes(`#${color}`);
      });
  };

  /**
   * @summary Search and replace colours within a CSS definition
   * @param {string} styles the text content of the style tag
   * @param {object} replacements key/value pairs of colour hex and the glow styles to replace them with
   * @returns
   */
  const replaceTokens = (styles, replacements) => Object.keys(replacements).reduce((acc, color) => {
    const re = new RegExp(`color: #${color};`, 'gi');
    return acc.replace(re, replacements[color]);
  }, styles);

  /**
   * @summary Checks if a theme is applied, and that the theme belongs to the Synthwave 84 family
   * @returns {boolean}
   */
  const usingSynthwave = () => {
    const appliedTheme = document.querySelector('[class*="theme-json"]');
    const synthWaveTheme = document.querySelector('[class*="sabrsorensen-synthwave-blues-themes"]');
    return appliedTheme && synthWaveTheme;
  }

  /**
   * @summary Checks if the theme is synthwave, and that the styles exist, ready for replacement
   * @param {HTMLElement} tokensEl the style tag
   * @param {object} replacements key/value pairs of colour hex and the glow styles to replace them with
   * @returns
   */
  const readyForReplacement = (tokensEl, tokenReplacements) => tokensEl
    ? (
      // only init if we're using a Synthwave 84 subtheme
      usingSynthwave() &&
      // does it have content ?
      themeStylesExist(tokensEl, tokenReplacements)
    )
    : false;

  /**
   * @summary Attempts to bootstrap the theme
   * @param {boolean} disableGlow
   * @param {MutationObserver} obs
   */
  const initNeonDreams = (disableGlow, obs) => {
    const tokensEl = document.querySelector('.vscode-tokens-styles');

    if (!tokensEl || !readyForReplacement(tokensEl, tokenReplacements)) {
      return;
    }

    // Add the theme styles if they don't already exist in the DOM
    if (!document.querySelector('#synthwave-84-blues-theme-styles')) {
      const initialThemeStyles = tokensEl.innerText;

      // Replace tokens with glow styles
      let updatedThemeStyles = !disableGlow
        ? replaceTokens(initialThemeStyles, tokenReplacements)
        : initialThemeStyles;

      /* append the remaining styles */
      updatedThemeStyles = `${updatedThemeStyles}[CHROME_STYLES]`;

      const newStyleTag = document.createElement('style');
      newStyleTag.setAttribute("id", "synthwave-84-blues-theme-styles");
      newStyleTag.innerText = updatedThemeStyles.replace(/(\r\n|\n|\r)/gm, '');
      document.body.appendChild(newStyleTag);

      console.log('Synthwave \'84 Blues: NEON DREAMS initialized!');
    }

    // disconnect the observer because we don't need it anymore
    if (obs) {
      obs.disconnect();
      obs = null;
    }
  };

  /**
   * @summary A MutationObserver callback that attempts to bootstrap the theme and assigns a retry attempt if it fails
   */
  const watchForBootstrap = function(mutationsList, observer) {
    for(let mutation of mutationsList) {
      if (mutation.type === 'attributes' || mutation.type === 'childList') {
        // does the style div exist yet?
        const tokensEl = document.querySelector('.vscode-tokens-styles');
        if (readyForReplacement(tokensEl, tokenReplacements)) {
          // If everything we need is ready, then initialise
          initNeonDreams([DISABLE_GLOW], observer);
        } else {
          if (tokensEl) {
            // sometimes VS code takes a while to init the styles content, so if there stop this observer and add an observer for that
            observer.disconnect();
            observer.observe(tokensEl, { childList: true });
          }
        }
      }
    }
  };

  //=============================
  // Start bootstrapping!
  //=============================
  // Grab body node
  const bodyNode = document.querySelector('body');
  // Use a mutation observer to check when we can bootstrap the theme
  const observer = new MutationObserver(watchForBootstrap);
  /* watch for both attribute and childList changes because, depending on
  the VS code version, the mutations might happen on the body, or they might
  happen on a nested div */
  observer.observe(bodyNode, { attributes: true, childList: true });
})();
