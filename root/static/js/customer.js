/* IntelliShip Customer Portal Javascript */
/* 2013 Aloha Technology Pvt Ltd. */
/* Designed by: Imran Momin*/

$(function() {
	var tooltips = $( "[title]" ).tooltip();
	});

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
				//$('#preload').hide();
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
	if (dialogTitle == undefined) dialogTitle = "Message";

	$('#dialog-message').dialog( {
		title: dialogTitle,
		width: '400px',
		buttons: {
			Ok: function() {
				$( this ).dialog( "close" );
				}
			}
		});

	$( "#dialog-message" ).html( dialogMessage );
	$( "#dialog-message" ).dialog("open");
	}

function validateEmail( Email ) {
	if (Email == undefined) return false;
	var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
	return filter.test(Email);
	}

function validPhoneNumber( Phone ) {
	if (Phone == undefined) return false;
	Phone = Phone.replace(/\D+/g,"");
	//alert("validPhoneNumber, Phone = " + Phone + ", length = " + Phone.length);
	return (Phone.length == 10);
	}

function validNumericField( control )
	{
	if ($("#" + control ).val() == undefined) return false;
	if ($("#" + control ).val() == 0) return false;
	if ($("#" + control ).val().match(/\D+/g)) return false;
	return true;
	}

function validDate( DateStr ) {
	var matches = /^(\d{2})[-\/](\d{2})[-\/](\d{4})$/.exec(DateStr);
	if (matches == null) return false;
	var mm = matches[1] - 1;
	var dd = matches[2];
	var yyyy = matches[3];
	var composedDate = new Date(yyyy, mm, dd);
	return composedDate.getDate() == dd && composedDate.getMonth() == mm && composedDate.getFullYear() == yyyy;
	}

function updateTips( tips, t )
	{
	tips
		.html( t )
		.addClass( "ui-state-highlight" );
		setTimeout(function() {
			tips.removeClass( "ui-state-highlight", 1500 );
			}, 500 );
	}

function validateForm( requireFields ) {
	//alert("in validateForm");
	var boolResult = true;
	var messageStr = "";

	try
	{
	Object.keys(requireFields).forEach(function (control) {
		var boolRequired = false;
		var properties = requireFields[control]

		// this check is added to breack forEach for one by one validation
		//if (boolRequired) return false;

		//alert("control= " + control);
		Object.keys(properties).forEach(function (proerty) {
			var value = properties[proerty];
			//alert("proerty= " + proerty + ", value = " + value + ", boolRequired = " + boolRequired);

			//if (boolRequired && proerty != "description") return false;

			if ( proerty == "email" )
				boolRequired = ( value ? !validateEmail($('#'+control).val()) : ($('#'+control).val().length > 0 && !validateEmail($('#'+control).val())));
			else if ( proerty == "phone" )
				boolRequired = ( value && !validPhoneNumber($('#'+control).val()) && $('#'+control).val('') );
			else if ( proerty == "date" )
				boolRequired = ( value && !validDate($('#'+control).val()) && $('#'+control).val('') );
			else if ( proerty == "minlength" )
				boolRequired = ( $('#'+control).val() == null || $('#'+control).val().length < value );
			else if ( proerty == "method" )
				if (value != null) boolRequired = value();
			else if ( proerty == "passwordmatch" )
				boolRequired = ( $('#'+control).val() != $('#'+value).val());

			if ( proerty == "description" && boolRequired) messageStr += "<p>" + value + "</p>";
			});

		//alert("messageStr= " + messageStr);

		if (boolRequired) {
			boolResult = false;
			$('#'+control).addClass( "ui-state-error" );
			}
		else
			if ($('#'+control).hasClass('ui-state-error')) $('#'+control).removeClass('ui-state-error');
		});

	var tips = $(".validateTips");
	//alert("tips: " + tips.length);

	if (boolResult == false) {
		if (tips.length == 0) {
			if (messageStr.length == 0)
				messageStr = "<div class='error'>Please fillup the valid information.</div>";
			else
				messageStr = "<div class='error'>"+messageStr+"</div>";

			showMessage(messageStr, "Error");
			} else {
			updateTips(tips, messageStr);
			}
		}
	}

	catch(err) {
		messageStr="<div class='error'><p>There was an error on this page</p>";
		messageStr+="<p>Error: " + err.message + "</p></div>";
		showMessage(messageStr, "Application Error");
		return false;
		}

	return boolResult;
	}

function add_new_row(ui_id, rowHTML) {
	$("#" + ui_id).append(rowHTML);
	//$(rowHTML).appendTo("#" + table_id + " tbody").fadeIn();
	//$("#" + table_id + " tbody").append(rowHTML);
	}
