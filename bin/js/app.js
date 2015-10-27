var App = (function(){

    var id = 'surf';

    /* обложки для трёх типов, можно менять картинки для наложения на видео */
	var data = [{
		links: {
			background: 'assets/background/cocos-new.png'
		},
		id: 0
	},{
		links: {
			background: 'assets/background/hazelnut-new.png'
		},
		id: 1
	},{
		links: {
			background: 'assets/background/max_fun-new.png'
		},
		id: 2
	}];

    /* создание флеш на странице */
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
	var debug = true;
    var flashvars = App.getOption('flashvars');
    var params = App.getOption('params');
    var attributes = App.getOption('attributes');
	var rand = (debug) ? (Math.random() * 1000) : 1;
	
    swfobject.embedSWF("surf.swf?v=" + rand, "altContent", "594", "450", "10.0.0", "expressInstall.swf", flashvars, params, attributes, function(){
		var movie = App.getMovie('surf');
		var btn = document.getElementById('screen');
		
		btn.addEventListener('click', function(e){
			e.preventDefault();
			App.api('_createScreen');
		});
	});
})();

/* основные функциии */
/* делает скрин */
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

/*
    определяет три типа, аргумент index возвращает нужные данные для дальнейшей манипуляции, весь коде пишется внутри
*/
function _detectImage(index){

}

/*
	определяет установлена ли камера на компьютере, если нет камеры то будет вызвана эта функция
*/
function _cameraError(err){
	console.log(err);
}