$(document).ready(function(){
    var last_log = 0;
    get_latest_log();

    setInterval(function(){

        $.ajax(
            {
                url: "/new_logs",
                type: 'GET',
                cache: false,
                data: { latest_log: last_log },
                error: function(data)
                {
                },
                success: function(data)
                {
                    if(data != 'none')
                    {
                        var log = jQuery.parseJSON(data);

                        if(log.counter == '0')
                        {
                            $('.popup_message').html(log.message);
                            $('.popup_error').fadeIn('slow');
                            get_latest_log();
                        }
                        else
                        {
                            $('.popup_message').html("(" + log.counter + ")" + log.message);
                            $('.popup_error').fadeIn('slow');
                            get_latest_log();
                        }
                    }
                }
            });

    }, 3000);


    function get_latest_log()
    {
        $.ajax(
            {
                url: "/get_last_log",
                type: 'GET',
                cache: false,
                error: function(data)
                {
                },
                success: function(data)
                {
                    last_log = data;
                    console.log(data);
                }
            });
    }

});