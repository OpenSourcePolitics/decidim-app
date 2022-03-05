/******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/map/icon.js":
/*!*******************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/map/icon.js ***!
  \*******************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var leaflet_svgicon__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! leaflet-svgicon */ "./node_modules/leaflet-svgicon/index.js");


leaflet__WEBPACK_IMPORTED_MODULE_0__.DivIcon.SVGIcon = leaflet_svgicon__WEBPACK_IMPORTED_MODULE_1__.SVGIcon;
leaflet__WEBPACK_IMPORTED_MODULE_0__.DivIcon.SVGIcon.DecidimIcon = leaflet__WEBPACK_IMPORTED_MODULE_0__.DivIcon.SVGIcon.extend({
  options: {
    fillColor: "#ef604d",
    opacity: 0
  },
  _createPathDescription: function _createPathDescription() {
    return "M14 1.17a11.685 11.685 0 0 0-11.685 11.685c0 11.25 10.23 20.61 10.665 21a1.5 1.5 0 0 0 2.025 0c0.435-.435 10.665-9.81 10.665-21A11.685 11.685 0 0 0 14 1.17Zm0 17.415A5.085 5.085 0 1 1 19.085 13.5 5.085 5.085 0 0 1 14 18.585Z";
  },
  _createCircle: function _createCircle() {
    return "";
  },
  // Improved version of the _createSVG, essentially the same as in later
  // versions of Leaflet. It adds the `px` values after the width and height
  // CSS making the focus borders work correctly across all browsers.
  _createSVG: function _createSVG() {
    var path = this._createPath();

    var circle = this._createCircle();

    var text = this._createText();

    var className = "".concat(this.options.className, "-svg");
    var style = "width:".concat(this.options.iconSize.x, "px; height:").concat(this.options.iconSize.y, "px;");
    var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" class=\"".concat(className, "\" style=\"").concat(style, "\">").concat(path).concat(circle).concat(text, "</svg>");
    return svg;
  }
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/vendor/leaflet-tilelayer-here.js":
/*!****************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/vendor/leaflet-tilelayer-here.js ***!
  \****************************************************************************************************************************************************************/
/***/ (function() {

/* eslint-disable */
// 🍂class TileLayer.HERE
// Tile layer for HERE maps tiles.
L.TileLayer.HERE = L.TileLayer.extend({
  options: {
    subdomains: '1234',
    minZoom: 2,
    maxZoom: 18,
    // 🍂option scheme: String = 'normal.day'
    // The "map scheme", as documented in the HERE API.
    scheme: 'normal.day',
    // 🍂option resource: String = 'maptile'
    // The "map resource", as documented in the HERE API.
    resource: 'maptile',
    // 🍂option mapId: String = 'newest'
    // Version of the map tiles to be used, or a hash of an unique map
    mapId: 'newest',
    // 🍂option format: String = 'png8'
    // Image format to be used (`png8`, `png`, or `jpg`)
    format: 'png8',
    // 🍂option appId: String = ''
    // Required option. The `app_id` provided as part of the HERE credentials
    appId: '',
    // 🍂option appCode: String = ''
    // Required option. The `app_code` provided as part of the HERE credentials
    appCode: '',
    // 🍂option useCIT: boolean = false
    // Whether to use the CIT when loading the here-maptiles
    useCIT: false,
    // 🍂option useHTTPS: boolean = true
    // Whether to use HTTPS when loading the here-maptiles
    useHTTPS: true,
    // 🍂option language: String = ''
    // The language of the descriptions on the maps that are loaded
    language: '',
    // 🍂option language: String = ''
    // The second language of the descriptions on the maps that are loaded
    language2: ''
  },
  initialize: function initialize(options) {
    options = L.setOptions(this, options); // Decide if this scheme uses the aerial servers or the basemap servers

    var schemeStart = options.scheme.split('.')[0];
    options.tileResolution = 256; // {Base URL}{Path}/{resource (tile type)}/{map id}/{scheme}/{zoom}/{column}/{row}/{size}/{format}
    // ?apiKey={YOUR_API_KEY}
    // &{param}={value}

    var params = ['apiKey=' + encodeURIComponent(options.apiKey)]; // Fallback to old app_id,app_code if no apiKey passed

    if (!options.apiKey) {
      params = ['app_id=' + encodeURIComponent(options.appId), 'app_code=' + encodeURIComponent(options.appCode)];
    }

    if (options.language) {
      params.push('lg=' + encodeURIComponent(options.language));
    }

    if (options.language2) {
      params.push('lg2=' + encodeURIComponent(options.language2));
    }

    var urlQuery = '?' + params.join('&');
    var path = '/maptile/2.1/{resource}/{mapId}/{scheme}/{z}/{x}/{y}/{tileResolution}/{format}' + urlQuery;
    var attributionPath = '/maptile/2.1/copyright/{mapId}?apiKey={apiKey}';
    var baseUrl = 'maps.ls.hereapi.com'; // Old style with apiId/apiCode for compatibility

    if (!options.apiKey) {
      // make sure the CIT-url can be used
      baseUrl = 'maps' + (options.useCIT ? '.cit' : '') + '.api.here.com';
      attributionPath = '/maptile/2.1/copyright/{mapId}?app_id={appId}&app_code={appCode}';
    }

    var tileServer = 'base.' + baseUrl;

    if (schemeStart == 'satellite' || schemeStart == 'terrain' || schemeStart == 'hybrid') {
      tileServer = 'aerial.' + baseUrl;
    }

    if (options.scheme.indexOf('.traffic.') !== -1) {
      tileServer = 'traffic' + baseUrl;
    }

    var protocol = 'http' + (options.useHTTPS ? 's' : '');
    var tileUrl = protocol + '://{s}.' + tileServer + path;
    this._attributionUrl = L.Util.template(protocol + '://1.' + tileServer + attributionPath, this.options);
    L.TileLayer.prototype.initialize.call(this, tileUrl, options);
    this._attributionText = '';
  },
  onAdd: function onAdd(map) {
    L.TileLayer.prototype.onAdd.call(this, map);

    if (!this._attributionBBoxes) {
      this._fetchAttributionBBoxes();
    }
  },
  onRemove: function onRemove(map) {
    //
    // Remove the attribution text, and clear the cached text so it will be recalculated
    // if/when we are shown again.
    //
    this._map.attributionControl.removeAttribution(this._attributionText);

    this._attributionText = '';

    this._map.off('moveend zoomend resetview', this._findCopyrightBBox, this); //
    // Call the prototype last, once we've tidied up our own changes
    //


    L.TileLayer.prototype.onRemove.call(this, map);
  },
  _fetchAttributionBBoxes: function _onMapMove() {
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.onreadystatechange = L.bind(function () {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
        this._parseAttributionBBoxes(JSON.parse(xmlhttp.responseText));
      }
    }, this);
    xmlhttp.open("GET", this._attributionUrl, true);
    xmlhttp.send();
  },
  _parseAttributionBBoxes: function _parseAttributionBBoxes(json) {
    if (!this._map) {
      return;
    }

    var providers = json[this.options.scheme.split('.')[0]] || json.normal;

    for (var i = 0; i < providers.length; i++) {
      if (providers[i].boxes) {
        for (var j = 0; j < providers[i].boxes.length; j++) {
          var box = providers[i].boxes[j];
          providers[i].boxes[j] = L.latLngBounds([[box[0], box[1]], [box[2], box[3]]]);
        }
      }
    }

    this._map.on('moveend zoomend resetview', this._findCopyrightBBox, this);

    this._attributionProviders = providers;

    this._findCopyrightBBox();
  },
  _findCopyrightBBox: function _findCopyrightBBox() {
    if (!this._map) {
      return;
    }

    var providers = this._attributionProviders;
    var visibleProviders = [];

    var zoom = this._map.getZoom();

    var visibleBounds = this._map.getBounds();

    for (var i = 0; i < providers.length; i++) {
      if (providers[i].minLevel <= zoom && providers[i].maxLevel >= zoom) {
        if (!providers[i].boxes) {
          // No boxes = attribution always visible
          visibleProviders.push(providers[i]);
        } else {
          for (var j = 0; j < providers[i].boxes.length; j++) {
            var box = providers[i].boxes[j];

            if (visibleBounds.intersects(box)) {
              visibleProviders.push(providers[i]);
              break;
            }
          }
        }
      }
    }

    var attributions = ['<a href="https://legal.here.com/en-gb/terms" target="_blank" rel="noopener noreferrer">HERE maps</a>'];

    for (var i = 0; i < visibleProviders.length; i++) {
      var provider = visibleProviders[i];
      attributions.push('<abbr title="' + provider.alt + '">' + provider.label + '</abbr>');
    }

    var attributionText = '© ' + attributions.join(', ') + '. ';

    if (attributionText !== this._attributionText) {
      this._map.attributionControl.removeAttribution(this._attributionText);

      this._map.attributionControl.addAttribution(this._attributionText = attributionText);
    }
  }
});

L.tileLayer.here = function (opts) {
  return new L.TileLayer.HERE(opts);
};

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.js":
/*!**************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.js ***!
  \**************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_load_map_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/load_map.js */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/load_map.js");
/* harmony import */ var entrypoints_decidim_decidim_awesome_map_scss__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! entrypoints/decidim_decidim_awesome_map.scss */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.scss");
 // CSS



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/api_fetcher.js":
/*!******************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/api_fetcher.js ***!
  \******************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ ApiFetcher; }
/* harmony export */ });
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

var ApiFetcher = /*#__PURE__*/function () {
  // eslint-disable-line no-unused-vars
  function ApiFetcher(query, variables) {
    _classCallCheck(this, ApiFetcher);

    this.query = query;
    this.variables = variables;
  }

  _createClass(ApiFetcher, [{
    key: "fetch",
    value: function fetch(callback) {
      $.ajax({
        method: "POST",
        url: "/api",
        contentType: "application/json",
        data: JSON.stringify({
          query: this.query,
          variables: this.variables
        })
      }).done(function (data) {
        callback(data.data);
      });
    }
  }, {
    key: "fetchAll",
    value: function fetchAll(callback) {
      this.fetch(callback);
    }
  }]);

  return ApiFetcher;
}();



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/fetcher.js":
/*!**************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/fetcher.js ***!
  \**************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ Fetcher; }
/* harmony export */ });
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_api_api_fetcher__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/api/api_fetcher */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/api_fetcher.js");
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



