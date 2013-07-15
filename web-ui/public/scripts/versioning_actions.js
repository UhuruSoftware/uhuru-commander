$(document).ready(function(){
    var process = setInterval(
        function(){

            var request = $.ajax(
                {
                    url: "/download_state",
                    type: 'GET',
                    cache: false,
                    error: function(data)
                    {
                    },
                    success: function(data)
                    {
                        var progress_data = jQuery.parseJSON(data);

                        $('.progress_bars').each(function(index, object)
                        {
                            // progress HTML object will he an ID of the form progressbar_[product_name]_[version_number]
                            // i.e. progressbar_ucc_1.0.9

                            var object_id_parts = object.id.split('_');
                            var product_name = object_id_parts[1];
                            var version_number = object_id_parts[2];

                            var progress_bar = document.getElementById(object.id);
                            var progress_message = document.getElementById('message_' + object.id);

                            if (progress_data[product_name] != null)
                            {
                                if (progress_data[product_name][version_number] != null)
                                {
                                    progress_bar.className = "progress_bars";
                                    progress_message.className = "progress_message";

                                    progress_bar.value = progress_data[product_name][version_number][0]
                                    progress_message.innerText = progress_data[product_name][version_number][1]
                                }
                                else if (progress_bar.className != "progress_bars hidden")
                                {
                                    location.reload();
                                }
                            }
                            else if (progress_bar.className != "progress_bars hidden")
                            {
                                location.reload();
                            }
                        })
                    }
                });
        }, 1000);
});