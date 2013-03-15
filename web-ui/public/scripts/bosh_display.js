// This function is for "event_log_script"
function a(msg_guid, js_text)
{
    if (js_text != null && js_text != '')
    {
        document.getElementById(msg_guid + "_text").innerHTML = js_text;
    }
}

//This function is for "file_progressbar_script"
function b(pb_id, percentage_done)
{
    document.getElementById("progressbar" + pb_id + "_label").innerText = percentage_done + "%";
    document.getElementById("progressbar" + pb_id + "_value").style["width"] = percentage_done + "px";
}

//This function is for "stage_progressbar_script"
function c(progress_guid, value, title, finished_steps, total_steps, label, bar_visible)
{
//    var existingTitle = document.getElementById(progress_guid + "_title").innerHTML;
//    var messages = existingTitle.split('<!--msgsplit-->');
//    if (messages[messages.length - 1].trim() !== title.trim())
//    {
//        document.getElementById(progress_guid + "_title").innerHTML = existingTitle + "<br /><!--msgsplit-->" + title;
//    }
    if (title != null && title != '')
    {
        document.getElementById(progress_guid + "_title").innerHTML = title;
    }
    document.getElementById(progress_guid +"_p_label").innerHTML = value + "%";
    document.getElementById(progress_guid +"_pb").style["width"] = value + "px";
    document.getElementById(progress_guid +"_pb").parentNode.style["display"] = bar_visible ? "inherit" : "none";
    document.getElementById(progress_guid +"_steps").innerHTML = "finished " + finished_steps + " of " + total_steps;
    document.getElementById(progress_guid +"_label").innerHTML = label;
}