var Fetcher = /*#__PURE__*/function () {
  function Fetcher(controller) {
    _classCallCheck(this, Fetcher);

    this.controller = controller;
    this.config = {
      length: controller.awesomeMap.config.length || 255
    };

    this.onFinished = function () {};

    this.onNode = function () {};

    this.hashtags = [];
    this.collection = this.controller.component.type; // override in specific components:

    this.query = "query ($id: ID!, $after: String!) {\n        component(id: $id) {\n          id\n          __typename\n        }\n      }";
  }

  _createClass(Fetcher, [{
    key: "fetch",
    value: function fetch() {
      var _this = this;

      var after = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : "";
      var variables = {
        "id": this.controller.component.id,
        "after": after
      };
      var api = new src_decidim_decidim_awesome_awesome_map_api_api_fetcher__WEBPACK_IMPORTED_MODULE_0__["default"](this.query, variables);
      api.fetchAll(function (result) {
        if (result) {
          var collection = result.component[_this.collection]; // console.log("collection",collection)

          collection.edges.forEach(function (element) {
            var node = element.node;

            if (!node) {
              return;
            }

            if (node.coordinates && node.coordinates.latitude && node.coordinates.longitude) {
              _this.decorateNode(node);

              _this.onNode(node);
            }
          });

          if (collection.pageInfo.hasNextPage) {
            _this.fetch(collection.pageInfo.endCursor);
          } else {
            _this.onFinished();
          }
        }
      });
    }
  }, {
    key: "decorateNode",
    value: function decorateNode(node) {
      var body = this.findTranslation(node.body.translations);
      var title = this.findTranslation(node.title.translations);
      node.hashtags = this.collectHashtags(title);
      node.hashtags = node.hashtags.concat(this.collectHashtags(body)); // hashtags in the title look ugly, lets replace the gid:... structure with the tag #name

      node.title.translation = this.replaceHashtags(title, node.hashtags);
      node.body.translation = this.appendHtmlHashtags(this.truncate(this.removeHashtags(body)).replace(/\n/g, "<br>"), node.hashtags);
      node.link = "".concat(this.controller.component.url, "/").concat(this.collection, "/").concat(node.id);
    }
  }, {
    key: "findTranslation",
    value: function findTranslation(translations) {
      var text,
          lang = document.querySelector("html").getAttribute("lang");
      translations.forEach(function (t) {
        if (t.text) {
          if (!text || t.locale == lang) {
            text = t.text;
          }
        }
      });
      return text;
    }
  }, {
    key: "collectHashtags",
    value: function collectHashtags(text) {
      var _this2 = this;

      var tags = [];

      if (text) {
        var gids = text.match(/gid:\/\/[^\s<]+/g);

        if (gids) {
          tags = gids.filter(function (gid) {
            return gid.indexOf("/Decidim::Hashtag/") != -1;
          }).map(function (gid) {
            var parts = gid.split("/");
            var fromSelector = parts[5].charAt(0) == "_";
            var tag = fromSelector ? parts[5].substr(1) : parts[5];
            var name = "#".concat(tag);
            var html = "<a href=\"/search?term=".concat(name, "\">").concat(name, "</a>");
            var hashtag = {
              color: getComputedStyle(document.documentElement).getPropertyValue("--secondary"),
              gid: gid,
              id: parseInt(parts[4], 10),
              fromSelector: fromSelector,
              tag: tag,
              name: name,
              html: html
            };

            _this2.hashtags.push(hashtag);

            return hashtag;
          });
        }
      }

      return tags;
    }
  }, {
    key: "replaceHashtags",
    value: function replaceHashtags(text, hashtags) {
      hashtags.forEach(function (tag) {
        text = text.replace(tag.gid, tag.name);
      });
      return text;
    }
  }, {
    key: "removeHashtags",
    value: function removeHashtags(text) {
      return text.replace(/gid:\/\/[^\s<]+/g, "");
    }
  }, {
    key: "appendHtmlHashtags",
    value: function appendHtmlHashtags(text, tags) {
      tags.forEach(function (tag) {
        text += " ".concat(tag.html);
      });
      return text;
    }
  }, {
    key: "truncate",
    value: function truncate(html) {
      return $.truncate(html, this.config);
    }
  }]);

  return Fetcher;
}();



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/meetings_fetcher.js":
/*!***********************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/meetings_fetcher.js ***!
  \***********************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ MeetingsFetcher; }
/* harmony export */ });
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_api_fetcher__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/api/fetcher */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/fetcher.js");
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

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) _setPrototypeOf(subClass, superClass);
}

