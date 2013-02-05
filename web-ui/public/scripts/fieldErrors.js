$('.error').focus(function(){
    var value = $(this).val();
    $(this).css("color", "#f2f2f2");
    $(this).css("border", "2px solid red");
    $(this).focusout(function(){
        if(value != $(this).val())
        {
            $(this).css("border", "2px solid #dddddd");
            $(this).css("background-color", "transparent");
            $(this).css("color", "#f2f2f2");
        }
        else
        {
        }
    });
});