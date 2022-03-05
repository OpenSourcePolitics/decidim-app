/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/form_exit_warn.js":
/*!***********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/form_exit_warn.js ***!
  \***********************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  var $form = $("form.awesome-edit-config");

  if ($form.length > 0) {
    $form.find("input, textarea, select").on("change", function () {
      $form.data("changed", true);
    });
    var safePath = $form.data("safe-path").split("?")[0];
    $(document).on("click", "a", function (event) {
      window.exitUrl = event.currentTarget.href;
    });
    $(document).on("submit", "form", function (event) {
      window.exitUrl = event.currentTarget.action;
    });
    window.addEventListener("beforeunload", function (event) {
      var exitUrl = window.exitUrl;
      var hasChanged = $form.data("changed");
      window.exitUrl = null;

      if (!hasChanged || exitUrl && exitUrl.includes(safePath)) {
        return null;
      }

      event.returnValue = true;
    });
  }
});

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
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
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
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be in strict mode.
!function() {
"use strict";
/*!*******************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_admin_form_exit_warn.js ***!
  \*******************************************************************************************************************************************************************/
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_admin_form_exit_warn__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/admin/form_exit_warn */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/admin/form_exit_warn.js");
/* harmony import */ var src_decidim_decidim_awesome_admin_form_exit_warn__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(src_decidim_decidim_awesome_admin_form_exit_warn__WEBPACK_IMPORTED_MODULE_0__);

}();
/******/ })()
;
//# sourceMappingURL=decidim_decidim_awesome_admin_form_exit_warn.js.map