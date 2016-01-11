////////
// Author:     jc3
// Maintainer: jc3
// Created:    2005-01-31
// Toggle hide/show for navigation sidebar
//

function sidebar_off() {
  document.getElementById('sidebar').style.display = 'none';
  document.getElementById('main').className        = 'expanded';
  document.getElementById('nav_tab').src           = sidebar_images['show']; //'/gfx/show_nav.png';
  document.getElementById('nav_tab').title         = 'Show sidebar';
  document.getElementById('navblock').className    = 'collapsed';
  setCookie("hidden","1",null,null,".sanger.ac.uk",null);
}

function sidebar_on() {
  document.getElementById('sidebar').style.display = 'block';
  document.getElementById('main').className        = 'collapsed';
  document.getElementById('nav_tab').src           = sidebar_images['hide']; //'/gfx/hide_nav.png';
  document.getElementById('nav_tab').title         = 'Hide sidebar';
  document.getElementById('navblock').className    = 'expanded';
  setCookie("hidden","0",null,null,".sanger.ac.uk",null);
}

function toggle() {
  if (document.getElementById('sidebar').style.display == 'none'){
    sidebar_on();
  } else {
    sidebar_off();
  }  
}  

/* sidebar_default has been deprecated
   this functionality now needs to be performed in SiteDecor/<subclass>.pm, server-side */
function sidebar_default() {}

// set the Cookie
function setCookie(name,value,expires,path,domain,secure) {
  document.cookie = name + "=" +escape(value) +
  ( (expires) ? ";expires=" + expires.toGMTString() : "") +
   ";path=/" + 
  ( (domain) ? ";domain=" + domain : "") +
  ( (secure) ? ";secure" : "");
}

// grab the Cookie
function getCookie(name) {
  var start = document.cookie.indexOf(name+"=");
  var len   = start+name.length+1;
  if ((!start) && (name != document.cookie.substring(0,name.length))) return null;
  if (start == -1) return null;
  var end = document.cookie.indexOf(";",len);
  if (end == -1) end = document.cookie.length;
  return unescape(document.cookie.substring(len,end));
}

//addLoadEvent(sidebar_default);
