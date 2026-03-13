// handle the iframe settings in proposals component
document.addEventListener("DOMContentLoaded", function(){
    const iframeCheck = document.querySelector('input#component_settings_enable_iframe')
    const urlDiv = document.querySelector("div.iframe_url_container")
    const inputUrl = document.querySelector("input[name='component[settings][iframe_url]']")
    const iframeLabelCheck = document.querySelector("label[for='component_settings_enable_iframe']")

    if(iframeCheck){
        let help_text = document.createElement('p')
        help_text.style.fontSize = '14px'
        help_text.style.fontWeight = '400'
        help_text.style.color = '#3e4c5c'
        help_text.textContent = 'Enables an iframe that will be displayed on the proposals show page'
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
            } else {
                urlDiv.style.display = "none";
            }
        })
    }
    // check validity of urls when input looses focus
    inputUrl.addEventListener("blur", checkUrl)
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
            // create content
            const newContent = document.createTextNode("There is an invalid url");
            // add content to p
            elem.appendChild(newContent);
            // add style and class to p
            elem.style.color = "red";
            elem.classList.add('url_input_error');
            // insert p after input
            inputUrl.after(elem);
        } else if(errors.length === 0 && inputUrl.parentNode.lastChild !== inputUrl){
            const elem = document.querySelector('p.url_input_error');
            inputUrl.parentNode.removeChild(elem);
        }
    }
})