function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();

  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived),
        result;

    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;

      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }

    return _possibleConstructorReturn(this, result);
  };
}

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof(call) === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }

  return _assertThisInitialized(self);
}

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct) return false;
  if (Reflect.construct.sham) return false;
  if (typeof Proxy === "function") return true;

  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
    return true;
  } catch (e) {
    return false;
  }
}

function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}



var MeetingsFetcher = /*#__PURE__*/function (_Fetcher) {
  _inherits(MeetingsFetcher, _Fetcher);

  var _super = _createSuper(MeetingsFetcher);

  function MeetingsFetcher(controller) {
    var _this;

    _classCallCheck(this, MeetingsFetcher);

    _this = _super.call(this, controller);
    _this.query = "query ($id: ID!, $after: String!) {\n    component(id: $id) {\n        id\n        __typename\n        ... on Meetings {\n          meetings(first: 50, after: $after) {\n            pageInfo {\n              hasNextPage\n              endCursor\n            }\n            edges {\n              node {\n                id\n                title {\n                  translations {\n                    text\n                    locale\n                  }\n                }\n                body: description {\n                  translations {\n                    text\n                    locale\n                  }\n                }\n                startTime\n                location {\n                  translations {\n                    text\n                    locale\n                  }\n                }\n                address\n                locationHints {\n                  translations {\n                    text\n                    locale\n                  }\n                }\n                coordinates {\n                  latitude\n                  longitude\n                }\n                category {\n                  id\n                }\n              }\n            }\n          }\n        }\n      }\n    }";
    return _this;
  }

  return MeetingsFetcher;
}(src_decidim_decidim_awesome_awesome_map_api_fetcher__WEBPACK_IMPORTED_MODULE_0__["default"]);



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/proposals_fetcher.js":
/*!************************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/proposals_fetcher.js ***!
  \************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ ProposalsFetcher; }
/* harmony export */ });
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_api_fetcher__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/api/fetcher */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/fetcher.js");
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

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) _setPrototypeOf(subClass, superClass);
}

function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();

  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived),
        result;

    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;

      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }

    return _possibleConstructorReturn(this, result);
  };
}

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof(call) === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }

  return _assertThisInitialized(self);
}

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct) return false;
  if (Reflect.construct.sham) return false;
  if (typeof Proxy === "function") return true;

  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
    return true;
  } catch (e) {
    return false;
  }
}

function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}



