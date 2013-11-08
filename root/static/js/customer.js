/* IntelliShip Customer Portal Javascript */
/* 2013 Aloha Technology Pvt Ltd. */
/* Designed by: Imran Momin*/

$(function() {
	$( "#dialog-message" ).dialog({
		autoOpen: false,
		modal: true,
		buttons: {
			Ok: function() {
			$( this ).dialog( "close" );
			}
		}
		});
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
