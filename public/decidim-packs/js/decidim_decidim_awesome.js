/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images sync recursive ^\\.\\/.*$":
/*!*****************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images/ sync ^\.\/.*$ ***!
  \*****************************************************************************************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var map = {
	"./decidim/decidim_awesome/platoniq-logo.png": "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images/decidim/decidim_awesome/platoniq-logo.png"
};


function webpackContext(req) {
	var id = webpackContextResolve(req);
	return __webpack_require__(id);
}
function webpackContextResolve(req) {
	if(!__webpack_require__.o(map, req)) {
		var e = new Error("Cannot find module '" + req + "'");
		e.code = 'MODULE_NOT_FOUND';
		throw e;
	}
	return map[req];
}
webpackContext.keys = function webpackContextKeys() {
	return Object.keys(map);
};
webpackContext.resolve = webpackContextResolve;
module.exports = webpackContext;
webpackContext.id = "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images sync recursive ^\\.\\/.*$";

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.js":
/*!**********************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.js ***!
  \**********************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_application_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_application.js */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_application.js");
/* harmony import */ var entrypoints_decidim_decidim_awesome_scss__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! entrypoints/decidim_decidim_awesome.scss */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.scss");
 // Images

__webpack_require__("../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images sync recursive ^\\.\\/.*$"); // CSS




/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_application.js":
/*!**********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_application.js ***!
  \**********************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_proposals_images__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/proposals/images */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/proposals/images.js");
/* harmony import */ var src_decidim_decidim_awesome_proposals_images__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_proposals_images__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var src_decidim_decidim_awesome_forms_autosave__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/decidim_awesome/forms/autosave */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/forms/autosave.js");
/* harmony import */ var src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! src/decidim/decidim_awesome/editors/editor */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/editors/editor.js");



