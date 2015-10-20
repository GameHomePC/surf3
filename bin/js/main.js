var App = (function(){

    var id = 'surf';
	
	var data = [{
		url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/boy.jpg',
		name: 'boy'
	},{
		url: 'http://c2364.paas2.ams.modxcloud.com/assets/as3/webx/assets/markers/checks.png',
		name: 'checks'
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
            wmode: "direct" // can cause issues with FP settings & webcam
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
        movie[methodName].apply(null, args)
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
		
	});

})();

function _createScreen(data){
    console.log(data);
}

function _detectImage(data){
	console.log(data);
}

function _debug(name){
	console.log(name);
}