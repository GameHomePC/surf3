var App = (function(){

    var id = 'surf';
	
	var data = [{
		links: {
			background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/cocos.png'
		},
		id: 0
	},{
		links: {
			background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/hazelnut.png'
		},
		id: 1
	},{
		links: {
			background: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/background/max_fun.png'
		},
		id: 2
	}];
	
    var options = {
        flashvars: {
			images: JSON.stringify({
				data: data
			})
		},
        params: {
            menu: "false",
            scale: "noScale",
            allowFullscreen: "true",
            allowScriptAccess: "always",
            bgcolor: "",
            wmode: "direct"
        },
        attributes: {
            id: id,
            name: id
        }
    };

    var service = {};

    service.getMovie = function(name){
        var M$ =  navigator.appName.indexOf("Microsoft") !=- 1;
        return (M$ ? window : document)[name];
    };

    service.getOption = function(key){
        return options[key];
    };

    service.api = function(methodName, args){
        args = args || [];

        var movie = this.getMovie(id);
		
		try {
			movie[methodName].apply(null, args)
		} catch(err){}
    };

    return service;

})();

(function(){

    var flashvars = App.getOption('flashvars');
    var params = App.getOption('params');
    var attributes = App.getOption('attributes');
	var rand = Math.random() * 1000;
	
    swfobject.embedSWF("surf.swf?v=" + rand, "altContent", "640", "360", "10.0.0", "expressInstall.swf", flashvars, params, attributes, function(){
		var movie = App.getMovie('surf');
		var btn = document.getElementById('screen');
		
		btn.addEventListener('click', function(e){
			e.preventDefault();
			App.api('_createScreen');
		});

        // App.addDebug();
		
	});

})();

function _createScreen(data){
    var parse;
    try {
        parse = JSON.parse(data);

        if ('type' in parse){
            switch(parse.type){
                case 'complete':
                    var img_src = document.getElementById('img_src');
                    var img = document.getElementById('img');
                    img_src.innerHTML = parse.path;
                    img.src = parse.path;
                    break;
                default:
            }
        }

    } catch(err){}
}

function _detectImage(index){}