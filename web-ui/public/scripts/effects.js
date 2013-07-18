
function versionNotification(newVersions)
{
    if(newVersions == true)
    {
        changecolors();
    }
}

function changecolors() {
    setInterval(change, 700);
}

function change() {
    var new_class = $('.versions').hasClass("notify_on") ? "notify_off" : "notify_on"

    $('.versions').removeClass("notify_on");
    $('.versions').removeClass("notify_off");

    $('.versions').addClass(new_class);
}