var ProposalsFetcher = /*#__PURE__*/function (_Fetcher) {
  _inherits(ProposalsFetcher, _Fetcher);

  var _super = _createSuper(ProposalsFetcher);

  function ProposalsFetcher(controller) {
    var _this;

    _classCallCheck(this, ProposalsFetcher);

    _this = _super.call(this, controller);
    _this.query = "query ($id: ID!, $after: String!) {\n      component(id: $id) {\n          id\n          __typename\n          ... on Proposals {\n            proposals(first: 50, after: $after){\n              pageInfo {\n                hasNextPage\n                endCursor\n              }\n              edges {\n                node {\n                  id\n                  state\n                  title {\n                    translations {\n                      text\n                      locale\n                    }\n                  }\n                  body {\n                    translations {\n                      text\n                      locale\n                    }\n                  }\n                  address\n                  coordinates {\n                    latitude\n                    longitude\n                  }\n                  amendments {\n                    emendation {\n                      id\n                    }\n                  }\n                  category {\n                    id\n                  }\n                }\n              }\n            }\n          }\n        }\n      }";
    return _this;
  }

  return ProposalsFetcher;
}(src_decidim_decidim_awesome_awesome_map_api_fetcher__WEBPACK_IMPORTED_MODULE_0__["default"]);



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/awesome_map.js":
/*!**************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/awesome_map.js ***!
  \**************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ AwesomeMap; }
/* harmony export */ });
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var src_decidim_map_icon_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/map/icon.js */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/map/icon.js");
/* harmony import */ var src_decidim_vendor_leaflet_tilelayer_here__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! src/decidim/vendor/leaflet-tilelayer-here */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/bundler/gems/decidim-d0c925e2dfd1/decidim-core/app/packs/src/decidim/vendor/leaflet-tilelayer-here.js");
/* harmony import */ var src_decidim_vendor_leaflet_tilelayer_here__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(src_decidim_vendor_leaflet_tilelayer_here__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var leaflet_markercluster__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! leaflet.markercluster */ "./node_modules/leaflet.markercluster/dist/leaflet.markercluster-src.js");
/* harmony import */ var leaflet_markercluster__WEBPACK_IMPORTED_MODULE_3___default = /*#__PURE__*/__webpack_require__.n(leaflet_markercluster__WEBPACK_IMPORTED_MODULE_3__);
/* harmony import */ var leaflet_featuregroup_subgroup__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! leaflet.featuregroup.subgroup */ "./node_modules/leaflet.featuregroup.subgroup/dist/leaflet.featuregroup.subgroup.js");
/* harmony import */ var leaflet_featuregroup_subgroup__WEBPACK_IMPORTED_MODULE_4___default = /*#__PURE__*/__webpack_require__.n(leaflet_featuregroup_subgroup__WEBPACK_IMPORTED_MODULE_4__);
/* harmony import */ var src_vendor_jquery_truncate__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! src/vendor/jquery.truncate */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/vendor/jquery.truncate.js");
/* harmony import */ var src_vendor_jquery_truncate__WEBPACK_IMPORTED_MODULE_5___default = /*#__PURE__*/__webpack_require__.n(src_vendor_jquery_truncate__WEBPACK_IMPORTED_MODULE_5__);
/* harmony import */ var jsrender__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! jsrender */ "./node_modules/jsrender/jsrender.js");
/* harmony import */ var jsrender__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(jsrender__WEBPACK_IMPORTED_MODULE_6__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_controls_ui__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/controls_ui */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controls_ui.js");
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_controllers_proposals_controller__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/controllers/proposals_controller */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/proposals_controller.js");
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_controllers_meetings_controller__WEBPACK_IMPORTED_MODULE_9__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/controllers/meetings_controller */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/meetings_controller.js");
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


 // comes with Decidim


 // Comes with Decidim

 // included in this package.json







var AwesomeMap = /*#__PURE__*/function () {
  function AwesomeMap(map, config) {
    _classCallCheck(this, AwesomeMap);

    this.map = map;
    this.categories = window.AwesomeMap && window.AwesomeMap.categories || [];
    this.config = $.extend({
      length: 255,
      center: null,
      zoom: 8,
      menu: {
        amendments: false,
        meetings: false,
        categories: true,
        hashtags: false,
        mergeComponents: false
      },
      show: {
        withdrawn: false,
        accepted: false,
        evaluating: false,
        notAnswered: false,
        rejected: false
      },
      hideControls: false,
      collapsedMenu: false,
      components: []
    }, config);
    this.layers = {};
    this.cluster = new leaflet__WEBPACK_IMPORTED_MODULE_0__.MarkerClusterGroup();
    this.map.addLayer(this.cluster);
    this.controls = new src_decidim_decidim_awesome_awesome_map_controls_ui__WEBPACK_IMPORTED_MODULE_7__["default"](this);
    this.allMarkers = [];

    this.onFinished = function () {};

    this.controllers = {};
    this.loading = [];
    this._firstController = {};
  } // Queries the API and load all the markers


  _createClass(AwesomeMap, [{
    key: "loadControllers",
    value: function loadControllers() {
      var _this = this;

      this.autoResize();
      this.controls.attach();
      this.config.components.forEach(function (component) {
        var controller = _this._getController(component);

        if (controller) {
          controller.loadNodes();

          _this.loading.push(component.type);

          controller.onFinished = function () {
            _this.loading.pop();

            _this.autoResize();

            if (_this.loading.length == 0) {
              _this.controls.$loading.hide(); // call trigger as all loads are finished


              _this.onFinished();
            }
          };
        }
      });
    }
  }, {
    key: "autoResize",
    value: function autoResize() {
      // Setup center/zoom options if specified, otherwise fitbounds
      var bounds = this.cluster.getBounds();

      if (this.config.center && this.config.zoom) {
        this.map.setView(this.config.center, this.config.zoom);
      } else if (bounds.isValid()) {
        // this.map.fitBounds(bounds, { padding: [50, 50] }); // this doesn't work much of the time, probably some race condition
        this.map.fitBounds([[bounds.getNorth(), bounds.getEast()], [bounds.getSouth(), bounds.getWest()]], {
          padding: [50, 50]
        });
      }
    }
  }, {
    key: "getCategory",
    value: function getCategory(category) {
      var _this2 = this;

      var defaultCat = {
        color: getComputedStyle(document.documentElement).getPropertyValue("--primary"),
        children: function children() {},
        parent: null,
        name: null
      };

      if (category) {
        var id = category.id ? parseInt(category.id, 10) : parseInt(category, 10);
        var cat = this.categories.find(function (c) {
          return c.id == id;
        });

        if (cat) {
          cat.children = function () {
            return _this2.categories.filter(function (c) {
              return c.parent === cat.id;
            });
          };

          return cat;
        }
      }

      return defaultCat;
    }
  }, {
    key: "_getController",
    value: function _getController(component) {
      var controller;

      if (component.type == "proposals") {
        controller = new src_decidim_decidim_awesome_awesome_map_controllers_proposals_controller__WEBPACK_IMPORTED_MODULE_8__["default"](this, component);
      }

      if (component.type == "meetings" && this.config.menu.meetings) {
        controller = new src_decidim_decidim_awesome_awesome_map_controllers_meetings_controller__WEBPACK_IMPORTED_MODULE_9__["default"](this, component);
      }

      if (controller) {
        // Agrupate layers for controlling components
        if (this._firstController[component.type] && this.config.menu.mergeComponents) {
          controller.controls = this._firstController[component.type].controls;
        } else {
          controller.addControls();
        }

        this._firstController[component.type] = this._firstController[component.type] || controller;
        this.controllers[component.type] = controller;
        return this.controllers[component.type];
      }
    }
  }]);

  return AwesomeMap;
}();



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/controller.js":
/*!*************************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/controller.js ***!
  \*************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ Controller; }
/* harmony export */ });
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
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



var Controller = /*#__PURE__*/function () {
  function Controller(awesomeMap, component) {
    _classCallCheck(this, Controller);

    this.awesomeMap = awesomeMap;
    this.component = component;
    this.templateId = "marker-meeting-popup";
    this.controls = {
      label: this.getLabel(),
      group: new leaflet__WEBPACK_IMPORTED_MODULE_0__.FeatureGroup.SubGroup(this.awesomeMap.cluster)
    };

    this.onFinished = function () {};

    this.allMarkers = [];
  }

  _createClass(Controller, [{
    key: "getLabel",
    value: function getLabel() {
      var text = this.awesomeMap.config.menu.mergeComponents || !this.component.name ? window.DecidimAwesome.texts[this.component.type] : this.component.name;
      return "<span class=\"awesome_map-component\" id=\"awesome_map-component_".concat(this.component.id, "\" title=\"0\" data-layer=\"").concat(this.component.type, "\">").concat(text, "</span>");
    }
  }, {
    key: "setFetcher",
    value: function setFetcher(Fetcher) {
      var _this = this;

      this.fetcher = new Fetcher(this);

      this.fetcher.onFinished = function () {
        // console.log(`all ${this.component.type} loaded`, this)
        _this._onFinished();
      };
    }
  }, {
    key: "addControls",
    value: function addControls() {
      this.awesomeMap.controls.main.addOverlay(this.controls.group, this.controls.label);
      this.awesomeMap.map.addLayer(this.controls.group);
    }
  }, {
    key: "loadNodes",
    value: function loadNodes() {// to override
    }
  }, {
    key: "addMarker",
    value: function addMarker(marker, node) {
      var _this2 = this;
      /* theorically, this should be enough to create popups on markers but looks that there is som bug in leaflet that sometimes prevents this to work
      let node = document.createElement("div");
      // console.log("addMarker", marker, "node", node)
      node.innerHTML = $.templates(`#${this.templateId}`).render(node);
      marker.bindPopup(node, {
        maxwidth: 640,
        minWidth: 500,
        keepInView: true,
        className: "map-info"
      }); */


      marker.on("click", function () {
        var dom = document.createElement("div");
        dom.innerHTML = $.templates("#".concat(_this2.templateId)).render(node);
        var pop = leaflet__WEBPACK_IMPORTED_MODULE_0__.popup({
          maxwidth: 640,
          minWidth: 500,
          keepInView: true,
          className: "map-info"
        }).setLatLng(marker.getLatLng()).setContent(dom);

        _this2.awesomeMap.map.addlayer(pop);
      });
      this.controls.group.addLayer(marker);
      this.allMarkers.push({
        marker: marker,
        component: this.component,
        node: node
      });
      this.addMarkerCategory(marker, node.category);
      this.addMarkerHashtags(marker, node.hashtags);
    }
  }, {
    key: "addMarkerCategory",
    value: function addMarkerCategory(marker, category) {
      // Add to category layer
      var cat = this.awesomeMap.getCategory(category);

      if (this.awesomeMap.layers[cat.id]) {
        marker.addTo(this.awesomeMap.layers[cat.id].group);
        this.awesomeMap.controls.showCategory(cat);
      }
    }
  }, {
    key: "addMarkerHashtags",
    value: function addMarkerHashtags(marker, hashtags) {
      // Add hashtag layer
      if (this.awesomeMap.config.menu.hashtags) {
        this.awesomeMap.controls.addHashtagsControls(hashtags, marker);
      }
    } // Override if needed (call this.onFinished() at the end!)

  }, {
    key: "_onFinished",
    value: function _onFinished() {
      this.awesomeMap.controls.updateStats("component_".concat(this.component.id), this.allMarkers.length);
      this.onFinished();
    }
  }, {
    key: "createIcon",
    value: function createIcon(Builder, color) {
      return new Builder({
        color: "#000000",
        fillColor: color,
        circleFillColor: color,
        weight: 1,
        stroke: color,
        fillOpacity: 0.9
      });
    }
  }]);

  return Controller;
}();



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/meetings_controller.js":
/*!**********************************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/meetings_controller.js ***!
  \**********************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ MeetingsController; }
/* harmony export */ });
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_controllers_controller__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/controllers/controller */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/controller.js");
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_api_meetings_fetcher__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/api/meetings_fetcher */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/meetings_fetcher.js");
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

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) _setPrototypeOf(subClass, superClass);
}

