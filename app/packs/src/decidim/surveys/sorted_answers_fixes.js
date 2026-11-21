$(() => {
  const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;

  if (!isTouchDevice) return;

  // Only sorting answers are draggable; other answer types share .js-collection-input
  const SORTABLE_ITEM = '.js-sortable-check-box-collection .js-collection-input';

  const preventScroll = (e) => {
    e.preventDefault();
  };

  const scrollToTopIfNeeded = () => {
    if (window.pageY > window.innerHeight * 0.3) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  // Block scrolling only while a sorting item is being dragged, so the page keeps native scrolling otherwise
  const handleInteractionStart = (e) => {
    if (e.target.closest(SORTABLE_ITEM)) {
      document.addEventListener('touchmove', preventScroll, { passive: false });
      if (e.type === 'dragstart') scrollToTopIfNeeded();
    }
  };

  const handleInteractionEnd = () => {
    document.removeEventListener('touchmove', preventScroll, { passive: false });
  };

  document.addEventListener('dragstart', handleInteractionStart);
  document.addEventListener('dragend', handleInteractionEnd);
  document.addEventListener('touchstart', handleInteractionStart, { passive: true });
  document.addEventListener('touchend', handleInteractionEnd);
  document.addEventListener('touchcancel', handleInteractionEnd);
});
