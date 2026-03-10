// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

// Import centralized global adjustments for Decidim
import "src/decidim/global_adjustments"

// add an error message if loading image with special character in rich-text editor
document.addEventListener("DOMContentLoaded", function(event) {
    setTimeout(function (){
        const container = document.querySelector('div.proposal_custom_field div.editor-container[type=richtext]') || document.querySelector('div.editor div.editor-container');
        const editorToolbarImage = document.querySelector('div.editor-toolbar button[data-editor-type="image"]');

        if(container && editorToolbarImage){
            // add paragraph before container
            const paragraph = document.createElement('p');
            paragraph.style.fontSize = "14px";
            paragraph.style.textAlign = "justify";
            paragraph.style.color = "rgb(62 76 92 / var(--tw-text-opacity, 1))";

            const lang = document.querySelector('html').lang
            let text;
            switch (lang) {
                case "fr": text = "Si vous ajoutez une image, le nom du fichier ne doit pas contenir de caractères spéciaux (espace, accent, parenthèse...).";
                    break;
                case "de": text = "Wenn Sie ein Bild hinzufügen, darf der Dateiname keine Sonderzeichen (Leerzeichen, Akzente, Klammern...) enthalten.";
                    break;
                case "nl": text = "Als je een afbeelding toevoegt, mag de bestandsnaam geen speciale tekens bevatten (spaties, accenten, haakjes...).";
                    break;
                default:   text = "If you upload an image, the name of the file must not contain special characters (space, accent, parenthesis...).";
            }
            paragraph.textContent = text;
            container.before(paragraph);

            // add guidance to modal
            const modalText = document.querySelector('div.upload-modal .upload-modal__text ul');
            const li = document.createElement('li');
            let liText;
            switch (lang) {
                case "fr": liText = "Pas de caractères spéciaux dans le nom de l'image.";
                    break;
                case "de": liText = "Keine Sonderzeichen im Bildnamen.";
                    break;
                case "nl": liText = "Geen speciale tekens in de afbeeldingsnaam.";
                    break;
                default:   liText = "No special characters in image name.";
            }
            li.textContent = liText;
            modalText.appendChild(li);

            function showEditorError(message) {
                // Remove previous existing error if exists
                const existingError = document.querySelector("div.custom-editor-upload-error");
                if (existingError) {
                    existingError.remove();
                }

                const errorDiv = document.createElement("div");
                errorDiv.classList.add("custom-editor-upload-error", "form-error", "is-visible");
                errorDiv.textContent = message;

                let div = document.querySelector('div.proposal_custom_field div.editor-container[type=richtext]') || document.querySelector('div.editor div.editor-container');
                // Insert error after container
                div.after(errorDiv);
            }

            const originalFetch = window.fetch;

            window.fetch = async function (...args) {
                const response = await originalFetch.apply(this, args);
                // target only calls to editor_images endpoint
                const url = typeof args[0] === "string" ? args[0] : args[0]?.url;
                if (url && url.includes("editor_images")) {
                    // if EditorForm is invalid, there is a 422
                    if (response.status === 422) {
                        // Clone response to read it without consuming it
                        const cloned = response.clone();
                        cloned.json().then((data) => {
                            showEditorError(data.message);
                        });
                    } else if (response.ok) {
                        // Remove previous existing error if upload is a success
                        const existingError = document.querySelector(".custom-editor-upload-error");
                        if (existingError) {
                            existingError.remove();
                        }
                    }
                }
                return response;
            };
        }
    }, 500);
});
