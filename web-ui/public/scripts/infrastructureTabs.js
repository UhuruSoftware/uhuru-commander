function showNetworking()
{
    $('#networking_btn').css("background-color", "#000000");
    $('#cpi_btn').css("background-color", "#183052");

    $('#networking_div').show();
    $('#cpi_div').hide();
}

function showCPI()
{
    $('#networking_btn').css("background-color", "#183052");
    $('#cpi_btn').css("background-color", "#000000");

    $('#networking_div').hide();
    $('#cpi_div').show();
}


//$('#networking_btn').hover(function(){
//    $(this).css("background-color", "#366EBC");
//}, function(){
//    if ($('#cpi_div:not(:visible)'))
//    {
//        $(this).css("background-color", "#000000");
//    }
//    else
//    {
//        $(this).css("background-color", "#183052");
//    }
//});