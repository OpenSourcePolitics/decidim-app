!function(){var e,t={33165:function(e,t,n){"use strict";function i(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function o(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}var r=function(){function e(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};i(this,e),this.listSelector=t.listSelector,this.hideOnFirstSelector=t.hideOnFirstSelector,this.hideOnLastSelector=t.hideOnLastSelector,this.run()}var t,n,r;return t=e,(n=[{key:"run",value:function(){var e=$(this.listSelector),t=this.hideOnFirstSelector,n=this.hideOnLastSelector;if(1===e.length){var i=e.first();i.find(t).hide(),i.find(n).hide()}else e.each((function(i,o){o.id===e.first().attr("id")?($(o).find(t).hide(),$(o).find(n).show()):o.id===e.last().attr("id")?($(o).find(n).hide(),$(o).find(t).show()):($(o).find(n).show(),$(o).find(t).show())}))}}])&&o(t.prototype,n),r&&o(t,r),e}();function a(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function l(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}var d=function(){function e(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};a(this,e),this.listSelector=t.listSelector,this.labelSelector=t.labelSelector,this.onPositionComputed=t.onPositionComputed,this.run()}var t,n,i;return t=e,(n=[{key:"run",value:function(){var e=this;$(this.listSelector).each((function(t,n){var i=$(n).find(e.labelSelector),o=i.html();o.match(/#(\d+)/)?i.html(o.replace(/#(\d+)/,"#".concat(t+1))):i.html("".concat(o," #").concat(t+1)),e.onPositionComputed&&e.onPositionComputed(n,t)}))}}])&&l(t.prototype,n),i&&l(t,i),e}(),c=n(64112);var u=function e(t,n){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),$(t).length>0&&(0,c.Z)(t,n)[0].addEventListener("sortupdate",(function(e){var t=$(e.target).children();n.onSortUpdate&&n.onSortUpdate(t)}))};function s(e,t){return new u(e,t)}function f(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function h(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}var p=function(){function e(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};f(this,e),this.wrapperSelector=t.wrapperSelector,this.containerSelector=t.containerSelector,this.fieldSelector=t.fieldSelector,this.addFieldButtonSelector=t.addFieldButtonSelector,this.addSeparatorButtonSelector=t.addSeparatorButtonSelector,this.fieldTemplateSelector=t.fieldTemplateSelector,this.separatorTemplateSelector=t.separatorTemplateSelector,this.removeFieldButtonSelector=t.removeFieldButtonSelector,this.moveUpFieldButtonSelector=t.moveUpFieldButtonSelector,this.moveDownFieldButtonSelector=t.moveDownFieldButtonSelector,this.onAddField=t.onAddField,this.onRemoveField=t.onRemoveField,this.onMoveUpField=t.onMoveUpField,this.onMoveDownField=t.onMoveDownField,this.placeholderId=t.placeholderId,this.elementCounter=0,this._enableInterpolation(),this._activateFields(),this._bindEvents()}var t,n,i;return t=e,n=[{key:"_enableInterpolation",value:function(){$.fn.replaceAttribute=function(e,t,n){return $(this).find("[".concat(e,"*=").concat(t,"]")).addBack("[".concat(e,"*=").concat(t,"]")).each((function(i,o){$(o).attr(e,$(o).attr(e).replace(t,n))})),this},$.fn.template=function(e,t){var n=$(this).find("template, .decidim-template");n.length>0&&n.html((function(n,i){return $(i).template(e,t)[0].outerHTML}));var i=$(this).find("[data-template]");return i.length>0&&i.each((function(n,i){var o=$(i),r=$(o.data("template")),a=$(r[0].outerHTML),l="".concat(r.attr("id"),"-").concat(t),d="#".concat(l);a.attr("id",l),o.attr("data-template",d).data("template",d),r.after(a),a.html((function(n,i){return $(i).template(e,t)[0].outerHTML}))})),$(this).replaceAttribute("id",e,t),$(this).replaceAttribute("name",e,t),$(this).replaceAttribute("data-tabs-content",e,t),$(this).replaceAttribute("for",e,t),$(this).replaceAttribute("tabs_id",e,t),$(this).replaceAttribute("href",e,t),this}}},{key:"_bindEvents",value:function(){var e=this;$(this.wrapperSelector).on("click",this.addFieldButtonSelector,(function(t){return e._bindSafeEvent(t,(function(){return e._addField(e.fieldTemplateSelector)}))})),this.addSeparatorButtonSelector&&$(this.wrapperSelector).on("click",this.addSeparatorButtonSelector,(function(t){return e._bindSafeEvent(t,(function(){return e._addField(e.separatorTemplateSelector)}))})),$(this.wrapperSelector).on("click",this.removeFieldButtonSelector,(function(t){return e._bindSafeEvent(t,(function(t){return e._removeField(t)}))})),this.moveUpFieldButtonSelector&&$(this.wrapperSelector).on("click",this.moveUpFieldButtonSelector,(function(t){return e._bindSafeEvent(t,(function(t){return e._moveUpField(t)}))})),this.moveDownFieldButtonSelector&&$(this.wrapperSelector).on("click",this.moveDownFieldButtonSelector,(function(t){return e._bindSafeEvent(t,(function(t){return e._moveDownField(t)}))}))}},{key:"_bindSafeEvent",value:function(e,t){e.preventDefault(),e.stopPropagation();try{return t(e.target)}catch(n){return console.error(n),n}}},{key:"_addField",value:function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:".decidim-template",t=$(this.wrapperSelector),n=t.find(this.containerSelector),i=t.data("template"),o=null;i&&(o=$(i)),(null===o||o.length<1)&&(o=t.children("template, ".concat(e)));var r=$(o.html()).template(this.placeholderId,this._getUID());r.find("ul.tabs").attr("data-tabs",!0);var a=n.find(this.fieldSelector).last();a.length>0?a.after(r):r.appendTo(n),r.foundation(),this.onAddField&&this.onAddField(r)}},{key:"_removeField",value:function(e){var t=$(e).parents(this.fieldSelector);if(t.find("input").filter((function(e,t){return t.name.match(/id/)})).length>0){var n=t.find("input").filter((function(e,t){return t.name.match(/delete/)}));n.length>0&&$(n[0]).val(!0),t.addClass("hidden"),t.hide()}else t.remove();this.onRemoveField&&this.onRemoveField(t)}},{key:"_moveUpField",value:function(e){var t=$(e).parents(this.fieldSelector);t.prev().before(t),this.onMoveUpField&&this.onMoveUpField(t)}},{key:"_moveDownField",value:function(e){var t=$(e).parents(this.fieldSelector);t.next().after(t),this.onMoveDownField&&this.onMoveDownField(t)}},{key:"_activateFields",value:function(){var e=this,t=$(this.wrapperSelector).find(this.containerSelector);t.append(t.find("script")),$(this.fieldSelector).each((function(t,n){$(n).template(e.placeholderId,e._getUID()),$(n).find("ul.tabs").attr("data-tabs",!0)}))}},{key:"_getUID",value:function(){return this.elementCounter+=1,(new Date).getTime()+this.elementCounter}}],n&&h(t.prototype,n),i&&h(t,i),e}();function v(e){return new p(e)}var m=n(61246),g=".meeting-agenda-item",S=new d({listSelector:".meeting-agenda-item:not(.hidden)",labelSelector:".card-title span:first",onPositionComputed:function(e,t){$(e).find("input[name$=\\[position\\]]").val(t)}}),b=new r({listSelector:".meeting-agenda-item:not(.hidden)",hideOnFirstSelector:".move-up-agenda-item",hideOnLastSelector:".move-down-agenda-item"}),F=function(){s(".meeting-agenda-items-list:not(.published)",{handle:".agenda-item-divider",placeholder:'<div style="border-style: dashed; border-color: #000"></div>',forcePlaceholderSize:!0,onSortUpdate:function(){S.run()}})},_=new d({listSelector:".meeting-agenda-item-child:not(.hidden)",labelSelector:".card-title span:first",onPositionComputed:function(e,t){$(e).find("input[name$=\\[position\\]]").val(t)}}),w=new r({listSelector:".meeting-agenda-item-child:not(.hidden)",hideOnFirstSelector:".move-up-agenda-item-child",hideOnLastSelector:".move-down-agenda-item-child"}),y=function(e){return v({placeholderId:"meeting-agenda-item-child-id",wrapperSelector:"#".concat(e," ").concat(".meeting-agenda-item-childs"),containerSelector:".meeting-agenda-item-childs-list",fieldSelector:".meeting-agenda-item-child",addFieldButtonSelector:".add-agenda-item-child",removeFieldButtonSelector:".remove-agenda-item-child",moveUpFieldButtonSelector:".move-up-agenda-item-child",moveDownFieldButtonSelector:".move-down-agenda-item-child",onAddField:function(e){s(".meeting-agenda-item-childs-list:not(.published)",{handle:".agenda-item-child-divider",placeholder:'<div style="border-style: dashed; border-color: #000"></div>',forcePlaceholderSize:!0,onSortUpdate:function(){S.run()}}),e.find(".editor-container").each((function(e,t){(0,m.Z)(t)})),_.run(),w.run()},onRemoveField:function(){_.run(),w.run()},onMoveUpField:function(){_.run(),w.run()},onMoveDownField:function(){_.run(),w.run()}})},k={},B=function(e){var t=e.attr("id");k[t]=y(t)};v({placeholderId:"meeting-agenda-item-id",wrapperSelector:".meeting-agenda-items",containerSelector:".meeting-agenda-items-list",fieldSelector:g,addFieldButtonSelector:".add-agenda-item",removeFieldButtonSelector:".remove-agenda-item",moveUpFieldButtonSelector:".move-up-agenda-item",moveDownFieldButtonSelector:".move-down-agenda-item",onAddField:function(e){B(e),F(),e.find(".editor-container").each((function(e,t){(0,m.Z)(t)})),S.run(),b.run()},onRemoveField:function(){S.run(),b.run()},onMoveUpField:function(){S.run(),b.run()},onMoveDownField:function(){S.run(),b.run()}}),F(),$(g).each((function(e,t){var n=$(t);!function(e){"true"===e.find("input[name$=\\[deleted\\]]").val()&&(e.addClass("hidden"),e.hide())}(n),B(n)})),S.run(),b.run(),_.run(),w.run();n(49001);function I(e,t,n){var i="".concat(e,"Name");if(n[i])return n[i];var o=t.attr("name"),r=/\[[^\]]+\]$/;return o.match(r)?o.replace(r,"[".concat(e,"]")):e}function O(e,t,n){var i=$.extend({},t),o=e.attr("id").split("_");o.pop();var r="".concat(o.join("_")),a="latitude",l="longitude";e.length>0&&(a=I("latitude",e,i),l=I("longitude",e,i));var d=$.extend({latitudeId:"".concat(r,"_latitude"),longitudeId:"".concat(r,"_longitude"),latitudeName:a,longitudeName:l},t),c=!1,u=function(t){!function(){var t=$("#".concat(d.latitudeId));t.length<1&&(t=$('<input type="hidden" name="'.concat(d.latitudeName,'" id="').concat(d.latitudeId,'" />')),e.after(t));var n=$("#".concat(d.longitudeId));n.length<1&&(n=$('<input type="hidden" name="'.concat(d.longitudeName,'" id="').concat(d.longitudeId,'" />')),e.after(n))}(),$("#".concat(d.latitudeId)).val(t[0]).attr("value",t[0]),$("#".concat(d.longitudeId)).val(t[1]).attr("value",t[1])};e.on("change.decidim",(function(){c||($("#".concat(d.latitudeId)).val("").removeAttr("value"),$("#".concat(d.longitudeId)).val("").removeAttr("value"))})),e.on("geocoder-suggest-coordinates.decidim",(function(e,t){u(t),c=!0,n(t)}));var s="".concat(e.data("coordinates")).split(",").map(parseFloat);Array.isArray(s)&&2===s.length&&u(s)}$((function(){var e=".meeting-service",t=new d({listSelector:".meeting-service:not(.hidden)",labelSelector:".card-title span:first",onPositionComputed:function(e,t){$(e).find("input[name$=\\[position\\]]").val(t)}}),n=new r({listSelector:".meeting-service:not(.hidden)",hideOnFirstSelector:".move-up-service",hideOnLastSelector:".move-down-service"}),i=function(){s(".meeting-services-list:not(.published)",{handle:".service-divider",placeholder:'<div style="border-style: dashed; border-color: #000"></div>',forcePlaceholderSize:!0,onSortUpdate:function(){t.run()}})};v({placeholderId:"meeting-service-id",wrapperSelector:".meeting-services",containerSelector:".meeting-services-list",fieldSelector:e,addFieldButtonSelector:".add-service",removeFieldButtonSelector:".remove-service",moveUpFieldButtonSelector:".move-up-service",moveDownFieldButtonSelector:".move-down-service",onAddField:function(){i(),t.run(),n.run()},onRemoveField:function(){t.run(),n.run()},onMoveUpField:function(){t.run(),n.run()},onMoveDownField:function(){t.run(),n.run()}}),i(),$(e).each((function(e,t){!function(e){"true"===e.find("input[name$=\\[deleted\\]]").val()&&(e.addClass("hidden"),e.hide())}($(t))})),t.run(),n.run();var o=$(".edit_meeting, .new_meeting, .copy_meetings");if(o.length>0){var a=o.find("#private_meeting"),l=o.find("#transparent"),c=function(){var e=a.find("input[type='checkbox']").prop("checked");l.find("input[type='checkbox']").attr("disabled","disabled"),e&&l.find("input[type='checkbox']").attr("disabled",!e)};a.on("change",c),c(),O(o.find("#meeting_address"));var u=o.find("#meeting_registration_type"),f=o.find("#meeting_registration_terms"),h=o.find("#meeting_registration_url"),p=o.find("#meeting_available_slots"),m=function(e,t,n){var i=e.val();t.toggle(i===n)};u.on("change",(function(e){var t=$(e.target);m(t,p,"on_this_platform"),m(t,f,"on_this_platform"),m(t,h,"on_different_platform")})),u.trigger("change")}var g=$(".meetings_form");if(g.length>0){var S=g.find("#meeting_type_of_meeting"),b=g.find(".field[data-meeting-type='online']"),F=g.find(".field[data-meeting-type='in_person']"),_=function(e,t,n){var i=e.val();"hybrid"===i?t.show():(t.hide(),i===n&&t.show())};S.on("change",(function(e){var t=$(e.target);_(t,b,"online"),_(t,F,"in_person")})),_(S,b,"online"),_(S,F,"in_person")}}));n(33212);function C(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function U(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}var D=function(){function e(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};C(this,e),this.controllerField=t.controllerField,this.wrapperSelector=t.wrapperSelector,this.dependentFieldsSelector=t.dependentFieldsSelector,this.dependentInputSelector=t.dependentInputSelector,this.enablingCondition=t.enablingCondition,this._bindEvent(),this._run()}var t,n,i;return t=e,(n=[{key:"_run",value:function(){var e=this.controllerField,t=e.parents(this.wrapperSelector).find(this.dependentFieldsSelector),n=t.find(this.dependentInputSelector);this.enablingCondition(e)?(n.prop("disabled",!1),t.show()):(n.prop("disabled",!0),t.hide())}},{key:"_bindEvent",value:function(){var e=this;this.controllerField.on("change",(function(){e._run()}))}}])&&U(t.prototype,n),i&&U(t,i),e}();function A(e){return new D(e)}$((function(){var e=$('[name="meeting_registration_invite[existing_user]"');A({controllerField:e,wrapperSelector:".attendee-fields",dependentFieldsSelector:".attendee-fields--new-user",dependentInputSelector:"input",enablingCondition:function(){return $("#meeting_registration_invite_existing_user_false").is(":checked")}}),A({controllerField:e,wrapperSelector:".attendee-fields",dependentFieldsSelector:".attendee-fields--user-picker",dependentInputSelector:"input",enablingCondition:function(){return $("#meeting_registration_invite_existing_user_true").is(":checked")}})}))},49001:function(){$((function(){var e=$(".destroy-meeting-alert");e.length>0&&e.on("click",(function(){var t="".concat(e.data("invalid-destroy-message")," \n\n");t+=e.data("proposal-titles").replace(/\n\s/g,"\n"),alert(t)}))}))},33212:function(){$((function(){var e=$(".edit_meeting_registrations");if(e.length>0){var t=e.find("#meeting_registrations_enabled"),n=e.find("#meeting_available_slots"),i=e.find("#meeting_reserved_slots"),o=function(){var o=t.prop("checked");n.attr("disabled",!o),i.attr("disabled",!o),e.find(".editor-container").each((function(e,t){Quill.find(t).enable(o)}))};t.on("change",o),o()}}))}},n={};function i(e){var o=n[e];if(void 0!==o)return o.exports;var r=n[e]={exports:{}};return t[e](r,r.exports,i),r.exports}i.m=t,e=[],i.O=function(t,n,o,r){if(!n){var a=1/0;for(u=0;u<e.length;u++){n=e[u][0],o=e[u][1],r=e[u][2];for(var l=!0,d=0;d<n.length;d++)(!1&r||a>=r)&&Object.keys(i.O).every((function(e){return i.O[e](n[d])}))?n.splice(d--,1):(l=!1,r<a&&(a=r));if(l){e.splice(u--,1);var c=o();void 0!==c&&(t=c)}}return t}r=r||0;for(var u=e.length;u>0&&e[u-1][2]>r;u--)e[u]=e[u-1];e[u]=[n,o,r]},i.d=function(e,t){for(var n in t)i.o(t,n)&&!i.o(e,n)&&Object.defineProperty(e,n,{enumerable:!0,get:t[n]})},i.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},function(){var e={597:0};i.O.j=function(t){return 0===e[t]};var t=function(t,n){var o,r,a=n[0],l=n[1],d=n[2],c=0;if(a.some((function(t){return 0!==e[t]}))){for(o in l)i.o(l,o)&&(i.m[o]=l[o]);if(d)var u=d(i)}for(t&&t(n);c<a.length;c++)r=a[c],i.o(e,r)&&e[r]&&e[r][0](),e[a[c]]=0;return i.O(u)},n=self.webpackChunkapp=self.webpackChunkapp||[];n.forEach(t.bind(null,0)),n.push=t.bind(null,n.push.bind(n))}();var o=i.O(void 0,[112,335],(function(){return i(33165)}));o=i.O(o)}();
//# sourceMappingURL=decidim_meetings_admin-3670c42f26b54b96be1f.js.map