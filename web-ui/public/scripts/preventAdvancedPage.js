$("#advanced_page").click(function(){
    $("#black_screen").css("display", "block");
    $("#advanced_dialog").fadeIn(600);
});

$("#advanced_dialog_no_btn").click(function(){
    $("#advanced_dialog").hide(100);
    $("#black_screen").css("display", "none");
});