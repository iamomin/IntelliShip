/* IntelliShip Customer Portal Javascript */
/* 2013 Aloha Technology Pvt Ltd. */
/* Designed by: Imran Momin*/

function afterSuccessCallBack(response_type, result_div, call_back_function, responseStatus) {
	var bollIsErrorResponse = false;
	var content = (response_type == "JSON" ? JSON_data.error : $('#response-content').html());

	if (responseStatus == 'error'){
		content = "ERROR:::Could not complete request.";
		}

	var re = new RegExp("(ERROR:::|Please See Errors Below|errors were encountered)","g");

	if (content != undefined && content.match(re))
		{
		bollIsErrorResponse = true;
		(content.match(/ERROR:::/) ? showMessage(content.replace(re,""), "Error") : showMessage(content, "Error"));
		}
	else
		{
		bollIsErrorResponse = false;
		if (response_type == "HTML") $('#' + result_div).html($('#response-content').html());
		}

	if (response_type == "HTML") $('#response-content').empty();

	// Make call to call back function on demand
	if (call_back_function != null) {call_back_function();}
	}

var JSON_data;
function send_ajax_request(result_div, type_value, section_value, action_value, optional_param, call_back_function) {

	$('#preload').show();

	var data_string = "ajax=1";
	if (type_value) data_string += '&type='+ (type_value ? type_value : 'HTML');
	if (action_value) data_string += '&action='+ action_value;

	if (optional_param) data_string += optional_param;

	var request_url = (section_value ? '/customer/' + section_value + '/ajax' : '/customer/ajax');

	var charPattern = /#/g;
	if (data_string.match(charPattern)) { data_string = data_string.replace(charPattern,"%23"); }

	if (type_value == "JSON") {
		JSON_data = null;
		$.ajax({
			type: "GET",
			url: request_url, 
			data: data_string,
			contentType: "application/json; charset=utf-8",
			dataType: 'json',
			success: function(data) {
				$('#preload').hide();

				if (data.error) showMessage(data.error, "Reseponse Error");
				else JSON_data = data;

				afterSuccessCallBack(type_value, "", call_back_function);
				},
			error: function(data) {
				showMessage("An internal error has occurred, Please contact support. " + data, "Internal Server Error");
				$('#preload').hide();
				},
			complete: function(data){
				$('#preload').hide();
				}
			});
		} else {
		$('#response-content').load(encodeURI(request_url+"?"+data_string), function (responseText, textStatus, XMLHttpRequest) {
			$('#preload').hide();
			afterSuccessCallBack(type_value, result_div, call_back_function, textStatus);
			});
		}
	}

$(".datefield").datepicker({ dateFormat: 'mm/dd/yy', gotoCurrent: true, clearText:'Clear', minDate: 0 });

$( "#dialog-message" ).dialog({
	autoOpen: false,
	modal: true,
	buttons: {
		Ok: function() {
		$( this ).dialog( "close" );
		}
	}
	});

function showMessage( dialogMessage, dialogTitle ) {
	if (dialogTitle == undefined)
		$('#dialog-message').dialog( { title: "Message"} );
	else
		$('#dialog-message').dialog( { title: dialogTitle } );

	$( "#dialog-message" ).html( "<p>" + dialogMessage + "</p>" );
	$( "#dialog-message" ).dialog("open");
	}

function validateEmail( Email ) {
	var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
	return filter.test(Email);
	}

function validPhoneNumber( Phone ) {
	Phone = Phone.replace(/\D+/g,"");
	//alert("validPhoneNumber, Phone = " + Phone + ", length = " + Phone.length);
	return (Phone.length == 10);
	}

function validateForm( requireFields ) {
	//alert("in validateForm");
	var boolResult = true;

	Object.keys(requireFields).forEach(function (control) {
		var boolRequired = false;
		var properties = requireFields[control]

		Object.keys(properties).forEach(function (proerty) {
			var value = properties[proerty];
			//alert("proerty= " + proerty + ", value = " + value);

			if ( proerty == "email" )
				boolRequired = ( value && !validateEmail($('#'+control).val()) );
			else if ( proerty == "phone" )
				boolRequired = ( value && !validPhoneNumber($('#'+control).val()) && $('#'+control).val('') );
			else if ( proerty == "minlength" )
				boolRequired = ( $('#'+control).val().length < value );
			});

		if (boolRequired) {
			boolResult = false;
			$('#'+control).addClass('require');
			}
		else
			if ($('#'+control).hasClass('require')) $('#'+control).removeClass('require');
		});

	if (boolResult == false)
		showMessage("Please fillup the valid information.","Error");

	return boolResult;
	}

var pkg_detail_row_ID = 0;
function add_row_to_table() {
	pkg_detail_row_ID++;
	var query_param = '&row_ID=' + pkg_detail_row_ID;

	send_ajax_request('', 'JSON', 'order', 'add_new_row', query_param, function (){
			add_new_row('pkg_detail', JSON_data.rowHTML);
			});
	}

function add_new_row(table_id, rowHTML) {
	$(rowHTML).appendTo("#" + table_id + " tbody").fadeIn();
	//$("#" + table_id + " tbody").append(rowHTML);
	}
