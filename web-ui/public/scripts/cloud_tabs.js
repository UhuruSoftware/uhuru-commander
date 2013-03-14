
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

function check_services() {
    $.get("/monit_status", function(data){
        if (data != "running") {
            var answer = confirm("Uhuru Cloud Commander services are restarting. You will not be able to login again until they are back online. Continue?")
            if (answer){
                window.location = "/logout"
            }
        }
        else{
            window.location = "/logout"
        }
    });
}

function refreshMonitStatus() {
    $.get("/monit_status", function(data){
        if (data == "running") {
            window.location = "/login"
        }
    });
}

function importSettings(){
    $('#file_upload_field').click();
    $("#file_upload_field").change(function(e){
        document.cloud_config_form.submit();
    });
}