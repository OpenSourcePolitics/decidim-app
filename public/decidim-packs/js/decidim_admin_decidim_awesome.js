/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.js":
/*!****************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.js ***!
  \****************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_admin__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_admin */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_admin.js");
/* harmony import */ var jquery_ui_ui_widgets_sortable__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! jquery-ui/ui/widgets/sortable */ "./node_modules/jquery-ui/ui/widgets/sortable.js");
/* harmony import */ var jquery_ui_ui_widgets_sortable__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(jquery_ui_ui_widgets_sortable__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var entrypoints_decidim_admin_decidim_awesome_scss__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! entrypoints/decidim_admin_decidim_awesome.scss */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.scss");

 // This is needed by custom fields builder but if loader there duplicates the jQuery inclusion
// CSS



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/auto_edit.js":
/*!******************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/auto_edit.js ***!
  \******************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  var CustomFieldsBuilders = window.CustomFieldsBuilders || [];
  $("body").on("click", "a.awesome-auto-edit", function (e) {
    e.preventDefault();
    var $link = $(e.currentTarget);
    var scope = $link.data("scope");
    var $target = $("span.awesome-auto-edit[data-scope=\"".concat(scope, "\"]"));
    var $constraints = $(".constraints-editor[data-key=\"".concat(scope, "\"]"));

    if ($target.length == 0) {
      return;
    }

    var key = $target.data("key");
    var attribute = $target.data("var");
    var $hidden = $("[name=\"config[".concat(attribute, "][").concat(key, "]\"]"));
    var $multiple = $("[name=\"config[".concat(attribute, "][").concat(key, "][]\"]"));
    var $container = $(".".concat(attribute, "_container[data-key=\"").concat(key, "\"]"));
    var $delete = $(".delete-box", $container);

    var rebuildLabel = function rebuildLabel(text, withScope) {
      $target.text(text);
      $target.attr("data-key", text);
      $target.data("key", text);

      if (withScope) {
        $target.attr("data-scope", withScope);
        $target.data("scope", withScope);
        $link.attr("data-scope", withScope);
        $link.data("scope", withScope);
      }

      $link.show();
    };

    var rebuildHmtl = function rebuildHmtl(result) {
      rebuildLabel(result.key, result.scope);
      $constraints.replaceWith(result.html); // update hidden input if exists

      $hidden.attr("name", "config[".concat(attribute, "][").concat(result.key, "]"));
      $multiple.attr("name", "config[".concat(attribute, "][").concat(result.key, "][]"));
      $container.data("key", result.key);
      $container.attr("data-key", result.key);
      $delete.attr("href", $delete.attr("href").replace("key=".concat(key), "key=".concat(result.key)));
      CustomFieldsBuilders.forEach(function (builder) {
        if (builder.key == key) {
          builder.key = result.key;
        }
      });
    };

    $target.html("<input class=\"awesome-auto-edit\" data-scope=\"".concat(scope, "\" type=\"text\" value=\"").concat(key, "\">"));
    var $input = $("input.awesome-auto-edit[data-scope=\"".concat(scope, "\"]"));
    $link.hide();
    $input.select();
    $input.on("keypress", function (evt) {
      if (evt.code == "Enter" || evt.code == "13" || evt.code == "10") {
        evt.preventDefault();
        $.ajax({
          type: "POST",
          url: DecidimAwesome.rename_scope_label_path,
          dataType: "json",
          headers: {
            "X-CSRF-Token": $("meta[name=csrf-token]").attr("content")
          },
          data: {
            key: key,
            scope: scope,
            attribute: attribute,
            text: $input.val()
          }
        }).done(function (result) {
          return rebuildHmtl(result);
        }).fail(function (err) {
          console.error("Error saving key", key, "ERR:", err);
          rebuildLabel(key);
        });
      }
    });
    $input.on("blur", function () {
      rebuildLabel(key);
    });
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/check_redirections.js":
/*!***************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/check_redirections.js ***!
  \***************************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  $(".check-custom-redirections").on("click", function (evt) {
    evt.preventDefault();

    if ($(evt.target).hasClass("disabled")) {
      return;
    }

    $(evt.target).addClass("disabled");

    var getReport = function getReport(tr, response) {
      var item = $(tr).data("item");
      var $td = $(tr).find(".redirect-status");
      var type = response.type;
      var status = response.status;

      if (response.type == "opaqueredirect") {
        type = "redirect";
        status = "302";
      }

      if (item.active) {
        if (type == "redirect") {
          $td.addClass("success");
        } else {
          $td.addClass("alert");
        }
      } else {
        $td.addClass("muted");
      }

      return "".concat(type, " (").concat(status, ")");
    };

    $("tr.custom-redirection").each(function (index, tr) {
      var $td = $(tr).find(".redirect-status");
      $td.html('<span class="loading-spinner" />');
      fetch($(tr).data("origin"), {
        method: "HEAD",
        redirect: "manual"
      }).then(function (response) {
        $td.html(getReport(tr, response));
      })["catch"](function (error) {
        console.error("ERROR", error);
        $td.removeClass("loading");
      });
    });
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/codemirror.js":
/*!*******************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/codemirror.js ***!
  \*******************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var codemirror__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! codemirror */ "./node_modules/codemirror/lib/codemirror.js");