function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();

  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived),
        result;

    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;

      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }

    return _possibleConstructorReturn(this, result);
  };
}

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof(call) === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }

  return _assertThisInitialized(self);
}

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct) return false;
  if (Reflect.construct.sham) return false;
  if (typeof Proxy === "function") return true;

  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
    return true;
  } catch (e) {
    return false;
  }
}

function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}




var MeetingIcon = leaflet__WEBPACK_IMPORTED_MODULE_0__.DivIcon.SVGIcon.DecidimIcon.extend({
  _createPathDescription: function _createPathDescription() {
    return "M 15.991543,4 C 7.3956015,4 2.9250351,10.5 3.000951,16.999999 3.1063486,26.460968 12.747693,30.000004 15.991543,43 19.242091,30.000004 29,26.255134 29,16.999999 29,10.5 23.951131,4 15.996007,4 m -0.153508,2.6000001 a 2.1720294,2.1076698 0 0 1 2.330514,2.1124998 2.177008,2.1125006 0 0 1 -4.354016,0 2.1720294,2.1076698 0 0 1 2.023502,-2.1124998 m -2.651707,4.8056679 h 5.610202 l 3.935584,7.569899 -1.926038,0.934266 -2.009546,-3.859265 v 14.557403 h -2.484243 v -9.126003 h -0.642162 v 9.126003 H 13.190347 V 16.050568 l -2.009545,3.859265 -1.926036,-0.934266 3.935581,-7.569899";
  }
});

var MeetingsController = /*#__PURE__*/function (_Controller) {
  _inherits(MeetingsController, _Controller);

  var _super = _createSuper(MeetingsController);

  function MeetingsController(awesomeMap, component) {
    var _this;

    _classCallCheck(this, MeetingsController);

    _this = _super.call(this, awesomeMap, component);
    _this.templateId = "marker-meeting-popup";

    _this.setFetcher(src_decidim_decidim_awesome_awesome_map_api_meetings_fetcher__WEBPACK_IMPORTED_MODULE_2__["default"]);

    return _this;
  }

  _createClass(MeetingsController, [{
    key: "loadNodes",
    value: function loadNodes() {
      var _this2 = this; // for each meeting, create a marker with an associated popup


      this.fetcher.onNode = function (meeting) {
        var marker = new leaflet__WEBPACK_IMPORTED_MODULE_0__.Marker([meeting.coordinates.latitude, meeting.coordinates.longitude], {
          icon: _this2.createIcon(MeetingIcon, _this2.awesomeMap.getCategory(meeting.category).color),
          title: meeting.title.translation
        }); // console.log("new meeting", meeting, marker)

        _this2.addMarker(marker, meeting);
      };

      this.fetcher.fetch();
    }
  }]);

  return MeetingsController;
}(src_decidim_decidim_awesome_awesome_map_controllers_controller__WEBPACK_IMPORTED_MODULE_1__["default"]);



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/proposals_controller.js":
/*!***********************************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/proposals_controller.js ***!
  \***********************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ ProposalsController; }
/* harmony export */ });
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_controllers_controller__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/controllers/controller */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controllers/controller.js");
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_api_proposals_fetcher__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/api/proposals_fetcher */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/api/proposals_fetcher.js");
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

function _get() {
  if (typeof Reflect !== "undefined" && Reflect.get) {
    _get = Reflect.get;
  } else {
    _get = function _get(target, property, receiver) {
      var base = _superPropBase(target, property);

      if (!base) return;
      var desc = Object.getOwnPropertyDescriptor(base, property);

      if (desc.get) {
        return desc.get.call(arguments.length < 3 ? target : receiver);
      }

      return desc.value;
    };
  }

  return _get.apply(this, arguments);
}

function _superPropBase(object, property) {
  while (!Object.prototype.hasOwnProperty.call(object, property)) {
    object = _getPrototypeOf(object);
    if (object === null) break;
  }

  return object;
}

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) _setPrototypeOf(subClass, superClass);
}

function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();

  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived),
        result;

    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;

      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }

    return _possibleConstructorReturn(this, result);
  };
}

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof(call) === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }

  return _assertThisInitialized(self);
}

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct) return false;
  if (Reflect.construct.sham) return false;
  if (typeof Proxy === "function") return true;

  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
    return true;
  } catch (e) {
    return false;
  }
}

function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}




var ProposalIcon = leaflet__WEBPACK_IMPORTED_MODULE_0__.DivIcon.SVGIcon.DecidimIcon.extend({
  options: {
    fillColor: "#ef604d",
    fillOpacity: 0.8,
    strokeWidth: 1,
    strokeOpcacity: 1
  }
});

