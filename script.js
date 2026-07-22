// Handles theme selection and header navigation actions.
window.addEventListener("DOMContentLoaded", () => {
  const storageKey = "theme-preference";
  const languageStorageKey = "language-preference";
  const root = document.documentElement;
  const logo = document.querySelector(".company-logo");
  const themeButtons = document.querySelectorAll(".theme-option");
  const languageButtons = document.querySelectorAll(".language-option");
  const translatableNodes = document.querySelectorAll("[data-i18n]");
  const systemPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const navButtons = document.querySelectorAll(".nav-button");
  const translations = {
    en: {
      "nav.studio": "Studio",
      "nav.projects": "Projects",
      "nav.contact": "Contact Us",
      "about.kicker": "Indie Studio",
      "about.title": "About Creami Productions",
      "about.description": "We build compact action experiences with strong visual identity and tight controls.",
      "projects.title": "Projects",
      "projects.kicker": "Project",
      "projects.genre": "Rougelike RPG",
      "theme.auto": "Auto",
      "theme.light": "Light",
      "theme.dark": "Dark",
    },
    de: {
      "nav.studio": "Studio",
      "nav.projects": "Projekte",
      "nav.contact": "Kontakt",
      "about.kicker": "Indie-Studio",
      "about.title": "Über Creami Productions",
      "about.description": "Wir entwickeln kompakte Action-Erlebnisse mit starker visueller Identität und präziser Steuerung.",
      "projects.title": "Projekte",
      "projects.kicker": "Projekt",
      "projects.genre": "Rougelike-RPG",
      "theme.auto": "Auto",
      "theme.light": "Hell",
      "theme.dark": "Dunkel",
    },
  };

  function getSystemLanguage() {
    const systemLanguage = (navigator.language || navigator.userLanguage || "en").toLowerCase();
    return systemLanguage.startsWith("de") ? "de" : "en";
  }

  function getInitialLanguage() {
    const stored = localStorage.getItem(languageStorageKey);
    if (stored === "en" || stored === "de") {
      return stored;
    }

    return getSystemLanguage();
  }

  function updateLanguageButtons(activeLanguage) {
    languageButtons.forEach((button) => {
      const isActive = button.dataset.languageValue === activeLanguage;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", isActive ? "true" : "false");
    });
  }

  function applyLanguage(language) {
    const activeLanguage = language === "de" ? "de" : "en";
    const dictionary = translations[activeLanguage];

    translatableNodes.forEach((node) => {
      const key = node.dataset.i18n;
      if (!key || !dictionary[key]) {
        return;
      }

      node.textContent = dictionary[key];
    });

    root.setAttribute("lang", activeLanguage);
    updateLanguageButtons(activeLanguage);
  }

  function getResolvedTheme(preference) {
    if (preference === "auto") {
      return systemPreference.matches ? "dark" : "light";
    }

    return preference;
  }

  function setLogoForTheme(theme) {
    if (!logo) {
      return;
    }

    const lightLogo = logo.dataset.logoLight;
    const darkLogo = logo.dataset.logoDark;

    if (!lightLogo || !darkLogo) {
      return;
    }

    logo.src = theme === "dark" ? darkLogo : lightLogo;
  }

  function updateThemeButtons(activePreference) {
    themeButtons.forEach((button) => {
      const isActive = button.dataset.themeValue === activePreference;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", isActive ? "true" : "false");
    });
  }

  function applyTheme(preference) {
    if (preference === "auto") {
      root.removeAttribute("data-theme");
    } else {
      root.setAttribute("data-theme", preference);
    }

    const resolvedTheme = getResolvedTheme(preference);
    setLogoForTheme(resolvedTheme);
    updateThemeButtons(preference);
  }

  function getInitialPreference() {
    const stored = localStorage.getItem(storageKey);
    return stored === "light" || stored === "dark" || stored === "auto"
      ? stored
      : "auto";
  }

  let currentPreference = getInitialPreference();
  let currentLanguage = getInitialLanguage();

  applyLanguage(currentLanguage);
  applyTheme(currentPreference);

  themeButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const nextPreference = button.dataset.themeValue;

      if (nextPreference !== "auto" && nextPreference !== "light" && nextPreference !== "dark") {
        return;
      }

      currentPreference = nextPreference;
      localStorage.setItem(storageKey, currentPreference);
      applyTheme(currentPreference);
    });
  });

  languageButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const nextLanguage = button.dataset.languageValue;

      if (nextLanguage !== "en" && nextLanguage !== "de") {
        return;
      }

      currentLanguage = nextLanguage;
      localStorage.setItem(languageStorageKey, currentLanguage);
      applyLanguage(currentLanguage);
    });
  });

  const handleSystemPreferenceChange = () => {
    if (currentPreference === "auto") {
      applyTheme("auto");
    }
  };

  if (typeof systemPreference.addEventListener === "function") {
    systemPreference.addEventListener("change", handleSystemPreferenceChange);
  } else if (typeof systemPreference.addListener === "function") {
    systemPreference.addListener(handleSystemPreferenceChange);
  }

  navButtons.forEach((button) => {
    button.addEventListener("click", (event) => {
      const isContactButton = button.dataset.contact === "true";
      const targetId = button.dataset.scrollTarget;

      if (isContactButton) {
        event.preventDefault();
        window.location.href = "mailto:hello@creamiproductions.com";
        return;
      }

      if (targetId) {
        event.preventDefault();
        const targetElement = document.getElementById(targetId);

        if (targetElement) {
          targetElement.scrollIntoView({ behavior: "smooth", block: "start" });
        }

        return;
      }

      event.preventDefault();
    });
  });
});
