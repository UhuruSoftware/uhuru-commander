function showNetworking()
{
    $('#networking_btn').css("background-color", "#06242d");
    $('#cpi_btn').css("background-color", "#1B4D63");

    $('#networking_div').show();
    $('#cpi_div').hide();
}

function showCPI()
{
    $('#networking_btn').css("background-color", "#1B4D63");
    $('#cpi_btn').css("background-color", "#06242d");

    $('#networking_div').hide();
    $('#cpi_div').show();
}