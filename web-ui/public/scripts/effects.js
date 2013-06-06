var color_changer;

function randomValue(newVersions)
{
    if(newVersions == true)
    {
        changecolors();
    }
}


function changecolors() {
    color_changer = 1;
    setInterval(change, 1000);
}

function change() {
    if(color_changer == 1) {
        color = "#0A3660";
        border = "#033E6B";
        color_changer = 2;
    } else {
        color = "#13A12C";
        border = "#2BB944";
        color_changer = 1;
    }

    $('.versions').css("background-color", color);
    $('.versions').css("border-color", border);
}





//    function scroll() {
//        $('.versions').css("border-color", "transparent");
//        $('.versions').animate({ backgroundColor: "#0A3660" }, 500);
//        $('.versions').animate({ backgroundColor: "#13A12C" }, 500, scroll);
//    }