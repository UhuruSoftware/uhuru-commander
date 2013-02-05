function showManage()
{
    $('#manage_cloud_div').show();
    $('#virtual_machines_div').hide();
    $('#summary_div').hide();

    $('#manage_sublist').show();

    $('#manage_btn').css("background-color", "#06242d");
    $('#virtual_machines_btn').css("background-color", "##1B4D63");
    $('#summary_btn').css("background-color", "##1B4D63");
}

function showVirtualMachines()
{
    $('#manage_cloud_div').hide();
    $('#virtual_machines_div').show();
    $('#summary_div').hide();

    $('#manage_sublist').hide();

    $('#manage_btn').css("background-color", "##1B4D63");
    $('#virtual_machines_btn').css("background-color", "#06242d");
    $('#summary_btn').css("background-color", "##1B4D63");
}

function showSummary()
{
    $('#manage_cloud_div').hide();
    $('#virtual_machines_div').hide();
    $('#summary_div').show();

    $('#manage_sublist').hide();

    $('#manage_btn').css("background-color", "##1B4D63");
    $('#virtual_machines_btn').css("background-color", "##1B4D63");
    $('#summary_btn').css("background-color", "#06242d");
}





function showCloudNetworks()
{
    $('#cloud_networks').css("background-color", "#06242d");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').show();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudCompilation()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#06242d");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').show();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudResourcePools()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#06242d");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').show();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudUpdate()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#06242d");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').show();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudDeas()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#06242d");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').show();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudServices()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#06242d");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').show();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudProperties()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#06242d");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').show();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').hide();
}

function showCloudServicePlans()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#06242d");
    $('#cloud_advanced').css("background-color", "#466f55");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').show();
    $('#cloud_advanced_div').hide();
}

function showCloudAdvanced()
{
    $('#cloud_networks').css("background-color", "#466f55");
    $('#cloud_compilation').css("background-color", "#466f55");
    $('#cloud_resource_pools').css("background-color", "#466f55");
    $('#cloud_update').css("background-color", "#466f55");
    $('#cloud_deas').css("background-color", "#466f55");
    $('#cloud_services').css("background-color", "#466f55");
    $('#cloud_properties').css("background-color", "#466f55");
    $('#cloud_service_plans').css("background-color", "#466f55");
    $('#cloud_advanced').css("background-color", "#06242d");


    $('#cloud_networks_div').hide();
    $('#cloud_compilation_div').hide();
    $('#cloud_resource_pools_div').hide();
    $('#cloud_update_div').hide();
    $('#cloud_deas_div').hide();
    $('#cloud_services_div').hide();
    $('#cloud_properties_div').hide();
    $('#cloud_service_plans_div').hide();
    $('#cloud_advanced_div').show();
}

















