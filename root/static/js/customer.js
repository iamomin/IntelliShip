/* IntelliShip Customer Portal Javascript */
/* 2013 Aloha Technology Pvt Ltd. */
/* Designed by: Imran Momin*/

function setToolTip() {
	$("[title]").tooltip({ track: true });
	}

function isEmpty( el ) {
	return !$.trim($("#" + el).html())
	}

var JSON_data, waiting_COUNT=0;
function send_ajax_request(result_div, type_value, section_value, action_value, optional_param, call_back_function) {
	
	waiting_COUNT++;
	$('#preload').show();

	var data_string = "ajax=1&eventtimestamp=" + jQuery.now();
	if (type_value) data_string += '&type='+ (type_value ? type_value : 'HTML');
	if (action_value) data_string += '&action='+ action_value;

	if (optional_param) data_string += '&' + optional_param;

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
				waiting_COUNT--;
				if (waiting_COUNT == 0) $('#preload').hide();
				JSON_data = data;

				if (JSON_data.error && !JSON_data.popup_type) showMessage("<div class='error'>" + JSON_data.error + "</div>", "Reseponse Error");

				afterSuccessCallBack(type_value, "", call_back_function);
				},
			error: function(data) {
				showMessage("An internal error has occurred, Please contact support. " + data, "Internal Server Error");
				waiting_COUNT--;
				if (waiting_COUNT == 0) $('#preload').hide();
				},
			complete: function(data){
				//$('#preload').hide();
				}
			});
		} else {
		$('#response-content').load(encodeURI(request_url+"?"+data_string), function (responseText, textStatus, XMLHttpRequest) {
			waiting_COUNT--;
			if (waiting_COUNT == 0) $('#preload').hide();
			afterSuccessCallBack(type_value, result_div, call_back_function, textStatus);
			});
		}
	}

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
		if (response_type == "HTML") {
			//alert("RESPONSE CONTENT: " + $('#response-content').html());
			//$('#' + result_div).fadeOut(1000);
			$('#' + result_div).html($('#response-content').html());
			// + result_div).fadeIn(1000);
			}
		}

	if (response_type == "HTML") $('#response-content').empty();

	// Make call to call back function on demand
	if (call_back_function != null) {call_back_function();}
	}

//$(".datefield").datepicker({ dateFormat: 'mm/dd/yy', gotoCurrent: true, clearText:'Clear', minDate: 0 });

if ($( "#dialog-message" ).length)
	{
	$( "#dialog-message" ).dialog({
		show: { effect: "blind", duration: 1000 },
		hide: { effect: "explode", duration: 1000 },
		autoOpen: false,
		modal: true,
		buttons: {
			Ok: function() {
				$( this ).dialog( "close" );
				}
			}
		});
	}

function showMessage( dialogMessage, dialogTitle, ok_button_callback ) {
	if (dialogTitle == undefined) dialogTitle = "Message";
	if (ok_button_callback == null) ok_button_callback = function() { $('#dialog-message').dialog( "close" ) };

	$('#dialog-message').dialog( {
		title: dialogTitle,
		width: '400px',
		buttons: {
			Ok: ok_button_callback
			}
		});

	$( "#dialog-message" ).html( dialogMessage );
	$( "#dialog-message" ).dialog("open");
	}

function showError( dialogMessage, dialogTitle ) {
	if (dialogTitle == undefined) dialogTitle = "Error";

	$('#dialog-message').dialog( {
		title: dialogTitle,
		width: '400px',
		buttons: {
			Cancel: function() {
				$( this ).dialog( "close" );
				}
			}
		});

	$( "#dialog-message" ).html( "<div class='error'><p>" + dialogMessage + "</p>" );
	$( "#dialog-message" ).dialog("open");
	}

function showConfirmBox( dialogMessage, dialogTitle, ok_button_callback, cancel_button_callback ) {
	if (dialogTitle == undefined) dialogTitle = "Message";
	if (ok_button_callback == null) ok_button_callback = function() { $('#dialog-message').dialog( "close" ) };
	if (cancel_button_callback == null) cancel_button_callback = function() { $('#dialog-message').dialog( "close" ) };

	$('#dialog-message').dialog( {
		title: dialogTitle,
		width: '400px',
		buttons: {
			Ok: ok_button_callback,
			Cancel: cancel_button_callback
			}
		});

	$( "#dialog-message" ).html( dialogMessage );
	$( "#dialog-message" ).dialog("open");
	}

function validateEmail( Email ) {
	if (Email == undefined) return false;
	var filter = /^[A-Z0-9._-]+@[A-Z0-9.-]+\.[A-Z]{2,3}$/i;
	//var filter = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;
	return filter.test(Email);
	}

function validPhoneNumber( Phone ) {
	if (Phone == undefined) return false;
	Phone = Phone.replace(/\D+/g,"");
	//alert("validPhoneNumber, Phone = " + Phone + ", length = " + Phone.length);
	return (Phone.length >= 10 && Phone.length <= 15);
	}

function validNumericField( Numeric )
	{
	if (Numeric == undefined) return false;
	return Numeric.match(/^\d+(\.\d+)?$/g);
	}

function validNonZeroNumericField( Numeric )
	{
	if (Numeric == undefined) return false;
	if (Numeric.match(/^\d+(\.\d+)?$/g)) {
		return (Numeric > 0)
		}
	return false;
	}

function validDate( DateStr )
	{
	var matches = /^(\d{2})[-\/](\d{2})[-\/](\d{4})$/.exec(DateStr);
	if (matches == null) return false;
	var mm = matches[1] - 1;
	var dd = matches[2];
	var yyyy = matches[3];
	var composedDate = new Date(yyyy, mm, dd);
	return composedDate.getDate() == dd && composedDate.getMonth() == mm && composedDate.getFullYear() == yyyy;
	}

