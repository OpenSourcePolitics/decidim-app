/******/ (function() { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.js":
/*!***************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.js ***!
  \***************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var entrypoints_decidim_api_graphiql_scss__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! entrypoints/decidim_api_graphiql.scss */ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.scss");
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! react */ "./node_modules/react/index-exposed.js");
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var react_dom__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! react-dom */ "./node_modules/react-dom/index.js");
/* harmony import */ var graphiql__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! graphiql */ "./node_modules/graphiql/esm/index.js");
/* harmony import */ var src_decidim_configuration__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! src/decidim/configuration */ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-core/app/packs/src/decidim/configuration.js");
/* eslint-disable require-jsdoc */





window.Decidim = window.Decidim || {};
window.Decidim.config = new src_decidim_configuration__WEBPACK_IMPORTED_MODULE_4__["default"]();
var parameters = {}; // Parse the search string to get url parameters.

var search = window.location.search;
search.substr(1).split("&").forEach(function (entry) {
  var eq = entry.indexOf("=");

  if (eq >= 0) {
    parameters[decodeURIComponent(entry.slice(0, eq))] = decodeURIComponent(entry.slice(eq + 1));
  }
}); // if variables was provided, try to format it.

if (parameters.variables) {
  try {
    parameters.variables = JSON.stringify(JSON.parse(parameters.variables), null, 2);
  } catch (error) {// Do nothing, we want to display the invalid JSON as a string, rather
    // than present an error.
  }
}

var updateURL = function updateURL() {
  var newSearch = Object.keys(parameters).map(function (key) {
    return "".concat(encodeURIComponent(key), "=").concat(encodeURIComponent(parameters[key]));
  }).join("&");
  history.replaceState(null, null, "?".concat(newSearch));
}; // When the query and variables string is edited, update the URL bar so
// that it can be easily shared


var onEditQuery = function onEditQuery(newQuery) {
  parameters.query = newQuery;
  updateURL();
};

var onEditVariables = function onEditVariables(newVariables) {
  parameters.variables = newVariables;
  updateURL();
}; // Defines a GraphQL fetcher using the fetch API.


var graphQLFetcher = function graphQLFetcher(graphQLParams) {
  var graphQLEndpoint = window.Decidim.config.get("graphql_endpoint");
  return fetch(graphQLEndpoint, {
    method: "post",
    headers: JSON.parse(window.Decidim.config.get("request_headers")),
    body: JSON.stringify(graphQLParams),
    credentials: "include"
  }).then(function (response) {
    try {
      return response.json();
    } catch (error) {
      return {
        "status": response.status,
        "message": "The server responded with invalid JSON, this is probably a server-side error",
        "response": response.text()
      };
    }
  });
};

window.addEventListener("DOMContentLoaded", function () {
  // Render <GraphiQL /> into the body.
  react_dom__WEBPACK_IMPORTED_MODULE_2__.render( /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement(graphiql__WEBPACK_IMPORTED_MODULE_3__["default"], {
    fetcher: graphQLFetcher,
    defaultQuery: window.Decidim.config.get("default_query"),
    query: parameters.query,
    variables: parameters.variables,
    onEditQuery: onEditQuery,
    onEditVariables: onEditVariables
  }), document.getElementById("graphiql-container"));
});

/***/ }),

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-core/app/packs/src/decidim/configuration.js":
/*!*********************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-core/app/packs/src/decidim/configuration.js ***!
  \*********************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ Configuration; }
/* harmony export */ });
function ownKeys(object, enumerableOnly) {
  var keys = Object.keys(object);

  if (Object.getOwnPropertySymbols) {
    var symbols = Object.getOwnPropertySymbols(object);

    if (enumerableOnly) {
      symbols = symbols.filter(function (sym) {
        return Object.getOwnPropertyDescriptor(object, sym).enumerable;
      });
    }

    keys.push.apply(keys, symbols);
  }

  return keys;
}

function _objectSpread(target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i] != null ? arguments[i] : {};

    if (i % 2) {
      ownKeys(Object(source), true).forEach(function (key) {
        _defineProperty(target, key, source[key]);
      });
    } else if (Object.getOwnPropertyDescriptors) {
      Object.defineProperties(target, Object.getOwnPropertyDescriptors(source));
    } else {
      ownKeys(Object(source)).forEach(function (key) {
        Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
      });
    }
  }

  return target;
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }

  return obj;
}

function _typeof(obj) {
  "@babel/helpers - typeof";

  if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") {
    _typeof = function _typeof(obj) {
      return typeof obj;
    };
  } else {
    _typeof = function _typeof(obj) {
      return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
    };
  }

  return _typeof(obj);
}

function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, descriptor.key, descriptor);
  }
}

function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties(Constructor, staticProps);
  return Constructor;
}

var Configuration = /*#__PURE__*/function () {
  function Configuration() {
    _classCallCheck(this, Configuration);

    this.config = {};
  }

  _createClass(Configuration, [{
    key: "set",
    value: function set(key) {
      var value = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

      if (_typeof(key) === "object") {
        this.config = _objectSpread(_objectSpread({}, this.config), key);
      } else {
        this.config[key] = value;
      }
    }
  }, {
    key: "get",
    value: function get(key) {
      return this.config[key];
    }
  }]);

  return Configuration;
}();



/***/ }),

/***/ "../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.scss":
/*!*****************************************************************************************************************************************************!*\
  !*** ../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.scss ***!
  \*****************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

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
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
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
/******/ 	/* webpack/runtime/jsonp chunk loading */
/******/ 	!function() {
/******/ 		// no baseURI
/******/ 		
/******/ 		// object to store loaded and loading chunks
/******/ 		// undefined = chunk not loaded, null = chunk preloaded/prefetched
/******/ 		// [resolve, reject, Promise] = chunk loading, 0 = chunk loaded
/******/ 		var installedChunks = {
/******/ 			"decidim_api_graphiql": 0
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
/******/ 	var __webpack_exports__ = __webpack_require__.O(undefined, ["vendors-node_modules_react-dom_index_js","vendors-node_modules_expose-loader_dist_runtime_getGlobalThis_js-node_modules_graphiql_esm_in-b41003"], function() { return __webpack_require__("../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-4f7e0ffd5b1e/decidim-api/app/packs/entrypoints/decidim_api_graphiql.js"); })
/******/ 	__webpack_exports__ = __webpack_require__.O(__webpack_exports__);
/******/ 	
/******/ })()
;
//# sourceMappingURL=decidim_api_graphiql.js.map