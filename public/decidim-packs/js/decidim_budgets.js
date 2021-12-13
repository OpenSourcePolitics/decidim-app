/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images sync recursive ^\\.\\/.*$":
/*!*****************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images/ sync ^\.\/.*$ ***!
  \*****************************************************************************************************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var map = {
	"./decidim/budgets/decidim_budgets.svg": "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images/decidim/budgets/decidim_budgets.svg"
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
webpackContext.id = "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images sync recursive ^\\.\\/.*$";

/***/ }),

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/progressFixed.js":
/*!********************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/progressFixed.js ***!
  \********************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  var checkProgressPosition = function checkProgressPosition() {
    var progressFix = document.querySelector("[data-progressbox-fixed]"),
        progressRef = document.querySelector("[data-progress-reference]"),
        progressVisibleClass = "is-progressbox-visible";

    if (!progressRef) {
      return;
    }

    var progressPosition = progressRef.getBoundingClientRect().bottom;

    if (progressPosition > 0) {
      progressFix.classList.remove(progressVisibleClass);
    } else {
      progressFix.classList.add(progressVisibleClass);
    }
  };

  window.addEventListener("scroll", checkProgressPosition);
  window.DecidimBudgets = window.DecidimBudgets || {};
  window.DecidimBudgets.checkProgressPosition = checkProgressPosition;
});

/***/ }),

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/projects.js":
/*!***************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/projects.js ***!
  \***************************************************************************************************************************************************/
/***/ (function() {

$(function () {
  var $projects = $("#projects, #project");
  var $budgetSummaryTotal = $(".budget-summary__total");
  var $budgetExceedModal = $("#budget-excess");
  var $budgetSummary = $(".budget-summary__progressbox");
  var totalAllocation = parseInt($budgetSummaryTotal.attr("data-total-allocation"), 10);

  var cancelEvent = function cancelEvent(event) {
    event.stopPropagation();
    event.preventDefault();
  };

  var allowExitFrom = function allowExitFrom($el) {
    if ($el.parents("#loginModal").length > 0) {
      return true;
    } else if ($el.parents("#authorizationModal").length > 0) {
      return true;
    }

    return false;
  };

  $projects.on("click", ".budget-list__action", function (event) {
    var currentAllocation = parseInt($budgetSummary.attr("data-current-allocation"), 10);
    var $currentTarget = $(event.currentTarget);
    var projectAllocation = parseInt($currentTarget.attr("data-allocation"), 10);

    if ($currentTarget.attr("disabled")) {
      cancelEvent(event);
    } else if ($currentTarget.attr("data-add") === "true" && currentAllocation + projectAllocation > totalAllocation) {
      $budgetExceedModal.foundation("toggle");
      cancelEvent(event);
    }
  });

  if ($("#order-progress [data-toggle=budget-confirm]").length > 0) {
    var safeUrl = $(".budget-summary").attr("data-safe-url").split("?")[0];
    $(document).on("click", "a", function (event) {
      if (allowExitFrom($(event.currentTarget))) {
        window.exitUrl = null;
      } else {
        window.exitUrl = event.currentTarget.href;
      }
    });
    $(document).on("submit", "form", function (event) {
      if (allowExitFrom($(event.currentTarget))) {
        window.exitUrl = null;
      } else {
        window.exitUrl = event.currentTarget.action;
      }
    });
    window.addEventListener("beforeunload", function (event) {
      var currentAllocation = parseInt($budgetSummary.attr("data-current-allocation"), 10);
      var exitUrl = window.exitUrl;
      window.exitUrl = null;

      if (currentAllocation === 0 || exitUrl && exitUrl.startsWith(safeUrl)) {
        return;
      }

      event.returnValue = true;
    });
  }
});

/***/ }),

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images/decidim/budgets/decidim_budgets.svg":
/*!**************************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images/decidim/budgets/decidim_budgets.svg ***!
  \**************************************************************************************************************************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";
module.exports = __webpack_require__.p + "media/images/decidim_budgets-63f448a8ecee4f8376a0.svg";

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
/******/ 	/* webpack/runtime/publicPath */
/******/ 	!function() {
/******/ 		__webpack_require__.p = "/decidim-packs/";
/******/ 	}();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be in strict mode.
!function() {
"use strict";
/*!**************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/entrypoints/decidim_budgets.js ***!
  \**************************************************************************************************************************************************/
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_budgets_projects__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/budgets/projects */ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/projects.js");
/* harmony import */ var src_decidim_budgets_projects__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(src_decidim_budgets_projects__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var src_decidim_budgets_progressFixed__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/budgets/progressFixed */ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/src/decidim/budgets/progressFixed.js");
/* harmony import */ var src_decidim_budgets_progressFixed__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(src_decidim_budgets_progressFixed__WEBPACK_IMPORTED_MODULE_1__);

 // Images

__webpack_require__("../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-budgets/app/packs/images sync recursive ^\\.\\/.*$");
}();
/******/ })()
;
//# sourceMappingURL=decidim_budgets.js.map