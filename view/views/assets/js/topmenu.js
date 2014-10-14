/* 
 * this is a menu that always keep itself on top of page
 *
 * == Example
 *
 * html 
 * 		#header.keeptop
 *			p note that the css of #header need to set by {position: absolute; top: 0;}
 *			p and the #toTop color set by { background: "colorwhatyouwant"; }
 *
 * js
 * 		== _js('view/js/topmenu.js')
 *
 */

var totop_png = "/_assets/view/images/totop.png"

$(".keeptop").before("<div id='toTop'><img src='" + totop_png + "'/></div>")
$("#toTop").css({
	"position" : "fixed",
	"bottom" : "5px",
	"right" : "5px",
	"display" : "none",
	"width" : "36px",
	"height" : "36px",
	"border-radius" : "6px",
	"cursor" : "pointer"
})

$("#toTop").click(function() {
	$('html, body').animate({scrollTop:0}, 100)
	return false;
});

$(window).scroll(function() {
    var aTop = $('.keeptop').height() - 10
    if($(this).scrollTop() > aTop){
		$('.keeptop').css('position', 'fixed')
		$('.keeptop').css('top', '0')
    }

    if ($(this).scrollTop()) {
        $('#toTop').fadeIn()
    } else {
        $('#toTop').fadeOut()
    }
});

/* 
 * this is a dropdown menu
 *
 * == Example
 *
 * html
 * 		ul
 * 			li menu itme
 * 			li menu itme
 * 			li.dropdownitem this is a dropdown menu
 * 				ul.hide.dropdownlist
 * 					li sub menu
 * 					li sub menu
 *
 * js
 * 		== _js("view/js/dropdown")
 *
 */

$(".dropdownitem").mouseover(function(){
	$hide = $(this).find('.dropdownlist')
	$hide.css('position', 'absolute')
	$hide.css('top', 29)
	$hide.css('left', $(this).offset().left - 10)
	$hide.show()
})

$(".dropdownitem").mouseleave(function(){
//}, function(){
	$hide = $(this).find('.dropdownlist')
	$hide.hide()
})

