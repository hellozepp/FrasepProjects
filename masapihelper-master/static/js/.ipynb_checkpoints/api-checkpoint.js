var lastItemId=0;
var lastJson={};
var token='';
var modules=[];

function initializeApp() {
    $('#agentResponseDiv').hide();
    var object = {};
    object.ContactType = "Info";

    console.log("initApp");
    $('#attributes').val(JSON.stringify(object,null,4));


    listenOnReturnClick('#password', getToken);

    $('#tab-masapi').hide();
    $('#viyaRestUrl').val($('#viyaRestUrlDropDown').val());
}

function listenOnReturnClick(element, executeFunction) {
  console.log("listen on element: " + element);
  $(element).keypress(function(e) {
        var keycode = (e.keyCode ? e.keyCode : e.which);
        if (keycode == '13') {
            executeFunction();
        }
    });
}


function onChangeUrl(element) {
    $('#viyaRestUrl').val(element.value);
}


function setModal(title, body, footer, jsonObject) {
    $('#jsonOutput').hide();

    $('#modal_title').html(title);
    $('#modal_body').html(body);
    if (jsonObject != undefined) {
        $('#jsonOutput').val(JSON.stringify(jsonObject,null,2));
        $('#jsonOutput').show();
    }
    
    $('#modal_footer').html(footer);
    $('#myModal').modal('show');
}


function removeSpaces(element) {
    var val = $(element).val();
    var newval = val.replace(/\s/g, '');
    $(element).val(newval);
}


function callApi(url, parameters) {
	return $.ajax(url, {
		type: 'POST',
        contentType: "application/json",
        headers: {"Accept": "application/json", 'X-Requested-With': 'XMLHttpRequest'},
		data: JSON.stringify(parameters)
	} );
}


function getToken() {
    $('.loginwrong').hide();
    $('#btn_verifyLogin').hide();
    $('.tenantDetails').hide();
    $('#imgLoad_verifyLogin').show();
    var settings = {
      "async": true,
      "crossDomain": true,
      "url": "https://"+ $('#viyaRestUrl').val() +"/SASWebMarketingMid/rest/tenants/myTenantName",
      "method": "GET",
      "headers": {
        "authorization": "Basic " + btoa($('#username').val() + ":" + $('#password').val()),
        "cache-control": "no-cache"
      }
    }
    
    var url = "/api/gettoken";
    var parameters = {
        "user": $('#username').val(),
        "password": $('#password').val(),
        "basicAuth": btoa($('#username').val()),
        "baseUrl": $('#viyaRestUrl').val(),
		"ssl": $('#sslCheck').prop('checked')
    }


    callApi(url,parameters).error(function (response, error) {
        if(error == 'error') {
            console.log(response);
            $('#errorText').html(response.responseText);
            $('.loginwrong').show();
        } else {
            console.log(response);
            $('#errorText').html('check your login credentials!');
            $('.loginwrong').show();
        }
		$('#btn_verifyLogin').show();
		$('#imgLoad_verifyLogin').hide(); 
    }).success(function (response) {
        console.log(response);
        if(response.hasOwnProperty('error')) {
            $('#errorText').html('Error: ' + response.error + '<br>Description: ' + response.error_description);
            $('.loginwrong').show();
        } else {
            $('#tokenType').html(response.token_type);
            $('#expiresIn').html(response.expires_in);
            $('.tenantDetails').show();
            $('#tab-masapi').show();
            token = response.access_token;
            getModules();
        }
		$('#btn_verifyLogin').show();
		$('#imgLoad_verifyLogin').hide();        
    });
    
    
}

function getModules() {
    $("#mas_input").hide();
    $("#mas_output").hide();
    $('#accordion').html("");
    $('#inputParameters').html("");
    $('#btn_getDescriptors').hide();
    $('#imgLoad_getDescriptors').show();
    $('.descriptor_details').hide();
    
    var url = "/api/getmodules";
    var parameters = {
        "token": token,
        "baseUrl": $('#viyaRestUrl').val()
    }

    $('#descriptors').html("");

    callApi(url,parameters).error(function (response, error) {
        if(error == 'error') {
            alert('Error occured');
        } else {
            console.log(response);
            $('.loginwrong').show();
        }
    }).success(function (response) {
        //console.log(response);
        $('#descriptors').append("<option id='0' value='0' name=''> -- SELECT -- </option>");
        modules = response;
        for (var i=0; i<response.length;i++) {
            var nameAndVersion = response[i].name;
            var version = nameAndVersion.match(/\d+_\d+/g);
            var name = nameAndVersion.split(version)[0];
            var ver = version[0].replace("_",".");
            var id = response[i].id;
            var optionHtml = "<option id='desc_"+id+"' value='"+id+"' name='"+name+"'>"+name+" ("+ver+")</option>";
            $('#descriptors').append(optionHtml);
            $('.descriptor_details').show();       
          }
        $('#btn_getDescriptors').show();
        $('#imgLoad_getDescriptors').hide();
    });

}

