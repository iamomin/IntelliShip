
function CancelShipment(shipmentid)
	{
	$("#dialog-message").dialog( {
		title: "Void Shipment",
		width: '400px',
		buttons: {
			Ok: function() {
				var query_param = "shipmentid=" + shipmentid;
				send_ajax_request('', 'JSON', 'order', 'cancel_shipment', query_param, function () {
					if ( JSON_data.voided ) {
						showMessage("<div class='notice'>Shipment voided successfully</div>", "Void Shipment", function() {
							$("#dialog-message").html("<div class='notice'>Please wait...</div>");
							$("#do").val('');
							$("#force_edit").val('1');
							$("#frm_label").attr('action',window.location.href);
							$('#frm_label').submit();
							});
						} else {
						showMessage("Shipment void operation failed...", "Void Shipment");
						}
					});
				},
				Cancel: function() { $( this ).dialog( "close" ); }
			}
		});

		$("#dialog-message").html("<div class='notice'>Are you sure you want to void shipments ?</div>");
		$("#dialog-message").dialog("open");
	}

function MarkShipmentAsPrinted(coid, shipmentid)
	{
	var query_param = 'coid=' + coid + '&shipmentid=' + shipmentid;
	send_ajax_request('', 'JSON', 'order', 'mark_shipment_as_printed', query_param, function() {
		var href = window.location.href.split('?')[0];
		if (JSON_data.RETURN_SHIPMENT == 1) href += '?coid=' + JSON_data.RET_COID;
		window.location.href = href;
		});
	}

function SendEmailNotification(coid,shipmentid)
	{
	var arr = shipmentid.split("_");
	jQuery.each(arr, function(index, item) {
		var query_param = 'coid=' + coid + '&shipmentid=' + item;
		send_ajax_request('', 'JSON', 'order', 'confirm_notification_emails', query_param, function() {
			showConfirmBox(JSON_data.HTML, "Shipment Notification", function(){
				var requireHash = {
					to_email : { email: false, description: "Please specify valid TO email address" },
					from_email : { email: false, description: "Please specify valid FROM email address" }
					};
				if (validateForm(requireHash))
					{
					query_param += '&to_email=' + $("#to_email").val();
					if ($("#from_email").length) query_param += '&from_email=' + $("#from_email").val();
					send_ajax_request('', 'JSON', 'order', 'send_email_notification', query_param, function() {
						if (arr.length == (index+1)) CheckAfterLabelPrintActivities(coid,shipmentid);
						});
					}
				});
			});
		});
	}

function DownloadLabelImage(coid,shipmentid)
	{
	//var arr = shipmentid.split("_");
	//jQuery.each(arr, function(index, item) {
	//	var img = document.getElementById('lbl_'+item);
	//	var url = img.src.replace("/print", "/download");
	//	window.open(url, '', 'left=0,top=0,width=900,height=500,status=0');

	//	if (arr.length == (index+1)) CheckAfterLabelPrintActivities(coid,shipmentid);
	//	});

	var iframe = $('<iframe/>', {
				id: 'i-download-label',
				src: '/customer/order/quickship?do=download&shipmentid='+shipmentid,
				style: 'display:none',
				load: function() {
					alert('iframe loaded !');
					CheckAfterLabelPrintActivities(coid,shipmentid);
					}
			});

	$('body').append(iframe);
	setInterval(function(){CheckAfterLabelPrintActivities(coid,shipmentid);}, 3000);
/*
	var frame = document.createElement("iframe");
	var att=document.createAttribute("src");
	att.value="/customer/order/quickship?do=download&shipmentid="+shipmentid;
	frame.setAttributeNode(att);
	frame.onload = function(){console.log("IFRAME load getting called");};
	frame.onabort = function(){console.log("IFRAME abort getting called");};
	frame.onerror = function(){console.log("IFRAME error getting called");};
	document.body.appendChild(frame);
*/
	}

function CheckAfterLabelPrintActivities(coid,shipmentid,boolReprintLabel)
	{
	if ($('#printpackinglist').val() == 1) return GeneratePrintPackingList(coid, shipmentid);
	if ($('#billoflading').val() == 1)     return GenerateBillOfLading(coid, shipmentid);
	if ($('#printcominv').val() == 1)      return GenerateCommercialInvoice(coid, shipmentid);
	if (!boolReprintLabel) MarkShipmentAsPrinted(coid, shipmentid);
	}

function GeneratePrintPackingList(coid, shipmentid)
	{
	var query_param = 'action=generate_packing_list&ajax=1&type=HTML&coid=' + coid + '&shipmentid=' + shipmentid;
	window.location.href = '/customer/order/ajax?' + query_param;
	}

function GenerateBillOfLading(coid, shipmentid)
	{
	var query_param = 'action=generate_bill_of_lading&ajax=1&type=HTML&coid=' + coid + '&shipmentid=' + shipmentid;
	window.location.href = '/customer/order/ajax?' + query_param;
	}

function GenerateCommercialInvoice(coid, shipmentid)
	{
	var query_param = 'action=generate_commercial_invoice&ajax=1&type=HTML&coid=' + coid + '&shipmentid=' + shipmentid;
	window.location.href = '/customer/order/ajax?' + query_param;
	}
