
function focusCloudMenu(id)
{
    $('#cloud_' + id).addClass("tab_focus");
    $('#cloud_' + id + '_div').show();
}

function unfocusCloudMenu(id)
{
    $('#cloud_' + id).removeClass("tab_focus");
    $('#cloud_' + id + '_div').hide();
}

function switchCloudMenu(menus, selectedMenu)
{
    var length = menus.length,
    element = null;
    for (var i = 0; i < length; i++) {
        element = menus[i];
        unfocusCloudMenu(element)
    }

    focusCloudMenu(selectedMenu);
}



