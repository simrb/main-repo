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

function ly_show_msg(data) {
	$('#msg').text(data);
	setTimeout(function(){ $('#msg').text(''); }, 3000);
}

function ly_insert_to_textarea(opt) {
	var textarea = $('.ly-et-textarea').data('textarea');
	var before = opt.before != undefined ? opt.before : '';
	var after = opt.after != undefined ? opt.after : '';
	var replace = opt.replace != undefined ? opt.replace : '';

	if (opt.html_type == 'img') {
		replace = '![' + opt.img_name + '](' + opt.img_link + ')';
	}

	if (before != '' || after != '' || replace != '') {
		var len = textarea.val().length;
		var start = textarea[0].selectionStart;
		var end = textarea[0].selectionEnd;
		var select_text = replace != '' ? replace : textarea.val().substring(start, end);
		var replace_text = before + select_text + after;
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
						{name : 'file', icon : 'picture', event : 'create_event_file'},
					]
				}, options);

				$(this).ly_editor('setup', config);
			});
		},

		setup : function(config) {
			return this.each(function(){

				//select the textarea to update rich text editor
				var textarea = $(this);
				textarea.wrap('<div class="ly-et-textarea" style="clear:both;" />');

				//add a toolbar to editor
				$('.ly-et-textarea').before('<div class="ly-et-toolbar" />');

				//initialize the toolbar
				var toolbar = "";
				$.each(config.toolbar, function(index, item){

					//set the toolbar index, attr, class, title, key ...
					//event listener need to get the value from json with this index
					toolbar += '<a index="' + index + '"';

					if (item.key != undefined) {
						toolbar += ' accessKey="' + item.key + '"';
					}
					if (item.title != undefined) {
						toolbar += ' title="' + item.title + '"';
					} else {
						toolbar += ' title="' + item.name + '"';
					}

					toolbar += ' class="ly-et-tb-' + item.name;
					if (item.class != undefined) {
						toolbar += ' ' + item.class;
					}

					// icon png
					var icon_url = item.icon == undefined ? item.name : item.icon
					toolbar += '" style="background-image:url(' + config.icon_path + icon_url + '.png)"'

					// given name
					toolbar += '>' + item.name + '</a>';

					// append the separator
					if (item.separator != undefined) {
						toolbar += '<a style="background-image:url(' + config.icon_path + 'separator.png)">' + item.separator + '</a>';
					}

				});

				//setup the toolbar
				$('.ly-et-toolbar').append(toolbar);
				$('.ly-et-textarea').data('textarea', textarea);
				$('.ly-et-textarea').data('config', config);
				$(this).ly_editor('create_event', config);

			});
		},

		// setup the default event for each item of toolbar
		create_event : function(config) {
			return $(this).each(function(){
				$.each(config.toolbar, function(index, item){

					if (item.event == undefined) {
						$('.ly-et-toolbar .ly-et-tb-' + item.name).click(function(){
							ly_insert_to_textarea(item);
						});
					} else if (item.event == 'create_event_file') {
						$('.ly-et-toolbar .ly-et-tb-' + item.name).ly_editor('create_event_file', config);
					}

				});
			});
		},

		// create file event
		create_event_file : function(config) {
			return $(this).each(function(){

				var fileHtml = '';
				fileHtml += '<span class="ly-et-file-close right">X</span><div class="ly-et-file-list"/>';
				fileHtml += '<div class="ly-et-file-upload">';
				fileHtml += '<form class="ly-et-file-form"><input type="file" name="upload" />';
				fileHtml += '<button class="ly-et-file-submit tiny">upload</button>';
				fileHtml += '<div class="ly-et-file-progressbar"><div class="ly-et-file-subprogressbar" /></div>';
				fileHtml += '</form></div>';
				fileHtml = '<div class="ly-et-file">' + fileHtml + '</div>';

				$('.ly-et-toolbar').after(fileHtml);
				$('.ly-et-textarea').data('file_loaded', false);

				//add event
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

				$('.ly-et-file-submit').click(function(){
					//$(this).ly_editor('file_upload', config);
				});

				$('.ly-et-file-close').click(function(){
					$('.ly-et-file').hide();
				});

			});
		},

		// load the file
		file_view : function(config) {
			return $(this).each(function(){
				if($('.ly-et-textarea').data('file_loaded') == false) {
					$.getJSON(config.picture_path, function(data){
						//console.log("work 1");

						if ($.isEmptyObject(data)) {
							$('.ly-et-file-list').html('no data');
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
					$('.editor').data('file_loaded', true);
				}
			});
		},

		// upload file
		file_upload : function(config) {
			return $(this).each(function(){

				//folder item event
				var create_folder_menu = false;
				$('.folder').click(function(){

					if (create_folder_menu === true) {
						$('.ly-et-file-submit').show();
					} else {

						//initialize folder dropmenu
						//$(this).after(folder);
						//var folder_menu = $('.ly-et-file-upload');
						//folder_menu.css('top', $(this).offset().top + 15);
						//folder_menu.css('left', $(this).offset().left);

						//add changed event
						$('.ly-et-file-form').change(function(){
							$('.ly-et-file-subprogressbar').text('0 %');
							$('.ly-et-file-subprogressbar').css('background-color', '');
						});

						//add view event
						$('.editor').data('file_loaded', false);
						$(this).ly_editor('file_view', config);

						//add validation function to form
						var ly_upload_validation_error = '';
						$('.ly-et-file-form :file').change(function(){
							var file = this.files[0];
							if ($.inArray(file.type, config.file_type) == -1) {
								ly_upload_validation_error = 'the file must be (' + config.file_type.join(',') + '), but rather is ' + file.type;
							}
							if (file.size > config.file_size) {
								ly_upload_validation_error = 'The file size ' + file.size + ' is not better than ' + config.file_size;
							}
						});

						//add uploading event
						$('.ly-et-file-submit').click(function(){
							if (ly_upload_validation_error != '') {
								ly_show_msg(ly_upload_validation_error);
								return false;
							}

							var formData = new FormData($('.ly-et-file-form')[0]);

							$.ajax({

								url : config.upload_path,
								type : 'post',

								xhr : function() {
									myxhr = $.ajaxSettings.xhr();
									if (myxhr.upload) {
										myxhr.upload.addEventListener('progress', function(e){
											var done = e.position || e.loaded, total = e.totalSize || e.total;
											var progressbar = 'uploading ... ' + (Math.floor(done/total*1000)/10) + ' %';
											$('.ly-et-file-subprogressbar').text(progressbar);
										}, false);
									}
									return myxhr;
								},

								success : function(data) {
									//update progressbar
									$('.ly-et-file-subprogressbar').text('100 %');
									$('.ly-et-file-subprogressbar').css('background-color', 'yellow');

									//show message
									ly_show_msg(data);

									//update folder view
									$('.editor').data('file_loaded', false);
									$(this).ly_editor('file_view', config);
								},

								error : function(xhr, status, err) {
									console.log(xhr.responseText);
									console.log(status);
									console.log(err);
								},

								data : formData,
								cache : false,
								contentType : false,
								processData : false

							}, 'join');

							return false;

						});
						create_folder_menu = true;
						//initialize folder dropmenu ---- end
					}

				});

			///-- setup complete

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

