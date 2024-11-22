$(document).ready(() => {
  let activeBlocks = Array.prototype.slice.call(document.querySelectorAll(".js-list-scopes li"));
  const defaultOrder = activeBlocks.map(block => block.dataset.scopeId);

  document.addEventListener("dragend", () => {
    activeBlocks = Array.prototype.slice.call(document.querySelectorAll(".js-list-scopes li"));
    let activeBlocksManifestName = activeBlocks.map(block => block.dataset.scopeId);
    let sortUrl = document.querySelector(".js-list-scopes").dataset.sortUrl;

    if (JSON.stringify(activeBlocksManifestName) === JSON.stringify(defaultOrder)) { return; }

    $.ajax({
      method: "PUT",
      url: sortUrl,
      contentType: "application/json",
      data: JSON.stringify({ manifests: activeBlocksManifestName })
    });
  })
});