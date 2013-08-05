function selectDependentVersions()
{
    var product_name = $('#dependent_products').val();
    $('.hidden_dependent_versions').hide();
    $('#' + product_name + '_dependent_versions').show();
}

function selectDependencyVersions()
{
    var product_name = $('#dependency_products').val();
    $('.hidden_dependency_versions').hide();
    $('#' + product_name + '_dependency_versions').show();
}