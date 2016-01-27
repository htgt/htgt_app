// THIS FILE SHOULD BE DYNAMICALLY RE-WRITTEN from -tmpl 
// Z-tooltip version 2.1
// rmp@psyphi.net May 2000
// Modifications by jc3
var safPattern = /safari/i;

var NS6 = (!document.all && document.getElementById)? 1:0;
var NS4 = (document.layers) ? 1:0;
var IE4 = (document.all) ? 1:0;
var SAF = (safPattern.test(navigator.userAgent)) ? 1:0;

/*  if(NS4) {
    alert("you appear to be using netscape 4");
  }
  if(NS6) {
    alert("you appear to be using netscape 6");
  }
  if(IE4) {
    alert("you appear to be using IE4 or similar");
  }
  if(SAF) {
    alert("you appear to be using safari or similar");
  }*/

var divname = "jstooldiv";
var x = 0;
var y = 0;
var window_width        = 800;
var timeoutId = 0;
var Z_MENU_XOFFSET	= 2;
var Z_MENU_YOFFSET	= 2;
var Z_MENU_CAPTIONBG	= "#e2e2ff";
var Z_MENU_CAPTIONFG	= "#000000";
var Z_MENU_TIPBG	= "#ffffff";
var Z_MENU_BORDERBG	= "#aaaaaa";
var Z_MENU		= true;
var Z_MENU_WIDTH	= 150;

//var Z_MENU_TIMEIN       = 500;
//var Z_MENU_TIMEOUT      = 6000;
var Z_MENU_TIMEIN       = 100;
var Z_MENU_TIMEOUT      = 10000;

if(NS4 || IE4 || NS6) {
  document.onmousemove = mouseMove;

  if(NS4) { // not for NS6 anymore should be replaced with element.addEventListener
    document.captureEvents(Event.MOUSEMOVE);
    window_width = window.innerWidth;
  }
}

function mouseMove(e) {
  if(SAF) {
    x = e.clientX +Z_MENU_XOFFSET + window.pageXOffset - document.body.scrollLeft;
    y = e.clientY +Z_MENU_YOFFSET + window.pageYOffset - document.body.scrollTop;
  } else if(NS4) {
    x = e.pageX +Z_MENU_XOFFSET;
    y = e.pageY +Z_MENU_YOFFSET;
  } else if(IE4) {
    x = event.clientX +Z_MENU_XOFFSET + document.documentElement.scrollLeft;
    y = event.clientY +Z_MENU_YOFFSET + document.documentElement.scrollTop;
  } else if(NS6) {
    x = e.clientX +Z_MENU_XOFFSET + window.pageXOffset;
    y = e.clientY +Z_MENU_YOFFSET + window.pageYOffset;
  }  
}
                                                                                

function zmenu() {
    if(!document.getElementById(divname)){
      var menu = document.createElement('div');
      menu.setAttribute("id",divname);
      document.body.appendChild(menu);
    }

    zmenuoff();

    
    var txt = "";

    if(arguments.length < 1) { 
      return true;
    } else if(arguments.length % 2 != 1) {
	return true;
    }

    txt += '<div id="title" style="position:relative;top:0;left:0;padding:0;margin:0;">'+
    '<table border="0" cellpadding="0" cellspacing="0" id="zmenu">'+
    '<tr><td><dl class="menu_container">'+
    '<dt><a href="javascript:void(zmenuoff());" onmouseover="window.status=\'\';return true;"><p>'+arguments[0]+'<img src="/blank.gif" height="1" width="20" border="0"></p></a></dt>';

    for(var i = 1; i < arguments.length; i+=2) {
	var link = "";
        var url  = arguments[i];
	if(url != "") {
          var target = '';
          if(url.substr(0,1)=='@') {
            url = url.substr(1);
            target = ' target="_blank"';
          }
	  link = '<a href="'+url+'"'+target+'>'+arguments[i+1]+'</a>';
	} 
        else {
	  link = arguments[i+1];
	}

        if (i == 1){
           txt += '<dd id="first_shadow">'+link+'</dd>';
        } else {   
	   txt += '<dd>'+link+'</dd>';
        }   
    }
    
    txt += '</dl></td></tr></table></div>';

    if(NS4) {
	l = document.layers[divname];
	l.document.open("text/html");
	l.document.write(txt);
	l.document.close();
	l.left			= x;
	l.top			= y;
        
    } else if(IE4) {
	l = document.all[divname];
	l.innerHTML		= txt;
	l.style.pixelLeft	= x;
	l.style.pixelTop	= y;

    } else if(NS6) {
        var l = document.getElementById(divname);

	var rng = document.createRange();
	rng.setStartBefore(l);
	var htmlFrag = rng.createContextualFragment(txt);

	while (l.hasChildNodes()) {
	    l.removeChild(l.lastChild);
	}
	l.appendChild(htmlFrag);

	l.style.border		= 1;
	l.style.backgroundColor	= Z_MENU_TIPBG;
        l.style.left            = x + 'px';
        l.style.top             = y + 'px';
        l.style.position        = 'absolute';
    }
    window.clearTimeout(timeoutId);
    timeoutId = window.setTimeout('zmenuon_now()', Z_MENU_TIMEIN);
    return true;
}

