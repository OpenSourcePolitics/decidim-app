// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

import $ from "jquery"
import "jquery-validation"

$(() => {
    if($(".submit_survey").length) {
        $("body").on('DOMNodeInserted', '.confirm-reveal', function () {
            $('.button[aria-label="Ok"]').on("mouseup", function () {
                $("form.answer-questionnaire").validate({
                    ignore: "thrhwrt",
                    focusInvalid: false,
                    invalidHandler: function(form, validator) {

                        $(".questionnaire-step").each(function () {
                            console.log($(this).removeClass("hide"))
                        });
                        $(".next_survey").hide();
                        $(".back_survey").hide();

                        if (!validator.numberOfInvalids())
                            return;

                        const y = validator.errorList[0].element.parentElement.getBoundingClientRect().top + window.pageYOffset - 10;

                        window.scrollTo({top: y, behavior: 'smooth'});
                    }
                });
                if ($("form.answer-questionnaire").valid()) {
                    $(".survey-form").submit();
                }
            });
        });
    }
});