function getModuleDetails() {
    $("#mas_input").show();
    $("#mas_output").hide();
    $('#accordion').html("");
    var data = {};
    var moduleid = $('#descriptors').val();
    
    var url = "/api/getmoduleparameters";
    var parameters = {
        "token": token,
        "baseUrl": $('#viyaRestUrl').val(),
        "moduleid": moduleid
    }
    
    
    callApi(url,parameters).error(function (response, error) {
        if(error == 'error') {
            alert('Error occured');
        } else {
            console.log(response);
            $('.loginwrong').show();
        }
    }).success(function (response) {
        console.log(response);
        var outputs = response.outputs;
        var inputs = response.inputs;
        
        $("#inputParameters").html('');
        $("#outputParameters").html('');
        for (var i=0; i<inputs.length;i++) {
            inputs[i].name = inputs[i].name.replace(/\"/g,"");
            inputs[i].type = inputs[i].type.replace(/\"/g,"");
            addInputVar(inputs[i]);
        }
        listenOnReturnClick('.inputvar', callDecision);
    });
}

function callDecision() {
    $('#btn_calldecision').hide();
	$('#imgLoad_calldecision').show();
	
    var moduleid = $('#descriptors').val();
    var inputparameters = $('.inputvar').toArray();
    var inputs = [];
    for (i=0;i<inputparameters.length;i++) {
        var namevaluepair = {};
        var attrtype = $(inputparameters[i]).attr('name');
        namevaluepair['name']  = $(inputparameters[i]).attr('id');
        if (attrtype == "decimal") {
            namevaluepair['value'] = parseFloat($(inputparameters[i]).val()); 
        } else {
            namevaluepair['value'] = $(inputparameters[i]).val(); 
        }

        inputs.push(namevaluepair);
    }
    
    var payload = { "version" : 1,  "inputs": inputs}
    
    var url = "/api/calldecision";
    var parameters = {
        "token": token,
        "baseUrl": $('#viyaRestUrl').val(),
        "moduleid": moduleid,
        "payload": payload,
		"ssl": $('#sslCheck').prop('checked')
    }
    
    callApi(url,parameters).error(function (response, error) {
        if(error == 'error') {
            alert('Error occured');
        } else {
            console.log(response);
        }
		$('#imgLoad_calldecision').hide();
		$('#btn_calldecision').show();
    }).success(function (response) {
		if (response.hasOwnProperty('error')) {
			alert(response.error);
		} else {
			var parametersToExclude = ['PathID', 'ruleFiredPathTraversal', 'ruleFiredFlags', 'rulesFiredForRecordCount']
			var outputs = response.outputs;
			$("#outputParameters").html('');
			for (var i=0; i<outputs.length;i++) {
				if (outputs[i].value) {
					outputs[i].name = outputs[i].name.replace(/\"/g,"");
					
					//only output parameter if not in exclusion list
					if (parametersToExclude.includes(outputs[i].name) == false ) {
						outputs[i].value = outputs[i].value;
						addOutputVar(outputs[i]);
					}
					
				}          
			}
            $("#mas_output").show();
			$('#imgLoad_calldecision').hide();
			$('#btn_calldecision').show();
		}
    });
}

function addInputVar(dataItem) {
    $("#inputParameters").append(htmlTemplates.templateInputVar(dataItem));
}
function addOutputVar(dataItem) {
    $("#outputParameters").append(htmlTemplates.templateOutputVar(dataItem));
}

function showModal() {
    setModal('modal header line'
            ,'Following JSON object was retrieved :<br>'
            ,'<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>'
            ,lastJson
        );
}


function openAbout() {
    setModal('<img src="/static/img/gpci_logo.png">'
            ,'This application has been developed by the GPCI <br><br>'
            +'If you have questions or comments please '
            +'<b><a href="mailto:rob.sneath@sas.com;mathias.bouten@sas.com?Subject=CI360APIHelper%20Question" target="_top">contact us via email</a><b>!'
            ,'<span class="mr-auto">Version 0.5 - last update 2018-06-08</span>'
            +'<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>'
        );
}