/*

function hw( species, page, part ) {
  X=window.open( '/'+species+'/helpview?se=1&kw='+page+'#'+part,'helpview','height=400,width=500,left=100,screenX=100,top=100,screenY=100,resizable,scrollbars=yes');
  X.focus()
}

function zz( script, chr, centre, size, zoom, extra ) {
  L = chr + ":" +Math.floor(centre-size/2)+"-"+Math.floor(centre+size/2);
  zmenu('Navigation',
    script+"?l="+L+extra+"&zoom_width="+Math.ceil(zoom/2),  "Zoom in (x2)",
    script+"?l="+L+extra+"&zoom_width="+Math.ceil(zoom),    "Centre on this scale interval",
    script+"?l="+L+extra+"&zoom_width="+Math.ceil(zoom*2),  "Zoom out (x0.5)"
  );
}

function zn( script, chr, centre, size, extra ) {
  zmenu('Navigation',
    script+"?l="+chr+":"+Math.floor(centre-size/10)+"-"+Math.ceil(1*centre+(size/10))+extra,  "Zoom in (x10)",
    script+"?l="+chr+":"+Math.floor(centre-size/ 5)+"-"+Math.ceil(1*centre+(size/5 ))+extra,  "Zoom in (x5)",
    script+"?l="+chr+":"+Math.floor(centre-size/ 2)+"-"+Math.ceil(1*centre+(size/2 ))+extra,  "Zoom in (x2)",
    script+"?l="+chr+":"+Math.floor(centre-size* 1)+"-"+Math.ceil(1*centre+(size/1 ))+extra,  "Centre on this scale interval",
    script+"?l="+chr+":"+Math.floor(centre-size* 2)+"-"+Math.ceil(1*centre+(size*2 ))+extra,  "Zoom out (x0.5)",
    script+"?l="+chr+":"+Math.floor(centre-size* 5)+"-"+Math.ceil(1*centre+(size*5 ))+extra,  "Zoom out (x0.2)",
    script+"?l="+chr+":"+Math.floor(centre-size*10)+"-"+Math.ceil(1*centre+(size*10))+extra,  "Zoom out (x0.1)"
  );
}
*/

function zmenuon_now() {
       if(NS4) { var l = document.layers[divname];         l.visibility       = "show";} 
  else if(IE4) { var l = document.all[divname];            l.style.visibility = "visible";}
  else if(NS6) { var l = document.getElementById(divname); l.style.visibility = "visible";}
  window.clearTimeout(timeoutId);
  timeoutId = window.setTimeout('zmenuoff()', Z_MENU_TIMEOUT);
  return true;
}

function zmenuoff() {
       if(NS4) { document.layers[divname].visibility = "hide";} 
  else if(IE4) { document.all[divname].style.visibility = "hidden";}
  else if(NS6) { document.getElementById(divname).style.visibility = "hidden";}
}
