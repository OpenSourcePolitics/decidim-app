document.addEventListener("DOMContentLoaded", function () {
  const leftSection = document.querySelector('.menu-bar__secondary-dropdown__left');
  if (leftSection) leftSection.remove();

  const dropdown = document.querySelector('.menu-bar__secondary-dropdown');
  if (dropdown) {
    dropdown.style.width = 'auto';
    dropdown.style.minWidth = '300px';
    const nav = dropdown.querySelector('nav');
    if (nav) nav.style.width = '100%';
  }
});

document.addEventListener("DOMContentLoaded", function () {
  if (window.innerWidth <= 768) return;

  const menuBar = document.getElementById("menu-bar-container");
  if (!menuBar) return;

  const placeholder = document.createElement("div");
  menuBar.parentNode.insertBefore(placeholder, menuBar);
  placeholder.style.height = menuBar.offsetHeight + "px";
  placeholder.style.display = "none";

  const menuOriginalTop = menuBar.getBoundingClientRect().top + window.scrollY;

  window.addEventListener("scroll", function () {
    const fixed = window.scrollY >= menuOriginalTop;

    menuBar.style.position = fixed ? "fixed" : "";
    menuBar.style.top = fixed ? "0" : "";
    menuBar.style.left = fixed ? "0" : "";
    menuBar.style.right = fixed ? "0" : "";
    menuBar.style.zIndex = fixed ? "1000" : "";
    menuBar.style.background = fixed ? "#fff" : "";
    menuBar.style.boxShadow = fixed ? "0 2px 8px rgba(0,0,0,0.1)" : "";

    if (fixed) {
      placeholder.style.display = "block";
    } else {
      requestAnimationFrame(() => placeholder.style.display = "none");
    }
  }, { passive: true });
});

// --- Fixes regarding the surveys --- //
document.addEventListener("DOMContentLoaded", () => {
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-toggle-toggle-value]");
    if (!btn) return;

    setTimeout(() => {
      const target =
        document.querySelector(".answer-questionnaire") ||
        document.querySelector(".questionnaire") ||
        document.querySelector("main");

      if (target) {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      } else {
        window.scrollTo({ top: 0, behavior: "smooth" });
      }
    }, 50);
  });
});

document.addEventListener("DOMContentLoaded", () => {
  const announcements = document.querySelectorAll(".flash[data-announcement]");
  if (!announcements.length) return;

  document.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-toggle-toggle-value]");
    if (!btn) return;

    const goingForward = btn.dataset.toggleToggleValue.startsWith("step-1");
    announcements.forEach(a => a.classList.toggle("is-hidden", goingForward));
  });
});

// ------ //