function updateTips( t, tips )
	{
	if (tips == undefined) tips = $(".validateTips");
	if (tips == undefined) return;
	if (t == undefined || t.length == 0) tips.empty();

	tips
		.html( "<div class='error'>" + t + "</div>")
		.addClass( "ui-state-highlight" );
		setTimeout(function() {
			tips.removeClass( "ui-state-highlight", 1500 );
			}, 500 );

	return tips;
	}

function validateForm( requireFields )
	{
	//alert("in validateForm");
	var boolResult = true;
	var messageStr = "";

	try
	{
	Object.keys(requireFields).forEach(function (control) {
		var boolRequired = false;
		var properties = requireFields[control];

		if (properties == undefined) return;

		// this check is added to breack forEach for one by one validation
		//if (boolRequired) return false;

		//alert("control= " + control);
		Object.keys(properties).forEach(function (proerty) {
			var value = properties[proerty];

			//if (boolRequired && proerty != "description") return false;

			if ( proerty == "email" )
				boolRequired = ( value ? !validateEmail($('#'+control).val()) : ($('#'+control).val().length > 0 && !validateEmail($('#'+control).val())));
			else if ( proerty == "phone" )
				boolRequired = ( value ? !validPhoneNumber($('#'+control).val()) : ($('#'+control).val().length > 0 && !validPhoneNumber($('#'+control).val())));
			else if ( proerty == "date" )
				boolRequired = ( value && !validDate($('#'+control).val()) && $('#'+control).val('') );
			else if ( proerty == "numeric" )
				boolRequired = ( value ? !validNumericField($('#'+control).val()) : ($('#'+control).val().length > 0 && !validNumericField($('#'+control).val())));
			else if ( proerty == "nonzero" )
				boolRequired = ( value ? !validNonZeroNumericField($('#'+control).val()) : ($('#'+control).val().length > 0 && !validNonZeroNumericField($('#'+control).val())));
			else if ( proerty == "minlength" )
				boolRequired = ( $('#'+control).val() == undefined || $('#'+control).val().length < value );
			else if ( proerty == "method" )
				if (value != null) boolRequired = value();
			else if ( proerty == "passwordmatch" )
				boolRequired = ( $('#'+control).val() != $('#'+value).val());

			//if ( proerty == "description" && boolRequired) messageStr += "<p>" + value + "</p>";
			if ( proerty == "description" && boolRequired) messageStr += " " + value + ",";

			//alert("proerty= " + proerty + ", value = " + value + ", boolRequired = " + boolRequired);
			});

		//alert("messageStr= " + messageStr + ", boolRequired: " + boolRequired);

		if (boolRequired) {
			boolResult = false;
			if (control != 'package-detail-list') $('#'+control).addClass( "ui-state-error" );
			}
		else
			if ($('#'+control).hasClass('ui-state-error')) $('#'+control).removeClass('ui-state-error');
		});

	var tips = $(".validateTips");
	//alert("tips: " + tips.length);

	messageStr = messageStr.replace(/Please specify /ig, "");
	messageStr = messageStr.replace(/,$/ig, "");
	messageStr = "Please specify " + (messageStr.length > 0 ? messageStr : "valid information");

	if (boolResult == false) {
		if (tips != undefined && tips.length == 0) {
			if (messageStr.length == 0)
				messageStr = "<div class='error'>Please provide all required information.</div>";
			else
				messageStr = "<div class='error'>"+messageStr+"</div>";

			showMessage(messageStr, "Error");
			} else {
			updateTips(messageStr,tips);
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

function add_new_row(ui_id, rowHTML)
	{
	$("#" + ui_id).append(rowHTML);
	//$(rowHTML).appendTo("#" + table_id + " tbody").fadeIn();
	//$("#" + table_id + " tbody").append(rowHTML);
	}

function markRequiredFields(requireFields)
	{
	Object.keys(requireFields).forEach(function (control) {
		var properties = requireFields[control];

		Object.keys(properties).forEach(function (property) {
			var value = properties[property];

			if ( property == "email" || property == "phone" || property == "date" || property == "numeric") {
				$('#'+control).prop("required", value);
				if (value != false) $('label[for="'+control+'"]').addClass('require');
				}
				else {
					$('#'+control).prop("required", true);
					$('label[for="'+control+'"]').addClass('require');
				}
			});
		});
	}

function validateDepartment(control_ID, customerid)
	{
	var department = $("#"+control_ID).val();
	if (department == undefined || department.length == 0) return;
	var query_param  = 'customerid=' + customerid + '&term=' + department;

	send_ajax_request('', 'JSON', '', 'validate_department', query_param, function() {
			if (JSON_data.COUNT > 0) return;
			showError("Please specify valid department name");
			$("#"+control_ID).val("");
			});
	}

/***************************************************************/
function ShowPrivacy()
	{
	$("#dialog-message").dialog({
		title: 'Privacy Policy',
		width: '1000px',
		show: { effect: "blind", duration: 1000 },
		hide: { effect: "explode", duration: 1000 },
		autoOpen: false,
		modal: true
		});

	send_ajax_request('dialog-message', 'HTML', 'privacy', '', '', function() {
			$("#dialog-message").dialog("open");
			});
	}
function ShowLegal()
	{
	$("#dialog-message").dialog({
		title: 'Software License Agreement/Terms of Use',
		width: '1000px',
		maxHeight: 600,
		show: { effect: "blind", duration: 1000 },
		hide: { effect: "explode", duration: 1000 },
		autoOpen: false,
		modal: true
		});

	send_ajax_request('dialog-message', 'HTML', 'legal', '', '', function() {
			$("#dialog-message").dialog("open");
			});
	}
