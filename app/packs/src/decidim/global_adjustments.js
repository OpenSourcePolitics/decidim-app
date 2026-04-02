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
// on mobile portrait, when user is not signin, change the display of div.main-bar__menu-mobile
// so that logo and signin link don't overlap
document.addEventListener("DOMContentLoaded", function () {
  const signIn = document.querySelector('.main-bar a[href^="/users/sign_in"]')
  const menuBarMobile = document.querySelector('header .main-bar__menu-mobile');
  const menuBarMobileLink = document.querySelector('header .main-bar__links-mobile__login')

  if (window.innerWidth <= 600 && signIn && screen.orientation.type === "portrait-primary"){
    menuBarMobile.style.flexDirection = "column-reverse";
    if (menuBarMobileLink) menuBarMobileLink.style.marginBottom = "1rem";
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
