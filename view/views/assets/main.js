
$(document).foundation();

//$('body').click(function(){
//	console.log('hello world');
//});

// form effect
$('.form .submit a').click(function(){
	$(this).each(function(){
		var val = $(this).attr('value');
		$(this).parents('.submit').find('.submit-value').val(val);
		$(this).parents('.form').submit();
	});
});
