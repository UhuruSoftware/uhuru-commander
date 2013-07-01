$(document).ready(function(){
    var process = setInterval(
        function(){

            $('.progress_bars').each(function(index, object)
            {
                if ($('#' + object.id).is(':visible') && $('#' + object.id).val < 100)
                {
                    $.get('download_state',
                        { product: object.classList[1], version: object.classList[2] },
                        function(data)
                        {
                            if(data < 100)
                            {
                                $('#' + object.id).attr('value', parseInt(data));
                            }
                            else
                            {
                                $('#' + object.id).attr('value', parseInt(data));
                                clearInterval(process);
                            }
                        }
                    );
                }
            });

        }, 1000);
});