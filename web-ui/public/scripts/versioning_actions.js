$(document).ready(function(){
    var process = setInterval(
        function(){

            $('.progress_bars').each(function(index, object)
            {
                if ($('#' + object.id).is(':visible'))
                {
                    $.get('download_state',
                        { product: object.classList[1], version: object.classList[2] },
                        function(data)
                        {
                            jsonString = jQuery.parseJSON(data);
                            state = jsonString.progressmessage.substring(0, 10);
                            if(jsonString.progressbar < 100 || state == 'Downloaded' || state == 'Unpacking.')
                            {
                                $('#' + object.id).attr('value', parseInt(jsonString.progressbar));
                                $('#message_' + object.id).html(jsonString.progressmessage);
                            }
                            else
                            {
                                $('#' + object.id).attr('value', parseInt(jsonString.progressbar));
                                $('#message_' + object.id).html(jsonString.progressmessage);
                                clearInterval(process);
                                location.reload();
                            }
                        }
                    );
                }
            });

        }, 1000);
});