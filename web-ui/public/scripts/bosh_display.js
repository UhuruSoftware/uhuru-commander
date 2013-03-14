// This function is for "event_log_script"
function a(msg_guid, js_text)
{
    document.getElementById(msg_guid + "_text").innerHTML = js_text;
}

//This function is for "file_progressbar_script"
function b(pb_id, percentage_done)
{
    document.getElementById("progressbar" + pb_id + "_label").innerText = percentage_done + "%";
    document.getElementById("progressbar" + pb_id + "_value").style["width"] = percentage_done + "px";
}

//This function is for "stage_progressbar_script"
function c(progress_guid, value, title, finished_steps, total_steps, label)
{
    document.getElementById(progress_guid + "_title").innerHTML = title;
    document.getElementById(progress_guid +"_p_label").innerHTML = value + "%";
    document.getElementById(progress_guid +"_pb").style["width"] = value + "px";
    document.getElementById(progress_guid +"_steps").innerHTML = "finished " + finished_steps + " of " + total_steps;
    document.getElementById(progress_guid +"_label").innerHTML = label;
}