$(function () {
  // rebuild editors
  if (window.DecidimAwesome.allow_images_in_full_editor || window.DecidimAwesome.allow_images_in_small_editor || window.DecidimAwesome.use_markdown_editor) {
    $(".editor-container").each(function (_idx, container) {
      (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_2__.destroyQuillEditor)(container);

      if (window.DecidimAwesome.use_markdown_editor) {
        (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_2__.createMarkdownEditor)(container);
      } else {
        (0,src_decidim_decidim_awesome_editors_editor__WEBPACK_IMPORTED_MODULE_2__.createQuillEditor)(container);
      }
    });
  }
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/forms/autosave.js":
/*!*****************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/forms/autosave.js ***!
  \*****************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var form_storage__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! form-storage */ "./node_modules/form-storage/lib/index.js");
/* harmony import */ var form_storage__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(form_storage__WEBPACK_IMPORTED_MODULE_0__);

$(function () {
  window.DecidimAwesome = window.DecidimAwesome || {};

  if (!window.DecidimAwesome.auto_save_forms) {
    return;
  }

  var questionnaireId = window.DecidimAwesome.current_questionnaire;

  if (!questionnaireId) {
    // console.log("Not a questionnaire page")
    return;
  }

  var storeId = "awesome_autosave:".concat(questionnaireId);
  var storeCheckboxesId = "awesome_autosave:checkboxes:".concat(questionnaireId);
  var $form = $("form.answer-questionnaire");

  if (!$form.length) {
    if (window.DecidimAwesome.questionnaire_answered) {
      // console.log("Questionnaire already answered, remove any data saved");
      window.localStorage.removeItem(storeId);
      window.localStorage.removeItem(storeCheckboxesId);
    } // console.log("No forms here");


    return;
  }

  var store = new (form_storage__WEBPACK_IMPORTED_MODULE_0___default())("#".concat($form.attr("id")), {
    name: storeId,
    ignores: [// '[type="hidden"]',
    '[name="utf8"]', '[name="authenticity_token"]', "[disabled]", '[type="checkbox"]' // there are problems with matrix questions
    ]
  });

  var showMsg = function showMsg(msg) {
    var error = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
    var default_time = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 700;
    var time = error ? 5000 : default_time;
    var $div = $("<div class=\"awesome_autosave-notice".concat(error ? " error" : "", "\">").concat(msg, "</div>")).appendTo($form);
    setTimeout(function () {
      $div.fadeOut(500, function () {
        $div.remove();
      });
    }, time);
  };

  if (!window.localStorage) {
    showMsg(window.DecidimAwesome.texts.autosaved_error, true);
    return;
  }

  if (window.localStorage.getItem(storeId)) {
    showMsg(window.DecidimAwesome.texts.autosaved_retrieved, false, 5000);
  } // restore if available


  store.apply(); // restore checkboxes

  try {
    var checkboxes = JSON.parse(window.localStorage.getItem(storeCheckboxesId));

    for (var id in checkboxes) {
      $("#".concat(id)).prop("checked", checkboxes[id]);
    }
  } catch (e) {
    console.log("No checkboxes found");
  } // this trigger the "change" event, it seems that it is too much
  // $form.find('input, textarea, select').change();


  var save = function save() {
    store.save(); // save checkbox manually

    var checkboxes = {};
    $form.find('input[type="checkbox"]').each(function (index, el) {
      checkboxes[el.id] = el.checked;
    });
    window.localStorage.setItem(storeCheckboxesId, JSON.stringify(checkboxes));
    showMsg(window.DecidimAwesome.texts.autosaved_success);
  }; // save changes when modifications


  $form.find("input, textarea, select").on("change", function () {
    save();
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/proposals/images.js":
/*!*******************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/proposals/images.js ***!
  \*******************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  window.DecidimAwesome = window.DecidimAwesome || {};
  var token = $('meta[name="csrf-token"]').attr("content");
  var $textarea = $("textarea#proposal_body");
  var t = window.DecidimAwesome.texts.drag_and_drop_image;

  if (!$textarea.length) {
    return;
  }

  if (window.DecidimAwesome.allow_images_in_proposals) {
    // Add the capability to upload images only (they will be presented as links)
    $textarea.after("<p class=\"help-text\">".concat(t, "</p>"));
    $textarea.inlineattachment({
      uploadUrl: window.DecidimAwesome.editor_uploader_path,
      uploadFieldName: "image",
      jsonFieldName: "url",
      progressText: "[Uploading file...]",
      urlText: "{filename}",
      extraHeaders: {
        "X-CSRF-Token": token
      }
    });
  }
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.scss":
/*!************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.scss ***!
  \************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images/decidim/decidim_awesome/platoniq-logo.png":
/*!********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/images/decidim/decidim_awesome/platoniq-logo.png ***!
  \********************************************************************************************************************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";
module.exports = __webpack_require__.p + "media/images/platoniq-logo-5439008eeac5e5428475.png";

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
/******/ 	/* webpack/runtime/publicPath */
/******/ 	!function() {
/******/ 		__webpack_require__.p = "/decidim-packs/";
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
/******/ 			"decidim_decidim_awesome": 0
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
/******/ 	var __webpack_exports__ = __webpack_require__.O(undefined, ["vendors-node_modules_codemirror_lib_codemirror_js","vendors-node_modules_europa_dist_europa_js-node_modules_inline-attachment_src_codemirror-4_in-db2b88","vendors-node_modules_form-storage_lib_index_js","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_bundler_gems_decidim-d0c925e2dfd1_decidim-core_app_-b427a9","_rbenv_versions_2_7_1_lib_ruby_gems_2_7_0_gems_decidim-decidim_awesome-0_8_1_app_packs_src_de-eb4c81"], function() { return __webpack_require__("../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome.js"); })
/******/ 	__webpack_exports__ = __webpack_require__.O(__webpack_exports__);
/******/ 	
/******/ })()
;
//# sourceMappingURL=decidim_decidim_awesome.js.map