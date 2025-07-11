$(() => {
  const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;

  if (!isTouchDevice) return;

  let isDragging = false;

  const preventScroll = (e) => {
    if (isDragging) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  };

  const scrollToTopIfNeeded = () => {
    if (window.pageY > window.innerHeight * 0.3) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const handleInteractionStart = (e) => {
    if (e.target.closest('.js-collection-input')) {
      isDragging = true;
      if (e.type === 'dragstart') scrollToTopIfNeeded();
    }
  };

  const handleInteractionEnd = () => {
    isDragging = false;
  };

  document.addEventListener('dragstart', handleInteractionStart);
  document.addEventListener('dragend', handleInteractionEnd);
  document.addEventListener('touchstart', handleInteractionStart);
  document.addEventListener('touchend', handleInteractionEnd);
  document.addEventListener('touchmove', preventScroll, { passive: false });
  document.addEventListener('scroll', preventScroll, { passive: false });
  document.addEventListener('wheel', preventScroll, { passive: false });
});