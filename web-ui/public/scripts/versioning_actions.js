
function download_and_state(product, version, progressbar_id, button_id)
{
    var current_cell = null;
    $.get('download', { product: product, version: version });

    $('.states div:first-child').each(function(item, object)
    {
        if (object.classList[0] == product && object.id == version)
        {
            current_cell = object;
            object.innerHTML = "<div class='downloading'>Downloading</div>";
            $('#' + progressbar_id).show();
            $('#' + button_id).hide();
        }
    });

    var process = setInterval(
        function(){
            $.get('download_state',
                { product: product, version: version },
                function(data)
                {
                    $('#' + progressbar_id).attr('value', parseInt(data));
                    if(data == 100)
                    {
                        $.get('refresh_state', { product: product, version: version }, function(response){
                            if(response == '1')
                            {
                                current_cell.innerHTML = "<div class='remote_only'>Remote Only</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '2')
                            {
                                current_cell.innerHTML = "<div class='downloading'>Downloading</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '3')
                            {
                                current_cell.innerHTML = "<div class='local'>Local</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '4')
                            {
                                current_cell.innerHTML = "<div class='local_preparing'>Local Preparing</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '5')
                            {
                                current_cell.innerHTML = "<div class='available'>Available</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '6')
                            {
                                current_cell.innerHTML = "<div class='deployed'>Deployed</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                            if(response == '')
                            {
                                current_cell.innerHTML = "<div class='error'>Error</div>";
                                $('#' + button_id).show();
                                $('#' + progressbar_id).hide();
                            }
                        });
                        clearInterval(process);
                    }
                }
            );
        }, 1000
    );
}