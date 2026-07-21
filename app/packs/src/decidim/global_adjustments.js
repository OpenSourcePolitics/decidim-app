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
  const MOBILE_BREAKPOINT = 768;
  const menuBar = document.getElementById("menu-bar-container");
  if (!menuBar) return;

  const placeholder = document.createElement("div");
  menuBar.parentNode.insertBefore(placeholder, menuBar);
  placeholder.style.height = menuBar.offsetHeight + "px";
  placeholder.style.display = "none";

  let isFixed = false;
  let scrollListenerActive = false;

  function unfix() {
    if (!isFixed) return;
    isFixed = false;
    menuBar.removeAttribute("style");
    placeholder.style.display = "none";
  }

  function fix() {
    if (isFixed) return;
    isFixed = true;
    placeholder.style.display = "block";
    menuBar.style.position = "fixed";
    menuBar.style.top = "0";
    menuBar.style.left = "0";
    menuBar.style.right = "0";
    menuBar.style.zIndex = "1000";
    menuBar.style.boxShadow = "0 2px 8px rgba(0,0,0,0.1)";
  }

  function onScroll() {
    if (window.innerWidth <= MOBILE_BREAKPOINT) {
      unfix();
      return;
    }
    if (isFixed) {
      if (placeholder.getBoundingClientRect().top > 0) unfix();
    } else {
      if (menuBar.getBoundingClientRect().top <= 0) fix();
    }
  }

  window.addEventListener("scroll", onScroll, { passive: true });

  window.addEventListener("resize", function () {
    if (window.innerWidth <= MOBILE_BREAKPOINT) {
      unfix();
    } else {
      onScroll();
    }
  }, { passive: true });
});

// on mobile portrait, when user is not signin, change the display of div.main-bar__menu-mobile
// so that logo and signin link don't overlap
document.addEventListener("DOMContentLoaded", function () {
  const signIn = document.querySelector('.main-bar a[href^="/users/sign_in"]')
  const menuBarMobile = document.querySelector('header .main-bar__menu-mobile');
  const menuBarMobileLink = document.querySelector('header .main-bar__links-mobile__login');
  const button = document.querySelector('#main-dropdown-summary-mobile');

  if (window.innerWidth <= 600 && signIn && screen.orientation.type === "portrait-primary"){
    menuBarMobile.style.flexDirection = "column-reverse";
    if (menuBarMobileLink) menuBarMobileLink.style.marginBottom = "1rem";

    // hide or show signin when the dropdown-menu is clicked
    button.addEventListener('click', () => {
      if (menuBarMobile.style.flexDirection == "column-reverse") {
        menuBarMobile.style.flexDirection = "row-reverse";
      } else {
        menuBarMobile.style.flexDirection = "column-reverse";
      }
    })
  }
  screen.orientation.addEventListener("change", () => {
    if (screen.orientation.type === "landscape-primary"){
      menuBarMobile.style.flexDirection = "row-reverse";
      if (menuBarMobileLink) menuBarMobileLink.style.marginBottom = "0rem";
    }else {
      menuBarMobile.style.flexDirection = "column-reverse";
      if (menuBarMobileLink) menuBarMobileLink.style.marginBottom = "1rem";
    }
  });
});

// --- Fixes regarding the surveys --- //

document.addEventListener("DOMContentLoaded", () => {
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-survey-buttons]");
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
    const btn = e.target.closest("button[data-survey-buttons]");
    if (!btn) return;

    const toggle = btn.dataset.toggle || "";
    const goingForward = !toggle.startsWith("step-0");
    announcements.forEach(a => a.classList.toggle("is-hidden", goingForward));
  });
});

// ------ //
