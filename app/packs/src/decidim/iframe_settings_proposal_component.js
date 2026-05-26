// handle the iframe settings in proposals component
document.addEventListener("DOMContentLoaded", function(){
    const iframeCheck = document.querySelector('input#component_settings_enable_iframe')
    const urlDiv = document.querySelector("div.iframe_url_container")
    const inputUrl = document.querySelector("input[name='component[settings][iframe_url]']")
    const iframeLabelCheck = document.querySelector("label[for='component_settings_enable_iframe']")
    const submitButton = document.querySelector("form button[type=submit]")
    const lang = document.querySelector('html').getAttribute('lang')

    if(iframeCheck){
        let help_text = document.createElement('p')
        help_text.style.fontSize = '14px'
        help_text.style.fontWeight = '400'
        help_text.style.color = '#3e4c5c'

        let text;
        switch (lang) {
            case "fr":
                text = "Autoriser un iframe qui sera affiché dans la vue show d'une proposition"
                break;
            case "de":
                text = "Aktiviert einen iFrame, der auf der Übersichtsseite eines Angebots angezeigt wird"
                break;
            case "nl":
                text = "Hiermee wordt een iframe ingeschakeld dat wordt weergegeven op de presentatiepagina van een voorstel"
                break;
            default:
                text = "Enables an iframe that will be displayed on the proposal show page"
                break;
        }
        help_text.textContent = text;
        iframeLabelCheck.appendChild(help_text)
        inputUrl.setAttribute("placeholder", "https://api.example.org")

        if(iframeCheck.checked){
            urlDiv.style.display = "block";
        } else {
            urlDiv.style.display = "none";
        }
        iframeCheck.addEventListener('change', function(){
            if (this.checked) {
                urlDiv.style.display = "block";
                inputUrl.addEventListener("blur", checkUrl)
            } else {
                urlDiv.style.display = "none";
                // allow to submit
                submitButton.removeAttribute("disabled");
                // remove error p if present
                if (document.querySelector('p.url_input_error')){
                    inputUrl.parentNode.removeChild(document.querySelector('p.url_input_error'));
                }
            }
        })
    }
    if(inputUrl){
        // check validity of urls when input looses focus
        inputUrl.addEventListener("keyup", checkUrl)
    }
    function checkUrl(event){
        const values = event.target.value;
        const errors = [];
        values.split(",").forEach(function(value){
            try {
                // if value is not valid, it will throw a TypeError
                const url = new URL(value);
            } catch(error){
                errors.push(error);
            }
        })
        if(errors.length !== 0 && inputUrl.parentNode.lastChild === inputUrl){
            // create p
            const elem = document.createElement('p');
            // create content depending on lang
            let errorText;
            switch (lang) {
                case "fr":
                    errorText = "Url non valide"
                    break;
                case "de":
                    errorText = "Ungültige URL"
                    break;
                case "nl":
                    errorText = "Ongeldige URL"
                    break;
                default:
                    errorText = "Invalid url"
                    break;
            }
            const newContent = document.createTextNode(errorText);
            // add content to p
            elem.appendChild(newContent);
            // add style and class to p
            elem.style.color = "red";
            elem.classList.add('url_input_error');
            // insert p after input
            inputUrl.after(elem);
            // block the create or update
            submitButton.setAttribute("disabled", "true")
        } else if(errors.length === 0 && inputUrl.parentNode.lastChild !== inputUrl){
            const elem = document.querySelector('p.url_input_error');
            inputUrl.parentNode.removeChild(elem);
            submitButton.removeAttribute("disabled")
        }
    }
})