var ProposalsController = /*#__PURE__*/function (_Controller) {
  _inherits(ProposalsController, _Controller);

  var _super = _createSuper(ProposalsController);

  function ProposalsController(awesomeMap, component) {
    var _this;

    _classCallCheck(this, ProposalsController);

    _this = _super.call(this, awesomeMap, component);
    _this.templateId = "marker-proposal-popup";
    _this.amendments = {};

    _this.setFetcher(src_decidim_decidim_awesome_awesome_map_api_proposals_fetcher__WEBPACK_IMPORTED_MODULE_2__["default"]);

    return _this;
  }

  _createClass(ProposalsController, [{
    key: "addControls",
    value: function addControls() {
      _get(_getPrototypeOf(ProposalsController.prototype), "addControls", this).call(this); // add control layer for amendments if any


      if (this.awesomeMap.config.menu.amendments && this.component.amendments && !this.awesomeMap.layers.amendments) {
        this.awesomeMap.layers.amendments = {
          label: "<span class=\"awesome_map-component\" id=\"awesome_map-amendments_".concat(this.component.id, "\" title=\"0\" data-layer=\"amendments\">").concat(window.DecidimAwesome.texts.amendments, "</span>"),
          group: new leaflet__WEBPACK_IMPORTED_MODULE_0__.FeatureGroup.SubGroup(this.awesomeMap.cluster)
        };
        this.awesomeMap.controls.main.addOverlay(this.awesomeMap.layers.amendments.group, this.awesomeMap.layers.amendments.label);
        this.awesomeMap.layers.amendments.group.addTo(this.awesomeMap.map);
      }
    }
  }, {
    key: "loadNodes",
    value: function loadNodes() {
      var _this2 = this; // for each proposal, create a marker with an associated popup


      this.fetcher.onNode = function (proposal) {
        var marker = new leaflet__WEBPACK_IMPORTED_MODULE_0__.Marker([proposal.coordinates.latitude, proposal.coordinates.longitude], {
          icon: _this2.createIcon(ProposalIcon, _this2.awesomeMap.getCategory(proposal.category).color),
          title: proposal.title.translation
        }); // Check if it has amendments, add it to a list
        // also assign parent's proposal categories to it

        if (proposal.amendments && proposal.amendments.length) {
          proposal.amendments.forEach(function (amendment) {
            _this2.amendments[amendment.emendation.id] = proposal;
          });
        } // console.log("new proposal", proposal, "marker",  marker)


        _this2.addMarker(marker, proposal);
      };

      this.fetcher.fetch();
    }
  }, {
    key: "_onFinished",
    value: function _onFinished() {
      var _this3 = this;

      var iterableAmendments = Object.entries(this.amendments);
      this.awesomeMap.controls.updateStats("component_".concat(this.component.id), this.allMarkers.length - iterableAmendments.length);
      this.awesomeMap.controls.updateStats("amendments_".concat(this.component.id), iterableAmendments.length); // Process all amendments

      iterableAmendments.forEach(function (amendment) {
        var marker = _this3.allMarkers.find(function (item) {
          return item.node.id == amendment[0];
        });

        var parent = amendment[1]; // console.log("marker", marker, "parent proposal", parent)
        // add marker to amendments layers and remove it from proposals

        if (marker) {
          try {
            marker.marker.removeFrom(_this3.controls.group);
          } catch (e) {
            console.error("error removeFrom marker", marker, "layer", _this3.controls.group, e);
          }

          if (_this3.awesomeMap.config.menu.amendments) {
            marker.marker.addTo(_this3.awesomeMap.layers.amendments.group); // mimic parent category (amendments doesn't have categories)

            if (parent.category) {
              marker.marker.setIcon(_this3.createIcon(ProposalIcon, _this3.awesomeMap.getCategory(parent.category).color));

              _this3.addMarkerCategory(marker.marker, parent.category);
            }
          }
        }
      });
      this.onFinished();
    }
  }]);

  return ProposalsController;
}(src_decidim_decidim_awesome_awesome_map_controllers_controller__WEBPACK_IMPORTED_MODULE_1__["default"]);



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controls_ui.js":
/*!**************************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/controls_ui.js ***!
  \**************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* binding */ ControlsUI; }
/* harmony export */ });
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! leaflet */ "./node_modules/leaflet/dist/leaflet-src.js");
/* harmony import */ var leaflet__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(leaflet__WEBPACK_IMPORTED_MODULE_0__);
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