/* harmony import */ var codemirror__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(codemirror__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var codemirror_mode_css_css__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! codemirror/mode/css/css */ "./node_modules/codemirror/mode/css/css.js");
/* harmony import */ var codemirror_mode_css_css__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(codemirror_mode_css_css__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var codemirror_keymap_sublime__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! codemirror/keymap/sublime */ "./node_modules/codemirror/keymap/sublime.js");
/* harmony import */ var codemirror_keymap_sublime__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(codemirror_keymap_sublime__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var stylesheets_decidim_decidim_awesome_admin_codemirror_scss__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! stylesheets/decidim/decidim_awesome/admin/codemirror.scss */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/codemirror.scss");




$(function () {
  $(".awesome-edit-config .scoped_styles_container textarea").each(function (_idx, el) {
    codemirror__WEBPACK_IMPORTED_MODULE_0___default().fromTextArea(el, {
      lineNumbers: true,
      mode: "css",
      keymap: "sublime"
    });
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/constraints.js":
/*!********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/constraints.js ***!
  \********************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  var $modal = $("#constraintsModal");

  if (!$modal.length) {
    return;
  }

  $(".decidim_awesome-form").on("click", ".constraints-editor .add-condition,.constraints-editor .edit-condition", function (e) {
    e.preventDefault();
    var $this = $(e.target);
    var url = $this.attr("href");
    var $callout = $this.closest(".constraints-editor").find(".callout");
    $callout.hide();
    $callout.removeClass("alert success");
    $modal.find(".modal-content").html("");
    $modal.addClass("loading");
    $modal.data("url", url);
    $modal.foundation("open");
    $modal.find(".modal-content").load(url, function () {
      $modal.removeClass("loading");
    });
  }); // Custom event listener to reload the modal if needed

  document.body.addEventListener("constraint:change", function (e) {
    var vars = e.detail.map(function (setting) {
      return "".concat(setting.key, "=").concat(setting.value);
    });
    var url = "".concat($modal.data("url"), "&").concat(vars.join("&")); // console.log("constraint:change vars:", vars, "url:", url)

    $modal.addClass("loading");
    $modal.find(".modal-content").load(url, function () {
      $modal.removeClass("loading");
    });
  }); // Rails AJAX events

  document.body.addEventListener("ajax:error", function (responseText) {
    // console.log("ajax:error", responseText)
    var $container = $(".constraints-editor[data-key=\"".concat(responseText.detail[0].key, "\"]"));
    var $callout = $container.find(".callout");
    $callout.show();
    $callout.contents("p").html("".concat(responseText.detail[0].message, ": <strong>").concat(responseText.detail[0].error, "</strong>"));
    $callout.addClass("alert");
  });
  document.body.addEventListener("ajax:success", function (responseText) {
    // console.log("ajax:success", responseText)
    var $container = $(".constraints-editor[data-key=\"".concat(responseText.detail[0].key, "\"]"));
    var $callout = $container.find(".callout");
    $modal.foundation("close");
    $callout.show();
    $callout.contents("p").html(responseText.detail[0].message);
    $callout.addClass("success"); // reconstruct list

    $container.replaceWith(responseText.detail[0].html);
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/user_picker.js":
/*!********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/user_picker.js ***!
  \********************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var select2__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! select2 */ "./node_modules/select2/dist/js/select2.js");
/* harmony import */ var select2__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(select2__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var stylesheets_decidim_decidim_awesome_admin_user_picker_scss__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! stylesheets/decidim/decidim_awesome/admin/user_picker.scss */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/user_picker.scss");


$(function () {
  $("select.multiusers-select").each(function () {
    var url = $(this).attr("data-url");
    $(this).select2({
      ajax: {
        url: url,
        delay: 100,
        dataType: "json",
        processResults: function processResults(data) {
          return {
            results: data
          };
        }
      },
      escapeMarkup: function escapeMarkup(markup) {
        return markup;
      },
      templateSelection: function templateSelection(item) {
        return "".concat(item.text);
      },
      minimumInputLength: 1,
      theme: "foundation"
    });
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_admin.js":
/*!****************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_admin.js ***!
  \****************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var entrypoints_decidim_admin__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! entrypoints/decidim_admin */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-admin/app/packs/entrypoints/decidim_admin.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_constraints__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/constraints */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/constraints.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_constraints__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_admin_constraints__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var src_decidim_decidim_awesome_admin_auto_edit__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/auto_edit */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/auto_edit.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_auto_edit__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_admin_auto_edit__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var src_decidim_decidim_awesome_admin_user_picker__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/user_picker */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/user_picker.js");
/* harmony import */ var src_decidim_decidim_awesome_editors_tabs_focus__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! src/decidim/decidim_awesome/editors/tabs_focus */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/editors/tabs_focus.js");
/* harmony import */ var src_decidim_decidim_awesome_editors_tabs_focus__WEBPACK_IMPORTED_MODULE_4___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_editors_tabs_focus__WEBPACK_IMPORTED_MODULE_4__);
/* harmony import */ var src_decidim_decidim_awesome_admin_codemirror__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/codemirror */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/codemirror.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_check_redirections__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/check_redirections */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/check_redirections.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_check_redirections__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_admin_check_redirections__WEBPACK_IMPORTED_MODULE_6__);
/* harmony import */ var src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! src/decidim/decidim_awesome/editors/editor */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/editors/editor.js");
// Webpack seems to "forgget" about certain libraries already being loaded 
// if javascript_pack_tag is called two times, let's include the whole Decidim admin here instead
 // Custom scripts for awesome








$(function () {
  $(".editor-container").each(function (_idx, container) {
    (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_7__.destroyQuillEditor)(container);

    if (window.DecidimAwesome.use_markdown_editor) {
      (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_7__.createMarkdownEditor)(container);
    } else {
      (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_7__.createQuillEditor)(container);
    }
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/editors/tabs_focus.js":
/*!*********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/editors/tabs_focus.js ***!
  \*********************************************************************************************************************************************************/
/***/ (function() {

/**
 * When switching tabs in i18n fields, autofocus on the markdown if exists
 */
$(function () {
  // Event launched by foundation
  $("[data-tabs]").on("change.zf.tabs", function (event) {
    var $container = $(event.target).closest(".label--tabs").next(".tabs-content").find(".tabs-panel.is-active"); // fix inscrybmde if present

    var $input = $container.find('[name="faker-inscrybmde"]');

    if ($input.length > 0) {
      $input[0].InscrybMDE.codemirror.refresh();
    } // fix custom fields if present


    $input = $container.find(".proposal_custom_field:first");

    if ($input.length > 0) {
      // saves current data to the hidden field for the lang
      window.DecidimAwesome.CustomFieldsRenderer.storeData(); // init the current language

      window.DecidimAwesome.CustomFieldsRenderer.init($input);
    }
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.scss":
/*!******************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.scss ***!
  \******************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/codemirror.scss":
/*!*****************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/codemirror.scss ***!
  \*****************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/user_picker.scss":
/*!******************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/stylesheets/decidim/decidim_awesome/admin/user_picker.scss ***!
  \******************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			id: moduleId,
/******/ 			loaded: false,
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = __webpack_modules__;
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/chunk loaded */
/******/ 	!function() {
/******/ 		var deferred = [];
/******/ 		__webpack_require__.O = function(result, chunkIds, fn, priority) {
/******/ 			if(chunkIds) {
/******/ 				priority = priority || 0;
/******/ 				for(var i = deferred.length; i > 0 && deferred[i - 1][2] > priority; i--) deferred[i] = deferred[i - 1];
/******/ 				deferred[i] = [chunkIds, fn, priority];
/******/ 				return;
/******/ 			}
/******/ 			var notFulfilled = Infinity;
/******/ 			for (var i = 0; i < deferred.length; i++) {
/******/ 				var chunkIds = deferred[i][0];
/******/ 				var fn = deferred[i][1];
/******/ 				var priority = deferred[i][2];
/******/ 				var fulfilled = true;
/******/ 				for (var j = 0; j < chunkIds.length; j++) {
/******/ 					if ((priority & 1 === 0 || notFulfilled >= priority) && Object.keys(__webpack_require__.O).every(function(key) { return __webpack_require__.O[key](chunkIds[j]); })) {
/******/ 						chunkIds.splice(j--, 1);
/******/ 					} else {
/******/ 						fulfilled = false;
/******/ 						if(priority < notFulfilled) notFulfilled = priority;
/******/ 					}
/******/ 				}
/******/ 				if(fulfilled) {
/******/ 					deferred.splice(i--, 1)
/******/ 					var r = fn();
/******/ 					if (r !== undefined) result = r;
/******/ 				}
/******/ 			}
/******/ 			return result;
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/compat get default export */
/******/ 	!function() {
/******/ 		// getDefaultExport function for compatibility with non-harmony modules
/******/ 		__webpack_require__.n = function(module) {
/******/ 			var getter = module && module.__esModule ?
/******/ 				function() { return module['default']; } :
/******/ 				function() { return module; };
/******/ 			__webpack_require__.d(getter, { a: getter });
/******/ 			return getter;
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/define property getters */
/******/ 	!function() {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = function(exports, definition) {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/global */
/******/ 	!function() {
/******/ 		__webpack_require__.g = (function() {
/******/ 			if (typeof globalThis === 'object') return globalThis;
/******/ 			try {
/******/ 				return this || new Function('return this')();
/******/ 			} catch (e) {
/******/ 				if (typeof window === 'object') return window;
/******/ 			}
/******/ 		})();
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	!function() {
/******/ 		__webpack_require__.o = function(obj, prop) { return Object.prototype.hasOwnProperty.call(obj, prop); }
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	!function() {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = function(exports) {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/node module decorator */
/******/ 	!function() {
/******/ 		__webpack_require__.nmd = function(module) {
/******/ 			module.paths = [];
/******/ 			if (!module.children) module.children = [];
/******/ 			return module;
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/jsonp chunk loading */
/******/ 	!function() {
/******/ 		// no baseURI
/******/ 		
/******/ 		// object to store loaded and loading chunks
/******/ 		// undefined = chunk not loaded, null = chunk preloaded/prefetched
/******/ 		// [resolve, reject, Promise] = chunk loading, 0 = chunk loaded
/******/ 		var installedChunks = {
/******/ 			"decidim_admin_decidim_awesome": 0
/******/ 		};
/******/ 		
/******/ 		// no chunk on demand loading
/******/ 		
/******/ 		// no prefetching
/******/ 		
/******/ 		// no preloaded
/******/ 		
/******/ 		// no HMR
/******/ 		
/******/ 		// no HMR manifest
/******/ 		
/******/ 		__webpack_require__.O.j = function(chunkId) { return installedChunks[chunkId] === 0; };
/******/ 		
/******/ 		// install a JSONP callback for chunk loading
/******/ 		var webpackJsonpCallback = function(parentChunkLoadingFunction, data) {
/******/ 			var chunkIds = data[0];
/******/ 			var moreModules = data[1];
/******/ 			var runtime = data[2];
/******/ 			// add "moreModules" to the modules object,
/******/ 			// then flag all "chunkIds" as loaded and fire callback
/******/ 			var moduleId, chunkId, i = 0;
/******/ 			if(chunkIds.some(function(id) { return installedChunks[id] !== 0; })) {
/******/ 				for(moduleId in moreModules) {
/******/ 					if(__webpack_require__.o(moreModules, moduleId)) {
/******/ 						__webpack_require__.m[moduleId] = moreModules[moduleId];
/******/ 					}
/******/ 				}
/******/ 				if(runtime) var result = runtime(__webpack_require__);
/******/ 			}
/******/ 			if(parentChunkLoadingFunction) parentChunkLoadingFunction(data);
/******/ 			for(;i < chunkIds.length; i++) {
/******/ 				chunkId = chunkIds[i];
/******/ 				if(__webpack_require__.o(installedChunks, chunkId) && installedChunks[chunkId]) {
/******/ 					installedChunks[chunkId][0]();
/******/ 				}
/******/ 				installedChunks[chunkIds[i]] = 0;
/******/ 			}
/******/ 			return __webpack_require__.O(result);
/******/ 		}
/******/ 		
/******/ 		var chunkLoadingGlobal = self["webpackChunkapp"] = self["webpackChunkapp"] || [];
/******/ 		chunkLoadingGlobal.forEach(webpackJsonpCallback.bind(null, 0));
/******/ 		chunkLoadingGlobal.push = webpackJsonpCallback.bind(null, chunkLoadingGlobal.push.bind(chunkLoadingGlobal));
/******/ 	}();
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module depends on other loaded chunks and execution need to be delayed
/******/ 	var __webpack_exports__ = __webpack_require__.O(undefined, ["vendors-node_modules_codemirror_lib_codemirror_js","vendors-node_modules_jquery_dist_jquery-exposed_js","vendors-node_modules_html5sortable_dist_html5sortable_es_js","vendors-node_modules_europa_dist_europa_js-node_modules_inline-attachment_src_codemirror-4_in-db2b88","vendors-node_modules_bootstrap-tagsinput_dist_bootstrap-tagsinput_js-node_modules_core-js_mod-91b0c1","vendors-node_modules_react-dom_index_js","vendors-node_modules_d3_index_js","vendors-node_modules_foundation-datepicker_js_locales_foundation-datepicker_ar_js-node_module-679306","vendors-node_modules_axios_index_js-node_modules_jquery-serializejson_jquery_serializejson_js-36d27d","vendors-node_modules_codemirror_keymap_sublime_js","vendors-node_modules_codemirror_mode_css_css_js-node_modules_jquery-ui_ui_widgets_sortable_js-d99fe5","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-core_app_-b427a9","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-core_app_-fe6e7d","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-admin_app-dee16c","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_gems_decidim-decidim_awesome-0_8_1_app_packs_src_de-eb4c81","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-core_app_-577718","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-core_app_-a8a6ef","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-admin_app-529961"], function() { return __webpack_require__("../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_admin_decidim_awesome.js"); })
/******/ 	__webpack_exports__ = __webpack_require__.O(__webpack_exports__);
/******/ 	
/******/ })()
;
//# sourceMappingURL=decidim_admin_decidim_awesome.js.map