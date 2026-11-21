(() => {
  "use strict";

  const REPO_OWNER = "Tiago-Pujia";
  const REPO_NAME = "LibreMIeL";
  const RELEASES_PAGE = `https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest`;
  const API_LATEST = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`;
  const API_LIST = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases?per_page=1`;

  const OS_META = {
    windows: {
      name: "Windows",
      recommendedSuffix: "-windows-x64-setup.exe",
      heroLabel: "Descargar para Windows (.exe)",
      hint: "Instalador recomendado para Windows 10 / 11 (x86_64)."
    },
    linux: {
      name: "Linux",
      recommendedSuffix: "-linux-x64.AppImage",
      heroLabel: "Descargar para Linux (AppImage)",
      hint: "También disponible en paquetes .deb (Ubuntu/Debian), .rpm (Fedora), Arch y ARM64."
    },
    android: {
      name: "Android",
      recommendedSuffix: "-android-arm64-v8a.apk",
      heroLabel: "Descargar para Android (.apk)",
      hint: "Instalador APK para celulares y tablets Android (ARM64 y Universal)."
    },
    macos: {
      name: "macOS",
      recommendedSuffix: "-macos-universal.dmg",
      heroLabel: "Descargar para macOS (.dmg)",
      hint: "Binario Universal nativo para Apple Silicon (M1–M4) e Intel."
    }
  };

  /* ========================================================================
     1. Interruptor de Tema Claro / Oscuro (dos estados + preferencia del SO)
     ======================================================================== */
  const metaScheme = document.querySelector('meta[name="color-scheme"]');
  const themeBtn = document.getElementById("theme-toggle");
  const themeText = document.getElementById("theme-toggle-text");
  const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

  function getStoredScheme() {
    try {
      const val = localStorage.getItem("color-scheme");
      return val === "light" || val === "dark" ? val : null;
    } catch {
      return null;
    }
  }

  function getSystemScheme() {
    return darkQuery.matches ? "dark" : "light";
  }

  function getRenderedScheme() {
    return getStoredScheme() ?? getSystemScheme();
  }

  function applyMetaScheme(storedValue) {
    if (metaScheme) {
      metaScheme.content = storedValue ?? "light dark";
    }
    updateThemeButtonLabel();
  }

  function updateThemeButtonLabel() {
    if (!themeBtn) return;
    const current = getRenderedScheme();
    const label =
      current === "dark" ? "Cambiar a tema claro" : "Cambiar a tema oscuro";
    themeBtn.setAttribute("aria-label", label);
    themeBtn.setAttribute("title", label);
    if (themeText) {
      themeText.textContent = label;
    }
  }

  if (themeBtn) {
    themeBtn.addEventListener("click", () => {
      const currentRendered = getRenderedScheme();
      const target = currentRendered === "dark" ? "light" : "dark";
      const system = getSystemScheme();

      try {
        if (target !== system) {
          localStorage.setItem("color-scheme", target);
          applyMetaScheme(target);
        } else {
          localStorage.removeItem("color-scheme");
          applyMetaScheme(null);
        }
      } catch {
        applyMetaScheme(target !== system ? target : null);
      }
    });
  }

  darkQuery.addEventListener("change", () => {
    updateThemeButtonLabel();
  });

  window.addEventListener("storage", (event) => {
    if (event.key === "color-scheme") {
      applyMetaScheme(getStoredScheme());
    }
  });

  updateThemeButtonLabel();

  /* ========================================================================
     2. Pestañas Accesibles del Centro de Descargas
     ======================================================================== */
  const tablist = document.querySelector(".tablist");
  const tabs = Array.from(document.querySelectorAll('[role="tab"][data-os-tab]'));
  const panels = Array.from(
    document.querySelectorAll('[role="tabpanel"][data-os-panel]')
  );

  function selectOsTab(osKey, { focusTab = false } = {}) {
    const selectedTab = tabs.find((t) => t.dataset.osTab === osKey);
    if (!selectedTab) return;

    for (const tab of tabs) {
      const isSelected = tab === selectedTab;
      tab.setAttribute("aria-selected", String(isSelected));
      tab.toggleAttribute("focusgroupstart", isSelected);
      tab.tabIndex = isSelected ? 0 : -1;
    }

    for (const panel of panels) {
      const isMatch = panel.dataset.osPanel === osKey;
      if (isMatch) {
        panel.removeAttribute("hidden");
      } else {
        panel.setAttribute("hidden", "until-found");
      }
    }

    if (focusTab) {
      selectedTab.focus();
    }

    try {
      selectedTab.scrollIntoView({
        block: "nearest",
        inline: "nearest",
        container: "nearest"
      });
    } catch {
      selectedTab.scrollIntoView({ block: "nearest", inline: "nearest" });
    }
  }

  for (const tab of tabs) {
    tab.addEventListener("click", () => {
      selectOsTab(tab.dataset.osTab, { focusTab: false });
    });

    tab.addEventListener("keydown", (event) => {
      const idx = tabs.indexOf(tab);
      let nextIdx = -1;
      if (event.key === "ArrowRight") {
        nextIdx = (idx + 1) % tabs.length;
      } else if (event.key === "ArrowLeft") {
        nextIdx = (idx - 1 + tabs.length) % tabs.length;
      } else if (event.key === "Home") {
        nextIdx = 0;
      } else if (event.key === "End") {
        nextIdx = tabs.length - 1;
      }

      if (nextIdx !== -1) {
        event.preventDefault();
        selectOsTab(tabs[nextIdx].dataset.osTab, { focusTab: true });
      }
    });
  }

  for (const panel of panels) {
    panel.addEventListener("beforematch", () => {
      selectOsTab(panel.dataset.osPanel, { focusTab: false });
    });
  }

  if (
    tablist &&
    typeof CSS !== "undefined" &&
    !CSS.supports("animation-timeline", "scroll()") &&
    "IntersectionObserver" in window
  ) {
    const first = tablist.firstElementChild;
    const last = tablist.lastElementChild;
    if (first && last) {
      const observer = new IntersectionObserver(
        (entries) => {
          for (const { target, intersectionRatio } of entries) {
            tablist.classList.toggle(
              target === first ? "more-start" : "more-end",
              intersectionRatio < 1
            );
          }
        },
        { root: tablist, threshold: 1, rootMargin: "1px" }
      );
      observer.observe(first);
      observer.observe(last);
    }
  }

  /* ========================================================================
     3. Detección de Sistema Operativo del Visitante
     ======================================================================== */
  function detectVisitorOs() {
    const uaDataPlatform = (
      navigator.userAgentData?.platform || ""
    ).toLowerCase();
    const ua = (navigator.userAgent || "").toLowerCase();

    if (uaDataPlatform.includes("android") || ua.includes("android")) {
      return "android";
    }
    if (uaDataPlatform.includes("mac") || ua.includes("macintosh") || ua.includes("mac os")) {
      return "macos";
    }
    if (uaDataPlatform.includes("linux") || ua.includes("linux")) {
      return "linux";
    }
    if (uaDataPlatform.includes("win") || ua.includes("windows")) {
      return "windows";
    }
    return null;
  }

  const detectedOs = detectVisitorOs();
  const heroBtn = document.getElementById("hero-primary-download");
  const heroLabel = document.getElementById("hero-download-label");
  const heroHint = document.getElementById("hero-os-hint");

  if (detectedOs && OS_META[detectedOs]) {
    const info = OS_META[detectedOs];
    selectOsTab(detectedOs, { focusTab: false });
    if (heroLabel) {
      heroLabel.textContent = info.heroLabel;
    }
    if (heroBtn) {
      heroBtn.dataset.assetSuffix = info.recommendedSuffix;
      heroBtn.href = `#panel-${detectedOs}`;
    }
    if (heroHint) {
      heroHint.textContent = info.hint;
    }
  }

  /* ========================================================================
     4. Sincronización Dinámica con GitHub Releases
     ======================================================================== */
  function formatBytes(bytes) {
    if (!Number.isFinite(bytes) || bytes <= 0) return "";
    const mb = bytes / (1024 * 1024);
    return `(${mb.toFixed(1)} MB)`;
  }

  async function fetchLatestRelease() {
    const response = await fetch(API_LATEST, {
      headers: { Accept: "application/vnd.github+json" }
    });
    if (response.ok) {
      return response.json();
    }
    if (response.status === 404) {
      const listResp = await fetch(API_LIST, {
        headers: { Accept: "application/vnd.github+json" }
      });
      if (listResp.ok) {
        const list = await listResp.json();
        if (Array.isArray(list) && list.length > 0) {
          return list[0];
        }
      }
    }
    return null;
  }

  function applyReleaseData(release) {
    if (!release || typeof release !== "object") return;

    const rawTag = String(release.tag_name || "").trim();
    const cleanVersion = rawTag.replace(/^v/i, "") || "0.1.0";
    const displayTag = rawTag.startsWith("v") ? rawTag : `v${cleanVersion}`;

    const versionPill = document.getElementById("header-version-pill");
    if (versionPill) {
      versionPill.textContent = displayTag;
    }

    const statusText = document.getElementById("release-status-text");
    if (statusText && release.published_at) {
      const dateStr = new Date(release.published_at).toLocaleDateString("es-AR", {
        day: "numeric",
        month: "long",
        year: "numeric"
      });
      statusText.textContent = `Última versión disponible: ${displayTag} (publicada el ${dateStr}). Todos los paquetes cuentan con verificación SHA-256.`;
    }

    const templates = document.querySelectorAll("[data-filename-template]");
    for (const codeEl of templates) {
      const tpl = codeEl.dataset.filenameTemplate;
      if (tpl) {
        codeEl.textContent = tpl.replace("{ver}", cleanVersion);
      }
    }

    const assets = Array.isArray(release.assets) ? release.assets : [];
    const assetLinks = document.querySelectorAll("a[data-asset-suffix]");

    for (const link of assetLinks) {
      const suffix = link.dataset.assetSuffix;
      if (!suffix) continue;

      const matched = assets.find(
        (a) => typeof a.name === "string" && a.name.endsWith(suffix)
      );

      if (matched && matched.browser_download_url) {
        link.href = matched.browser_download_url;
        const sizeEl = document.querySelector(`[data-size-for="${suffix}"]`);
        if (sizeEl && matched.size) {
          sizeEl.textContent = formatBytes(matched.size);
        }
      } else if (release.html_url) {
        link.href = release.html_url;
      } else {
        link.href = RELEASES_PAGE;
      }
    }
  }

  fetchLatestRelease()
    .then(applyReleaseData)
    .catch(() => {
      // Sin conexión o límite de API: se mantienen los enlaces seguros a /releases/latest
    });
})();