var ControlsUI = /*#__PURE__*/function () {
  function ControlsUI(awesomeMap) {
    var _this = this;

    _classCallCheck(this, ControlsUI);

    this.awesomeMap = awesomeMap;
    this.main = leaflet__WEBPACK_IMPORTED_MODULE_0__.control.layers(null, null, {
      position: "topleft",
      sortLayers: false,
      collapsed: this.awesomeMap.config.collapsedMenu // hideSingleBase: true

    });

    if (this.awesomeMap.config.hideControls) {
      $(this.main.getContainer()).hide();
    }

    this.$loading = $("#awesome-map .loading-spinner");
    this.onHashtag = this._orderHashtags;
    this.awesomeMap.map.on("overlayadd", function () {
      _this.removeHiddenCategories();
    });
  }

  _createClass(ControlsUI, [{
    key: "attach",
    value: function attach() {
      var _this2 = this; // legends


      this.main.addTo(this.awesomeMap.map);
      this.addSearchControls();

      if (this.awesomeMap.config.menu.categories) {
        this.addCategoriesControls();
      } // sub-layer hashtag title toggle


      $("#awesome-map").on("click", ".awesome_map-title-control", function (e) {
        e.preventDefault();
        e.stopPropagation();
        $("#awesome_map-categories-control").toggleClass("active");
        $("#awesome_map-hashtags-control").toggleClass("active");
      }); // hashtag events

      $("#awesome-map").on("change", ".awesome_map-hashtags-selector", function (e) {
        e.preventDefault();
        e.stopPropagation();
        var tag = $(e.target).closest("label").data("layer"); // console.log("changed, layer", tag, "checked", e.target.checked, e);

        if (tag) {
          _this2.updateHashtagLayers();
        }
      }); // select/deselect all tags

      $("#awesome-map").on("click", ".awesome_map-toggle_all_tags", function (e) {
        e.preventDefault();
        e.stopPropagation();
        $("#awesome-map .awesome_map-hashtags-selector").prop("checked", $("#awesome-map .awesome_map-hashtags-selector:checked").length < $("#awesome-map .awesome_map-hashtags-selector").length);

        _this2.updateHashtagLayers();
      });
    }
  }, {
    key: "addSearchControls",
    value: function addSearchControls() {
      $(this.main.getContainer()).contents("form").append("<div id=\"awesome_map-categories-control\" class=\"active\"><b class=\"awesome_map-title-control\">".concat(window.DecidimAwesome.texts.categories, "</b><div class=\"categories-container\"></div></div>\n    <div id=\"awesome_map-hashtags-control\"><b class=\"awesome_map-title-control\">").concat(window.DecidimAwesome.texts.hashtags, "</b><div class=\"hashtags-container\"></div><a href=\"#\" class=\"awesome_map-toggle_all_tags\">").concat(window.DecidimAwesome.texts.select_deselect_all, "</a></div>"));
    }
  }, {
    key: "addCategoriesControls",
    value: function addCategoriesControls() {
      var _this3 = this;

      this.awesomeMap.categories.forEach(function (category) {
        // add control layer for this category
        var label = "<i class=\"awesome_map-category_".concat(category.id, "\"></i> ").concat(category.name);
        _this3.awesomeMap.layers[category.id] = {
          label: label,
          group: leaflet__WEBPACK_IMPORTED_MODULE_0__.featureGroup.subGroup(_this3.awesomeMap.cluster)
        };

        _this3.awesomeMap.layers[category.id].group.addTo(_this3.awesomeMap.map);

        $("#awesome_map-categories-control .categories-container").append("<label data-layer=\"".concat(category.id, "\" class=\"awesome_map-category-").concat(category.id).concat(category.parent ? " subcategory" : "", "\" data-parent=\"").concat(category.parent, "\"><input type=\"checkbox\" class=\"awesome_map-categories-selector\" checked><span>").concat(label, "</span></label>"));
      }); // category events

      $("#awesome-map").on("change", ".awesome_map-categories-selector", function (e) {
        e.preventDefault();
        e.stopPropagation();
        var id = $(e.target).closest("label").data("layer");

        var cat = _this3.awesomeMap.getCategory(id); // console.log("changed, layer", id, "cat", cat, "checked", e.target.checked, e);


        if (cat) {
          var layer = _this3.awesomeMap.layers[cat.id];

          if (e.target.checked) {
            // show group of markers
            _this3.awesomeMap.map.addLayer(layer.group);
          } else {
            // hide group of markers
            _this3.awesomeMap.map.removeLayer(layer.group); // cat.children().forEach((c) => {
            //   let $el = $(`.awesome_map-category-${c.id}`);
            //   if($el.contents("input").prop("checked")) {
            //     $el.click();
            //   }
            // });

          } // if it's a children, put the parent to indeterminate


          _this3._indeterminateParentInput(cat); // sync tags


          _this3.updateHashtagLayers();
        }
      });
    } // Hashtags are collected directly from proposals (this is different than categories)

  }, {
    key: "addHashtagsControls",
    value: function addHashtagsControls(hashtags, marker) {
      var _this4 = this; // show hashtag layer


      if (hashtags && hashtags.length) {
        $("#awesome_map-hashtags-control").show();
        hashtags.forEach(function (hashtag) {
          // Add layer if not exists, otherwise just add the marker to the group
          if (!_this4.awesomeMap.layers[hashtag.tag]) {
            _this4.awesomeMap.layers[hashtag.tag] = {
              label: hashtag.name,
              group: new leaflet__WEBPACK_IMPORTED_MODULE_0__.FeatureGroup.SubGroup(_this4.awesomeMap.cluster)
            };

            _this4.awesomeMap.layers[hashtag.tag].group.addTo(_this4.awesomeMap.map);

            $("#awesome_map-hashtags-control .hashtags-container").append("<label data-layer=\"".concat(hashtag.tag, "\" class=\"awesome_map-hashtag-").concat(hashtag.tag, "\"><input type=\"checkbox\" class=\"awesome_map-hashtags-selector\" checked><span>").concat(hashtag.name, "</span></label>")); // Call a trigger, might be in service for customizations

            _this4.onHashtag(hashtag, $("#awesome_map-hashtags-control .hashtags-container"));
          }

          marker.addTo(_this4.awesomeMap.layers[hashtag.tag].group);
          var $label = $("label.awesome_map-hashtag-".concat(hashtag.tag)); // update number of items

          $label.attr("title", "".concat(parseInt($label.attr("title") || 0) + 1, " ").concat(window.DecidimAwesome.texts.items));
        });
      }
    }
  }, {
    key: "showCategory",
    value: function showCategory(cat) {
      $("#awesome_map-categories-control").show(); // show category if hidden

      var $label = $("label.awesome_map-category-".concat(cat.id));
      var $parent = $("label.awesome_map-category-".concat(cat.parent));
      $label.show(); // update number of items

      $label.attr("title", "".concat(parseInt($label.attr("title") || 0) + 1, " ").concat(window.DecidimAwesome.texts.items)); // show parent if apply

      $parent.show();
      $parent.attr("title", "".concat(parseInt($parent.attr("title") || 0) + 1, " ").concat(window.DecidimAwesome.texts.items));
    }
  }, {
    key: "removeHiddenComponents",
    value: function removeHiddenComponents() {
      var _this5 = this;

      $(".awesome_map-component").each(function (_idx, el) {
        var layer = _this5.awesomeMap.layers[$(el).data("layer")];

        var $input = $(el).closest("div").find("input:not(:checked)");

        if (layer && $input.length) {
          _this5.awesomeMap.map.addLayer(layer.group);

          _this5.awesomeMap.map.removeLayer(layer.group);
        }
      });
    }
  }, {
    key: "removeHiddenCategories",
    value: function removeHiddenCategories() {
      var _this6 = this;

      $(".awesome_map-categories-selector:not(:checked)").each(function (_idx, el) {
        var layer = _this6.awesomeMap.layers[$(el).closest("label").data("layer")];

        if (layer) {
          _this6.awesomeMap.map.addLayer(layer.group);

          _this6.awesomeMap.map.removeLayer(layer.group);
        }
      });
    }
  }, {
    key: "updateHashtagLayers",
    value: function updateHashtagLayers() {
      var _this7 = this; // hide all


      $(".awesome_map-hashtags-selector").each(function (_idx, el) {
        var layer = _this7.awesomeMap.layers[$(el).closest("label").data("layer")];

        if (layer) {
          _this7.awesomeMap.map.removeLayer(layer.group);
        }
      }); // show selected only

      $(".awesome_map-hashtags-selector:checked").each(function (_idx, el) {
        var layer = _this7.awesomeMap.layers[$(el).closest("label").data("layer")];

        if (layer) {
          _this7.awesomeMap.map.addLayer(layer.group);
        }
      }); // hide non-selected categories

      this.removeHiddenComponents();
      this.removeHiddenCategories();
    }
  }, {
    key: "updateStats",
    value: function updateStats(uid, total) {
      // update component stats
      var $component = $("#awesome_map-".concat(uid));
      $component.attr("title", "".concat(total, " ").concat(window.DecidimAwesome.texts.items));
    }
  }, {
    key: "_indeterminateParentInput",
    value: function _indeterminateParentInput(cat) {
      if (cat.parent) {
        var $input = $(".awesome_map-category-".concat(cat.parent)).contents("input");
        var $subcats = $("[class^=\"awesome_map-category-\"][data-parent=\"".concat(cat.parent, "\"]:visible"));
        var num_checked = $subcats.contents("input:checked").length;
        $input.prop("indeterminate", num_checked != $subcats.length && num_checked != 0);
      }
    } // order hashtags alphabetically

  }, {
    key: "_orderHashtags",
    value: function _orderHashtags(_hashtag, $div) {
      var $last = $div.contents("label:last");

      if ($last.prev("label").length) {
        // move the label to order it alphabetically
        $div.contents("label").each(function (_idx, el) {
          if ($(el).text().localeCompare($last.text()) > 0) {
            $(el).before($last);
            return false;
          }
        });
      }
    }
  }]);

  return ControlsUI;
}();



