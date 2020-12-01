function callApi(url, parameters) {
	return $.ajax(url, {
		type: 'POST',
        contentType: "application/json",
        headers: {"Accept": "application/json", 'X-Requested-With': 'XMLHttpRequest'},
		data: JSON.stringify(parameters)
	} );
}


function get_modules() {
    var url = "/api/getmodules";
    var parameters = {"filter": "a"}

    callApi(url,parameters).error(function (response, error) {
        if(error == 'error') {
            alert('Error occured');
        } else {
            console.log(response);
        }
    }).success(function (response) {
        $('#modules').html('');
        response.forEach(function(element) {
            console.log(element.id);
            $('#modules').append('<option value="'+element.id+'">'+element.name+'</option>');
        });
        drawSelect();
    });
}