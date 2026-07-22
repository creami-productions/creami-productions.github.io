// Handles theme selection and header navigation actions.
window.addEventListener("DOMContentLoaded", () => {
  const storageKey = "theme-preference";
  const root = document.documentElement;
  const logo = document.querySelector(".company-logo");
  const themeButtons = document.querySelectorAll(".theme-option");
  const systemPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const navButtons = document.querySelectorAll(".nav-button");

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
