/*
 * == Example
 *
 * html
 * 		input class="ly_editor" type="textarea"
 *
 * js
 * 		== _js("view/js/editor.js")
 *
 * css
 *		== _css("view/css/editor.css")
 *
 */

function ly_insert_to_textarea(opt) {
	var textarea	= $('.ly-et-textarea').data('textarea');
	var before		= opt.before != undefined ? opt.before : '';
	var after 		= opt.after != undefined ? opt.after : '';
	var replace 	= opt.replace != undefined ? opt.replace : '';

	if (opt.html_type == 'img') {
		replace = '![' + opt.img_name + '](' + opt.img_link + ')';
	}

	if (before != '' || after != '' || replace != '') {
		var len 			= textarea.val().length;
		var start 			= textarea[0].selectionStart;
		var end 			= textarea[0].selectionEnd;
		var select_text		= replace != '' ? replace : textarea.val().substring(start, end);
		var replace_text	= before + select_text + after;
		textarea.val(textarea.val().substring(0, start) + replace_text + textarea.val().substring(end, len));
	}
}

(function($){
	var methods = {
		init : function(options) {
			return this.each(function(){
				var config = $.extend({
					parser_path 	: '/file/preview',
					folder_path 	: '/file/type/all',
					picture_path 	: '/file/type/image',
					upload_path 	: '/file/upload',
					icon_path 		: '/_assets/view/icons/',
					file_path 		: '/file/get/',
					file_type 		: ['image/jpeg', 'image/gif', 'image/png'],
					file_size 		: 300000,
					toolbar 		: [
						{name : 'h1', key : '1', before : '# ', title :'Header 1'},
						{name : 'h2', key : '2', before : '## ', title :'Header 2'},
						{name : 'h3', key : '3', before : '### ', title :'Header 3', separator : '|'},

						{name : 'bold', key : 'B', before : '**', after : '**'},
						{name : 'italic', key : 'I', before : "_", after : "_", separator : '|'},

						{name : 'ol', before : '+ '},
						{name : 'ul', before : '- ', separator : '|'},

						{name : 'quotes', before : '-------\n', after : '\n-------\n'},
						{name : 'code', before : '```\n', after : '\n```', separator : '|'},

						{name : 'link', key : 'L', before : '[name]', after : '(link)'},
						{name : 'file', icon : 'picture', event : 'file_event'},
					]
				}, options);

				$(this).ly_editor('setup', config);
			});
		},

		setup : function(config) {
			return this.each(function(){

				// select the textarea to update richtext editor
				var textarea = $(this);
				textarea.wrap('<div class="ly-et-textarea" />');

				// add a toolbar to editor
				$('.ly-et-textarea').before('<div class="ly-et-toolbar" />');

				// initialize the toolbar
				var toolbarHtml = "";
				$.each(config.toolbar, function(index, item){

					//set the toolbar index, attr, class, title, key ...
					//event listener need to get the value from json with this index
					toolbarHtml += '<a index="' + index + '"';

					if (item.key != undefined) {
						toolbarHtml += ' accessKey="' + item.key + '"';
					}
					if (item.title != undefined) {
						toolbarHtml += ' title="' + item.title + '"';
					} else {
						toolbarHtml += ' title="' + item.name + '"';
					}

					toolbarHtml += ' class="ly-et-tb-' + item.name;
					if (item.class != undefined) {
						toolbarHtml += ' ' + item.class;
					}

					// icon png
					var icon_url = item.icon == undefined ? item.name : item.icon
					toolbarHtml += '" style="background-image:url(' + config.icon_path + icon_url + '.png)"'

					// given name
					toolbarHtml += '>' + item.name + '</a>';

					// append the separator
					if (item.separator != undefined) {
						toolbarHtml += '<a style="background-image:url(' + config.icon_path + 'separator.png)">' + item.separator + '</a>';
					}

				});

				// setup the toolbar
				$('.ly-et-toolbar').append(toolbarHtml);
				$('.ly-et-textarea').data('textarea', textarea);
				//$('.ly-et-textarea').data('config', config);

				// setup events for each item of toolbar function
				$.each(config.toolbar, function(index, item){
					if (item.event == undefined) {
						$('.ly-et-toolbar .ly-et-tb-' + item.name).click(function(){
							ly_insert_to_textarea(item);
						});
					} else {
						$('.ly-et-toolbar .ly-et-tb-' + item.name).ly_editor(item.event, config);
					}
				});

			});
		},

		// create file event
		file_event : function(config) {
			return $(this).each(function(){

				// generate html
				var fileHtml = '';
				fileHtml += '<span class="ly-et-file-close right">X</span><div class="ly-et-file-list"/>';
				fileHtml += '<form class="ly-et-file-form"><input type="file" name="upload" />';
				fileHtml += '<button class="ly-et-file-submit tiny">upload</button>';
				fileHtml += '<progress value=0 max=100 class="ly-et-file-progress hide" />';
				fileHtml += '<div class="ly-et-file-msg" />';
				fileHtml += '</form>';
				fileHtml = '<div class="ly-et-file">' + fileHtml + '</div>';

				$('.ly-et-toolbar').after(fileHtml);
				$('.ly-et-file').data('file_loaded', false);
				$('.ly-et-file').data('file_error', false);

				// add event
				$('.ly-et-tb-file').mouseenter(function(){
					//$('.ly-et-file').show();
					//$(this).ly_editor('file_view', config);
				});

				$('.ly-et-file').mouseleave(function(){
					//$('.ly-et-file').hide();
				});

				$('.ly-et-tb-file').click(function(){
					$('.ly-et-file').toggle();
					$(this).ly_editor('file_view', config);
				});

				$('.ly-et-file-close').click(function(){
					$('.ly-et-file').hide();
				});

				$('.ly-et-file-submit').click(function(){
					if ($('.ly-et-file').data('file_error') == false) {
						$(this).ly_editor('file_upload', config);
					}
					return false;
				});

				// listen the form
				$('.ly-et-file-form :file').change(function(){
					//console.log('file added');

					var file = this.files[0];
					var error_msg = '';
					$('.ly-et-file-progress').val(0);
					$('.ly-et-file-msg').text('');

					// validate the file
					if ($.inArray(file.type, config.file_type) == -1) {
						error_msg = 'file type must be ' + config.file_type.join(',') + '), not ' + file.type;
					}
					if (file.size > config.file_size) {
						error_msg = 'file size ' + file.size + ' need lower than ' + config.file_size + ' bytes';
					}

					if (error_msg == '') {
						$('.ly-et-file-msg').text('correct file');
						$('.ly-et-file').data('file_error', false);
					} else {
						$('.ly-et-file-msg').text(error_msg);
						$('.ly-et-file').data('file_error', true);
					}
				});

			});
		},

		// view file for loading from remote
		file_view : function(config) {
			return $(this).each(function(){
				if($('.ly-et-file').data('file_loaded') == false) {
					$.getJSON(config.picture_path, function(data){
						//console.log("work 1");

						if ($.isEmptyObject(data)) {
							$('.ly-et-file-msg').html('no data');
						} else {
							var datas = [];
							$.each(data, function(index, item){
								var type = item.type.split('/')
								datas.push('<li><img src="' + config.file_path + item.fnum + '" alt="' + item.name + '" title="' + item.name + '"  /></li>');
							});
							$('.ly-et-file-list').html('<ul>' + datas.join('') + '</ul>');
							$('.ly-et-file-list li img').click(function(){
								ly_insert_to_textarea({html_type : 'img', img_link : $(this).attr('src'), img_name : $(this).attr('alt')});
							});
						}

					});
					$('.ly-et-file').data('file_loaded', true);
				}
			});
		},

		// upload file
		file_upload : function(config) {
			return $(this).each(function(){
				//console.log('01 submit ...');
				var formData = new FormData($('.ly-et-file-form')[0]);
				$('.ly-et-file-progress').show();

				$.ajax({
					url 		: config.upload_path,
					type 		: 'post',
					data		: formData,
					cache		: false,
					contentType : false,
					processData : false,

					xhr 		: function() {
						var xhr = $.ajaxSettings.xhr();
						xhr.upload.onprogress = function(e){ 
							//console.log('progress', e.loaded/e.total*100);
							$('.ly-et-file-progress').val(e.loaded/e.total*100);
						};
						//xhr.upload.onload = function(){ console.log('DONE!') };
						return xhr;
					},

					success		: function(data) {
						// set progressbar
						$('.ly-et-file-msg').text('successful uploaded');

						// update file view
						$('.ly-et-file').data('file_loaded', false);
						$(this).ly_editor('file_view', config);
					},

					error		: function(xhr, status, err) {
						$('.ly-et-file-msg').text('uploaded failure');
						console.log(xhr.responseText);
						console.log(status);
						console.log(err);
					}
				}, 'join');

				//$('.ly-et-file-progress').hide();

			///-- end of function
			});
		},

	
	};


	$.fn.ly_editor = function(method) {
		if (methods[method]) {
			return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if (typeof method === 'object' || ! method) {
			return methods.init.apply(this, arguments);
		} else {
			$.error('Method ' + method + ' does not exist on plugins of jQeury');
		}
	};
})(jQuery);

// auto inject the js link
$('.ly_editor').ly_editor();

