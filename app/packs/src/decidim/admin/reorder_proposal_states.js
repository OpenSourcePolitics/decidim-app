$(document).ready(() => {
    const proposalStatesList = document.querySelector(".js-list-proposal-states");

    if (!proposalStatesList) {
        return;
    }

    let activeBlocks = Array.prototype.slice.call(document.querySelectorAll(".js-list-proposal-states li"));
    const defaultOrder = activeBlocks.map(block => block.dataset.proposalStateId);

    document.addEventListener("dragend", () => {
        if (!document.querySelector(".js-list-proposal-states")) {
            return;
        }

        activeBlocks = Array.prototype.slice.call(document.querySelectorAll(".js-list-proposal-states li"));
        let activeBlocksManifestName = activeBlocks.map(block => block.dataset.proposalStateId);
        let sortUrl = document.querySelector(".js-list-proposal-states").dataset.sortUrl;

        if (JSON.stringify(activeBlocksManifestName) === JSON.stringify(defaultOrder)) { return; }

        $.ajax({
            method: "PUT",
            url: sortUrl,
            contentType: "application/json",
            data: JSON.stringify({ manifests: activeBlocksManifestName })
        });
    });
});