/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/load_map.js":
/*!***********************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/load_map.js ***!
  \***********************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var src_decidim_decidim_awesome_awesome_map_awesome_map__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! src/decidim/decidim_awesome/awesome_map/awesome_map */ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/decidim/decidim_awesome/awesome_map/awesome_map.js");

$(function () {
  var sanitizeCenter = function sanitizeCenter(string) {
    if (string) {
      var parts = string.split(",");

      if (parts.length >= 2) {
        var lat = parseFloat(parts[0]);
        var lng = parseFloat(parts[1]);

        if (lat && lng) {
          return [lat, lng];
        }
      }
    }
  };

  var config = {
    length: $("#awesome-map").data("truncate") || 254,
    center: sanitizeCenter($("#awesome-map").data("map-center")),
    zoom: $("#awesome-map").data("map-zoom"),
    menu: {
      amendments: $("#awesome-map").data("menu-amendments"),
      meetings: $("#awesome-map").data("menu-meetings"),
      categories: $("#awesome-map").data("menu-categories"),
      hashtags: $("#awesome-map").data("menu-hashtags"),
      mergeComponents: $("#awesome-map").data("menu-merge-components")
    },
    show: {
      withdrawn: $("#awesome-map").data("show-withdrawn"),
      accepted: $("#awesome-map").data("show-accepted"),
      evaluating: $("#awesome-map").data("show-evaluating"),
      notAnswered: $("#awesome-map").data("show-not-answered"),
      rejected: $("#awesome-map").data("show-rejected")
    },
    hideControls: $("#awesome-map").data("hide-controls"),
    collapsedMenu: $("#awesome-map").data("collapsed"),
    components: $("#awesome-map").data("components")
  }; // build awesome map (if exist)

  $("#awesome-map .google-map").on("ready.decidim", function (evt, map) {
    // bindPopup doesn't work for some unknown cause and these handler neither so we're cancelling them
    map.off("popupopen");
    map.off("popupclose"); // console.log("ready map", map);

    window.AwesomeMap = new src_decidim_decidim_awesome_awesome_map_awesome_map__WEBPACK_IMPORTED_MODULE_0__["default"](map, config);
    window.AwesomeMap.loadControllers();
  });
});

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/vendor/jquery.truncate.js":
/*!*************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/src/vendor/jquery.truncate.js ***!
  \*************************************************************************************************************************************/
/***/ (function() {

// From https://github.com/pathable/truncate/
(function ($) {
  // Matches trailing non-space characters.
  var chop = /(\s*\S+|\s)$/; // Matches the first word in the string.

  var start = /^(\S*)/; // Return a truncated html string.  Delegates to $.fn.truncate.

  $.truncate = function (html, options) {
    return $('<div></div>').append(html).truncate(options).html();
  }; // Truncate the contents of an element in place.


  $.fn.truncate = function (options) {
    if ($.isNumeric(options)) options = {
      length: options
    };
    var o = $.extend({}, $.truncate.defaults, options);
    return this.each(function () {
      var self = $(this);
      if (o.noBreaks) self.find('br').replaceWith(' ');
      var text = self.text();
      var excess = text.length - o.length;
      if (o.stripTags) self.text(text); // Chop off any partial words if appropriate.

      if (o.words && excess > 0) {
        var truncated = text.slice(0, o.length).replace(chop, '').length;

        if (o.keepFirstWord && truncated === 0) {
          excess = text.length - start.exec(text)[0].length - 1;
        } else {
          excess = text.length - truncated - 1;
        }
      }

      if (excess < 0 || !excess && !o.truncated) return; // Iterate over each child node in reverse, removing excess text.

      $.each(self.contents().get().reverse(), function (i, el) {
        var $el = $(el);
        var text = $el.text();
        var length = text.length; // If the text is longer than the excess, remove the node and continue.

        if (length <= excess) {
          o.truncated = true;
          excess -= length;
          $el.remove();
          return;
        } // Remove the excess text and append the ellipsis.


        if (el.nodeType === 3) {
          // should we finish the block anyway?
          if (o.finishBlock) {
            $(el.splitText(length)).replaceWith(o.ellipsis);
          } else {
            $(el.splitText(length - excess - 1)).replaceWith(o.ellipsis);
          }

          return false;
        } // Recursively truncate child nodes.


        $el.truncate($.extend(o, {
          length: length - excess
        }));
        return false;
      });
    });
  };

  $.truncate.defaults = {
    // Strip all html elements, leaving only plain text.
    stripTags: false,
    // Only truncate at word boundaries.
    words: false,
    // When 'words' is active, keeps the first word in the string
    // even if it's longer than a target length.
    keepFirstWord: false,
    // Replace instances of <br> with a single space.
    noBreaks: false,
    // if true always truncate the content at the end of the block.
    finishBlock: false,
    // The maximum length of the truncated html.
    length: Infinity,
    // The character to use as the ellipsis.  The word joiner (U+2060) can be
    // used to prevent a hanging ellipsis, but displays incorrectly in Chrome
    // on Windows 7.
    // http://code.google.com/p/chromium/issues/detail?id=68323
    ellipsis: "\u2026" // '\u2060\u2026'

  };
})(jQuery);

/***/ }),

/***/ "../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.scss":
/*!****************************************************************************************************************************************************!*\
  !*** ../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.scss ***!
  \****************************************************************************************************************************************************/
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
/******/ 			"decidim_decidim_awesome_map": 0
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
/******/ 	var __webpack_exports__ = __webpack_require__.O(undefined, ["vendors-node_modules_leaflet-svgicon_index_js-node_modules_leaflet_markercluster_dist_leaflet-b732f3","vendors-node_modules_jsrender_jsrender_js-node_modules_leaflet_featuregroup_subgroup_dist_lea-79fc92"], function() { return __webpack_require__("../../../.rbenv/versions/2.7.1/lib/ruby/gems/2.7.0/gems/decidim-decidim_awesome-0.8.1/app/packs/entrypoints/decidim_decidim_awesome_map.js"); })
/******/ 	__webpack_exports__ = __webpack_require__.O(__webpack_exports__);
/******/ 	
/******/ })()
;
//# sourceMappingURL=decidim_decidim_awesome_map.js.map