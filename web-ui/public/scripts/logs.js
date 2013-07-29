var focused;

$(document).ready(function(){
    checkForLogs();
});
$(window).focus(function(){
    checkForLogs();
});

$(window).blur(function(){
    clearInterval(focused);
});


function checkForLogs()
{
    focused = setInterval(function(){

        $.ajax(
            {
                url: "/new_logs",
                type: 'GET',
                cache: false,
                error: function(data)
                {
                },
                success: function(data)
                {
                    var log = jQuery.parseJSON(data);

                    if (log.message != null)
                    {
                        $('.popup_message').html("Error (" + log.counter + "):&nbsp;" + log.message);
                        $('.popup_div').fadeIn('slow');
                    }
                }
            });

    }, 3000);
}