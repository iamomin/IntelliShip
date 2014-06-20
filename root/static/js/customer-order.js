var requiredFieldHash = {};

function BindCompanyAutoComplete(direction,availableCustomers)
	{
	$("#"+direction+"name").autocomplete({
		source: availableCustomers,
		select: function( event, ui ) {
			var SelectedCompany = ui.item.value
			var AddrParts = SelectedCompany.split(" | ");
			var Company = AddrParts[0];
			var Key = AddrParts[0] + '-' + AddrParts[1] + '-' + AddrParts[2] + '-' + AddrParts[3] + '-' + AddrParts[4];
			var RefID = hashCompanyRef[Key];
			if (RefID == undefined) return;
			ui.item.value = Company;
			populateShipAddress(direction,RefID);
			}
		}).focus(function() {
			$(this).autocomplete("search", "|");
			});
	}

/*
########################################################################################
## Inbound / Outbound / Dropship stuffs
########################################################################################
*/

function GetAddress(direction)
	{
	var name			= direction ? $('#' + direction + 'name').val() : '';
	var address1		= direction ? $('#' + direction + 'address1').val() : '';
	var address2		= direction ? $('#' + direction + 'address2').val() : '';
	var city			= direction ? $('#' + direction + 'city').val() : '';
	var state			= direction ? $('#' + direction + 'state').val() : '';
	var zip				= direction ? $('#' + direction + 'zip').val() : '';
	var country			= direction ? $('#' + direction + 'country').val() : 'US';
	var contact			= direction ? $('#' + direction + 'contact').val() : '';
	var phone			= direction ? $('#' + direction + 'phone').val() : '';
	var department		= direction ? $('#' + direction + 'department').val() : '';
	var customernumber	= direction ? $('#' + direction + 'customernumber').val() : '';
	var email			= direction ? $('#' + direction + 'email').val() : '';

	var newAddress = {
		name			: name,
		address1		: address1,
		address2		: address2,
		city			: city,
		state			: state,
		zip				: zip,
		country			: country,
		contact			: contact,
		phone			: phone,
		department		: department,
		customernumber	: customernumber,
		email			: email
		};

	return newAddress;
	}

function RestoreAddress(address, direction, type)
	{
	$('#' + direction + 'name').val(addressArray[address].name);
	$('#' + direction + 'address1').val(addressArray[address].address1);
	$('#' + direction + 'address2').val(addressArray[address].address2);
	$('#' + direction + 'country').val(addressArray[address].country);
	if(type == 'EDITABLE') $('#' + direction + 'country').change();
	$('#' + direction + 'city').val(addressArray[address].city);
	$('#' + direction + 'city').next("span").text($('#' + direction + 'city').val());
	$('#' + direction + 'state').val(addressArray[address].state);
	$('#' + direction + 'state').next("span").text($('#' + direction + 'state').val());
	$('#' + direction + 'zip').val(addressArray[address].zip);
	if(type == 'EDITABLE') $('#' + direction + 'zip').change();
	$('#' + direction + 'contact').val(addressArray[address].contact);
	$('#' + direction + 'phone').val(addressArray[address].phone);

	$('#' + direction + 'department').val(addressArray[address].department);
	$('#' + direction + 'customernumber').val(addressArray[address].customernumber);
	$('#' + direction + 'email').val(addressArray[address].email);
	}

var from_to_Hash = {};
var fieldArray = ['name', 'address1', 'address2', 'city', 'state', 'zip', 'country', 'contact', 'phone', 'department', 'customernumber', 'email'];

function ConfigureAddressSection(address, direction, type)
	{
	var editable     = (type == 'EDITABLE' ? true : false);
	var add_class    = (editable ? 'broad-text' : 'labellike');
	var remove_class = (editable ? 'labellike' : 'broad-text');

	//alert("ConfigureAddressSection, direction: " + direction + ", add_class: " + add_class + ", remove_class: " + remove_class);

	jQuery.each( fieldArray, function( i, val ) {
		if (val == 'department' || val == 'customernumber' || val == 'email') return;

		var targetCtrl = direction + val;
		if (val == 'city')
			{
			var targetDiv = direction + 'CityDiv';
			if (editable)
				$('#'+targetDiv).html(from_to_Hash[targetCtrl]);
			else
				{
				from_to_Hash[targetCtrl] = $('#'+targetDiv).html();
				var inputCtrl = '<input type="hidden" name="' + targetCtrl + '" id="' + targetCtrl + '" value="' + $('#'+targetCtrl).val() + '"/>';
				$('#'+targetDiv).html(inputCtrl + '<span class="labellike">' + $('#'+targetCtrl).val() + "</span>,");
				}
			}
		else if (val == 'state')
			{
			var targetDiv = direction + 'StateDiv';
			if (editable)
				$('#'+targetDiv).html(from_to_Hash[targetCtrl]);
			else
				{
				from_to_Hash[targetCtrl] = $('#'+targetDiv).html();
				var inputCtrl = '<input type="hidden" name="' + targetCtrl + '" id="' + targetCtrl + '" value="' + $('#'+targetCtrl).val() + '"/>';
				$('#'+targetDiv).html(inputCtrl + '<span id="'+direction+'statespan" class="labellike">' + $('#'+targetCtrl).val() + "</span>,");
				}
			}
		else if(val == 'country')
			{
			var targetDiv = direction + 'CountryDiv';
			if (editable)
				$('#'+targetDiv).html(from_to_Hash[targetCtrl]);
			else
				{
				from_to_Hash[targetCtrl] = $('#'+targetDiv).html();
				$('#'+targetDiv).html('<input type="text" name="'+targetCtrl+'" id="'+targetCtrl+'" class="labellike" value="'+$('#'+targetCtrl).val()+'"/>');
				}
			}
		else
			{
			$('#' + targetCtrl).removeClass(remove_class);
			$('#' + targetCtrl).addClass(add_class);
			$('#' + targetCtrl).prop("readonly", !editable);
			}

		if ($('#'+targetCtrl).val() != undefined ) $('#'+targetCtrl).prop('width', $('#'+targetCtrl).val().length);
		});

	RestoreAddress(address, direction, type);
	}

var previousCheck;
var addressArray = {};

function ConfigureInboundOutboundDropship()
	{
	var selectedType = $('input:radio[name=shipmenttype]:checked').val();

	/* set default shipment type outbound if no return capability */
	if (selectedType == undefined) selectedType = 'outbound';
	if (previousCheck == undefined) previousCheck = 'outbound';

	if (selectedType != previousCheck)
		{
		if (previousCheck == 'outbound')
			{
			addressArray['COMPANY_ADDRESS'] = GetAddress('from');
			addressArray['ADDRESS_DESTIN'] = GetAddress('to');
			}
		if (previousCheck == 'inbound')
			{
			addressArray['ADDRESS_DESTIN'] = GetAddress('from');
			addressArray['COMPANY_ADDRESS'] = GetAddress('to');
			}
		if (previousCheck == 'dropship')
			{
			addressArray['ADDRESS_ORIGIN'] = GetAddress('from');
			addressArray['ADDRESS_DESTIN'] = GetAddress('to');
			}
		}

	if (selectedType == 'inbound')
		{
		$('#fromdepartment_tr').hide();
		$('#todepartment_tr').show();
		$('#fromcustomernumber_tr').show();
		$('#tocustomernumber_tr').hide();
		ConfigureAddressSection('COMPANY_ADDRESS', 'to', 'READONLY');
		ConfigureAddressSection('ADDRESS_DESTIN', 'from', 'EDITABLE');
		}
	if (selectedType == 'outbound')
		{
		$('#fromdepartment_tr').show();
		$('#todepartment_tr').hide();
		$('#fromcustomernumber_tr').hide();
		$('#tocustomernumber_tr').show();
		ConfigureAddressSection('ADDRESS_DESTIN', 'to', 'EDITABLE');
		ConfigureAddressSection('COMPANY_ADDRESS', 'from', 'READONLY');
		}
	if (selectedType == 'dropship')
		{
		$('#fromdepartment_tr').show();
		$('#todepartment_tr').hide();
		$('#fromcustomernumber_tr').hide();
		$('#tocustomernumber_tr').show();
		ConfigureAddressSection('ADDRESS_ORIGIN', 'from', 'EDITABLE');
		ConfigureAddressSection('ADDRESS_DESTIN', 'to', 'EDITABLE');
		}

	previousCheck = selectedType;
	}
/*
########################################################################################
*/

function setCityAndState(type)
	{
	var tozip = $("#"+type+"zip").val();
	if (tozip.length < 5) return;

	var query_param = "&zipcode=" + tozip + '&city=' + $("#"+type+"city").val() + '&state=' + $("#"+type+"state").val() + '&country=' + $("#"+type+"country").val();
	if($("#"+type+"zip").val() != "") {
		send_ajax_request('', 'JSON', 'order', 'get_city_state', query_param, function () {
			if (JSON_data.city.length > 0) $("#"+type+"city").val(JSON_data.city);
			if (JSON_data.state.length > 0) $("#"+type+"state").val(JSON_data.state);
			if (JSON_data.country.length > 0) $("#"+type+"country").val(JSON_data.country);
			if ($("#fromstatespan").length && type == 'from') $("#fromstatespan").text(JSON_data.state);
			if ($('#destinationcountry').length > 0) $("#destinationcountry").val($("#tocountry").val());
			});
		}
	}

function updateStateList(type,call_back_fn)
	{
	$("#"+type+"city").val('');
	$("#"+type+"state").val('');
	$("#"+type+"zip").val('');

	var country = $("#"+type+"country").val();
	if (country.length == 0) return;

	var query_param = "country=" + country + '&control=' + type + 'state';

	send_ajax_request(type + 'StateDiv', 'HTML', 'order', 'get_country_states', query_param, call_back_fn);
	}

function populateShipAddress(direction, referenceid)
	{
	if (referenceid == undefined) return;

	var query_param = '&referenceid='+referenceid;

	if (referenceid.length > 0) {
		resetCSList();
		send_ajax_request('', 'JSON', 'order', 'get_address_detail', query_param, function (){
			if (JSON_data.addressname) {
				var ADDRESS_data = JSON_data;
				$("#" + direction + "country").val(ADDRESS_data.country);
				checkInternationalSection();

				updateStateList(direction, function() {
					$("#" + direction + "name").val(ADDRESS_data.addressname);
					$("#" + direction + "address1").val(ADDRESS_data.address1);
					$("#" + direction + "address2").val(ADDRESS_data.address2);
					$("#" + direction + "city").val(ADDRESS_data.city);
					$("#" + direction + "state").val(ADDRESS_data.state);
					$("#" + direction + "zip").val(ADDRESS_data.zip);
					$("#" + direction + "contact").val(ADDRESS_data.contactname);
					$("#" + direction + "phone").val(ADDRESS_data.contactphone);
					$("#" + direction + "customernumber").val(ADDRESS_data.extcustnum);
					$("#" + direction + "email").val(ADDRESS_data.shipmentnotification);
					});

				}
			});
		}
	}

function checkDueDate()
	{
	var ShipDate = $('#datetoship').val();
	var DueDate = $('#dateneeded').val();
	var OffsetEqual = 7;
	var OffsetLessThan = -7;

	var query_param = '&shipdate=' + ShipDate + '&duedate=' + DueDate + '&offset=' + OffsetEqual + '&lessthanoffset=' + OffsetLessThan;
	send_ajax_request('', 'JSON', 'order', 'adjust_due_date', query_param, function (){
		if (JSON_data.dateneeded) {
			$("#dateneeded").val(JSON_data.dateneeded);
			}
		});
	}

function validatePackageDetails()
	{
	var boolInvalidData=false;
	//var controls = ['quantity', 'sku', 'weight', 'dimlength', 'dimwidth', 'dimheight'];
	var controls = ['quantity', 'description', 'weight'];

	var requiredPkgProduct = {};

	$('input[id^=rownum_id_]').each(function( index ) {

		var row_ID = this.id.split('_')[2];

		if ($('#type_'+row_ID).val() == 'product') return;

		for (var i=0; i<controls.length; i++) {
			var element = controls[i];
			if (element == 'quantity') requiredPkgProduct[element+'_'+row_ID] = { nonzero: true };
			if (element == 'description' && $('#ppd_'+row_ID).val() == 'product') requiredPkgProduct[element+'_'+row_ID] = { minlength: 2 };
			if (element == 'weight')
			{
				var unittypeid = $('#unittype').val();
				if (unittypeid == 18)
				      requiredPkgProduct[element+'_'+row_ID] = { numeric: false };
				else
				      requiredPkgProduct[element+'_'+row_ID] = { nonzero: true };
			}
		}
		});

	return !validateForm(requiredPkgProduct);
	}

function calculateDensity(row_ID)
	{
	var Weight = $("#weight_"+row_ID).val();
	var Quantity = $("#quantity_"+row_ID).val();
	var DimLength = $("#dimlength_"+row_ID).val();
	var DimWidth = $("#dimwidth_"+row_ID).val();
	var DimHeight = $("#dimheight_"+row_ID).val();

	if ( DimLength > 0 && DimWidth > 0 && DimHeight > 0  && Weight > 0 && Quantity > 0)
		{
		var Density = (( (Weight/Quantity) / ( DimLength * DimWidth * DimHeight ) ) * 1728 );
		$("#density_"+row_ID).val(Density.toFixed(2));

		var Class = $("#class_"+row_ID).val();
		var query_param = '&density='+Density;
		send_ajax_request('', 'JSON', 'order', 'get_freight_class', query_param, function (){
			if (JSON_data.freight_class) {
				$("#class_"+row_ID).val(JSON_data.freight_class);
				}
			});
		}
	}

function setSkuDetails(row_ID, sku_id)
	{
	var query_param = '&sku_id='+sku_id;

	if (sku_id.length > 0) {
		$("#description_"+row_ID).val('');
		send_ajax_request('', 'JSON', 'order', 'get_sku_detail', query_param, function () {
			if (JSON_data.error) {
				clearProductDetails(row_ID);
				} else {
				$("#description_"+row_ID).val(JSON_data.description);
				$("#unittype_"+row_ID).val(JSON_data.unittypeid);
				$("#weight_"+row_ID).val(JSON_data.weight);
				$("#dimlength_"+row_ID).val(JSON_data.length);
				$("#dimwidth_"+row_ID).val(JSON_data.width);
				$("#dimheight_"+row_ID).val(JSON_data.height);
				$("#nmfc_"+row_ID).val(JSON_data.nmfc);
				$("#class_"+row_ID).val(JSON_data.class);
				$("#decval_"+row_ID).val(JSON_data.value);
				if (JSON_data.unittypeid != "") $("#unittype_"+row_ID+" option:selected").val(JSON_data.unittypeid);
				configureShipmentDetails();
				}
			});

		calculateDensity(row_ID);
		} else {
		clearProductDetails(row_ID);
		}
	}

function updatePackageProductSequence()
	{
	var pkg_detail_row_count=0;

	$('input[id^=rownum_id_]').each(function( index ) {
		var row_id = this.id;

		var row_num = row_id.split('_')[2];
		$("#rownum_id_"+row_num).val(index+1);
		pkg_detail_row_count++;
		});

	//alert("pkg_detail_row_count: " + pkg_detail_row_count);
	$("#pkg_detail_row_count").val(pkg_detail_row_count);
	}

function clearProductDetails(row_ID)
	{
	$("#description_"+row_ID).val('');
	$("#weight_"+row_ID).val('');
	$("#dimlength_"+row_ID).val('');
	$("#dimwidth_"+row_ID).val('');
	$("#dimheight_"+row_ID).val('');
	$("#nmfc_"+row_ID).val('');
	$("#class_"+row_ID).val('');
	$("#density_"+row_ID).val('');
	$("#quantity_"+row_ID).val('1');
	}

function setCustomsCommodityValue()
	{
	if ($("#insurance").length == 0) return;
	var insurance = parseFloat($("#insurance").val());
	$("#commoditycustomsvalue").val(insurance.toFixed(2));
	$('#destinationcountry').val($('#tocountry').val());
	}

function checkInternationalSection()
	{

	if ($('#intlCommoditySec').length == 0) return;
	if ($("#tocountry").val() == '' || $("#fromcountry").val() == '') return;

	if ($("#tocountry").val() != $("#fromcountry").val()) {

		if ($('#intlCommoditySec').html().length > 0) {
			$("#intlCommoditySec").slideDown(1000, setCustomsCommodityValue);
			return;
			}

		var params = 'coid=' + $("#coid").val();
		send_ajax_request('intlCommoditySec', 'HTML', 'order', 'display_international', params, function (){
			$("#intlCommoditySec").slideDown(1000, setCustomsCommodityValue);
			$("#insurance").change(setCustomsCommodityValue);
			$("#freightinsurance").change(setCustomsCommodityValue);
			});
		} else {
		$("#intlCommoditySec").slideUp("slow");
		//$("#intlCommoditySec").empty();
		}
	}

var has_TP=false;
function checkDeliveryMethodSection()
	{
	resetCSList();

	if ($('input:radio[name=deliverymethod]:checked').val() == 2)
		{
		$("#third-party-details").dialog({
			show: { effect: "blind", duration: 1000 },
			hide: { effect: "explode", duration: 1000 },
			title: "Third Party Information",
			autoOpen: false,
			modal: true,
			width: '500px',
			buttons: {
				Save: function() {
					if (!validateForm({
							tpcompanyname : { minlength: 2, description: 'Company name missing' },
							tpaddress1    : { minlength: 2, description: 'Address 1 missing' },
							tpcity        : { minlength: 2, description: 'City missing' },
							tpstate       : { minlength: 2, description: 'State missing' },
							tpzip         : { minlength: 2, description: 'Zip code missing' },
							tpcountry     : { minlength: 2, description: 'Country missing' },
							tpacctnumber  : { minlength: 2, description: 'Account info missing' },
							})
						)
						{
						return;
						}

					var params = 'coid=' + $("#coid").val() + '&' + $("#frm_TP").serialize();
					//alert("PARAMS: " + params);

					send_ajax_request('', 'JSON', 'order', 'save_third_party_info', params, function () {
						if (JSON_data.UPDATED == 1) $("#third-party-details").dialog( "close" );
						});
					},
				Close: function() {
					$( this ).dialog( "close" );
					}
				}
		});

		if ($("#third-party-details").html().length > 0) {
			$("#third-party-details").dialog( "open" );
			} else {
			var params = 'coid=' + $("#coid").val() + '&thirdpartyacctid=' + $("#thirdpartyacctid").val();
			send_ajax_request('third-party-details', 'HTML', 'order', 'third_party_delivery', params, function () {
				$("#third-party-details").dialog( "open" );
				if ($("#thirdpartyacctid").val() != '') setTpDetails($("#thirdpartyacctid").val());
				});
			}
		}
	else
		{
		$("#thirdpartyacctid").val('0');
		}
	}

var has_FC=false;
function getCarrierServiceList(form_name)
	{
	$('#loading-1').css('background', 'url(/static/branding/engage/images/route-preload-white.GIF) no-repeat center center');
	$('#loading-2').css('background', 'url(/static/branding/engage/images/route-preload-white.GIF) no-repeat center center');

	$("#carrier-service-list").slideUp(1000, function() {

		updatePackageProductSequence();
		$('#carrier-service-list').empty();

		var params = $("#"+form_name).serialize();

		send_ajax_request('carrier-service-list', 'HTML', 'order', 'get_carrier_service_list', params, function() {

			$('#loading-1').css('background', 'url(/static/branding/engage/images/command-refresh-24.png) no-repeat center center');
			$('#loading-2').css('background', 'url(/static/branding/engage/images/command-refresh-24.png) no-repeat center center');

			has_FC=true;

			$("#carrier-service-list-tabs").tabs({ beforeActivate: function( event, ui ) {
					var panelID = $(ui.newPanel).prop('id');
					var customerserviceid = $( "input:radio[name=customerserviceid]:checked" ).val();
					$("#"+panelID+" input:radio[name=customerserviceid]").each(function() {
						if ($(this).val() == customerserviceid) $(this).prop('checked', true) ;
						});
					}
				});

			$("#carrier-service-list").slideDown(1000);
			});
		});
	}

function resetCSList()
	{
	$("#customerserviceid").val('');
	$("#carrier").val('');

	if (has_FC) $("#carrier-service-list").slideUp(1000);
	}

function addCheckBox(container_ID, control_ID, control_Value, control_Label)
	{
	var container = $("#" + container_ID);
	$('<input />', { type: 'checkbox', id: control_ID, name: control_ID, value: control_Value }).appendTo(container);
	$('<label />', { 'for': control_ID, text: control_Label }).appendTo(container);
	}

function CalculateDimentionalWeight(customerserviceid)
	{
	if ($("#dimweight_1").val() == undefined || customerserviceid == undefined || customerserviceid.length == 0) return;

	updatePackageProductSequence();
	var total_package_rows = $("#pkg_detail_row_count").val();
	for(var package_row=1; package_row <= total_package_rows; package_row++)
		{
		var query_param = '&row=' + package_row + '&CSID=' + customerserviceid + '&dimlength=' + $("#dimlength_" + package_row).val() + '&dimwidth=' + $("#dimwidth_" + package_row).val() + '&dimheight=' + $("#dimheight_" + package_row).val() + '&quantity=' + $("#quantity_" + package_row).val();

		send_ajax_request('', 'JSON', 'order', 'get_dim_weight', query_param, function() {
			$("#dimweight_" + JSON_data.row).val(JSON_data.dimweight);
			});
		}
	}

function addNewPackageProduct(package_id,type)
	{
	var pkg_detail_row_count=0;
	var product_table_id = 'product-list-' + package_id;
	$('input[name^="rownum_id_"]').each(function() {
		var arr = this.id.split('_');
		var count = +arr[2];
		pkg_detail_row_count = ( count > pkg_detail_row_count ? count : pkg_detail_row_count);
		});

	var query_param = '&row_ID=' + ++pkg_detail_row_count + '&detail_type=' + type + '&unittypeid=' + $("#unittype").val();

	send_ajax_request('', 'JSON', 'order', 'add_package_product_row', query_param, function (){

			if (type == 'package') $('#add-package-btn').before(JSON_data.rowHTML);
			if (type == 'product') $('#'+product_table_id+' > tbody:last').append(JSON_data.rowHTML);

			configureShipmentDetails(type);
			updatePackageProductSequence();
			});
	}
	
function populatePackageDefaultDetials(row_ID)
	{
	var query_param = '&unittypeid=' + $('#unittype_'+row_ID).val();

	send_ajax_request('', 'JSON', 'order', 'populate_package_default_detials', query_param, function (){

		$("#dimlength_"+row_ID).val(JSON_data.dimlength);
		$("#dimwidth_"+row_ID).val(JSON_data.dimwidth);
		$("#dimheight_"+row_ID).val(JSON_data.dimheight);
		$("#dimweight_"+row_ID).val(0);
		$("#weightperpackage-"+row_ID).html("Weight Per " + JSON_data.PACKAGE_TYPE);
		});
	}

function calculateTotalWeight(event_row_ID)
	{
	var packageWeights = {};
	var ParentPackageID=BillablePackageWeight=TotalProductWeight=0;

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type == 'package')
			{
			var OldPackageWeight = +$("#weight_"+ParentPackageID).val();
			if (ParentPackageID > 0) packageWeights[ParentPackageID] = (OldPackageWeight > TotalProductWeight ? OldPackageWeight.toFixed(2) : TotalProductWeight.toFixed(2));
			ParentPackageID=row_ID;
			var PackageWeight = parseInt($("#weight_"+row_ID).val());
			if (isNaN(PackageWeight)) PackageWeight=0;
			TotalProductWeight=0;
			}
		else
			{
			if (packageWeights[ParentPackageID] == undefined) packageWeights[ParentPackageID] = 0;
			packageWeights[ParentPackageID] = +packageWeights[ParentPackageID] + +$("#weight_"+row_ID).val();
			TotalProductWeight += +$("#weight_"+row_ID).val();
			}
		});

	//alert("ParentPackageID : " + ParentPackageID + ", event_row_ID: " + event_row_ID + ", TotalProductWeight: " + TotalProductWeight);

	if (TotalProductWeight == 0 && $("#weight_"+ParentPackageID).val() > 0)
		{
		TotalProductWeight = +$("#weight_"+ParentPackageID).val();
		}

	if (ParentPackageID > 0 && TotalProductWeight > 0)
		{
		var OldPackageWeight = +$("#weight_"+ParentPackageID).val();

		if (packageWeights[ParentPackageID] == undefined) packageWeights[ParentPackageID] = 0;
		packageWeights[ParentPackageID] =  TotalProductWeight.toFixed(2);
		}

	//alert("packageWeights : " + JSON.stringify(packageWeights));

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type != 'package') return;

		var PackageWeight = isNaN(packageWeights[row_ID]) ? 0 : parseInt(packageWeights[row_ID]);
		if (isNaN(event_row_ID)) $("#weight_"+row_ID).val(PackageWeight.toFixed(2));

		//if (isNaN(PackageWeight)) PackageWeight=0;

		//alert("PackageWeight: " + PackageWeight + ", quantity_: " + $("#quantity_"+row_ID).val());

		var TotalPackageWeight = 0;

		if ($("#quantityxweight-"+row_ID).val() == 1)
			{
			TotalPackageWeight = +$("#weight_"+row_ID).val();
			}
		else
			{
			TotalPackageWeight = +$("#quantity_"+row_ID).val() * PackageWeight;
			}

		if ($("#dimweight_"+row_ID).val() > TotalPackageWeight)
			{
			TotalPackageWeight = +$("#dimweight_"+row_ID).val();
			}

		BillablePackageWeight += TotalPackageWeight;
		});

	$("#totalweight").val(BillablePackageWeight.toFixed(2));

	updateShipmentSummary();
	}

function calculateTotalDeclaredValueInsurance()
	{
	var ParentPackageID=TotalDeclaredInsurance=TotalProductDeclaredInsurance=0;

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type == 'package')
			{
			if (ParentPackageID > 0) $("#decval_"+ParentPackageID).val(TotalProductDeclaredInsurance);
			TotalProductDeclaredInsurance=0
			ParentPackageID=row_ID;
			}
		else
			{
			TotalProductDeclaredInsurance += +$("#decval_"+row_ID).val();
			}
		});

	if (ParentPackageID > 0 && TotalProductDeclaredInsurance > 0) $("#decval_"+ParentPackageID).val(TotalProductDeclaredInsurance);

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type != 'package') return;

		TotalDeclaredInsurance += +$("#decval_"+row_ID).val();
		});

	$('#insurance').val(TotalDeclaredInsurance.toFixed(2));
	}

function distributeInsuranceAmongProducts()
	{
	var insurance_value = +$("#insurance").val();

	if (insurance_value == 0) return;

	var PackageProductsCountDetails = {};
	var TotalPackageCount=TotalProductCount=PackageProductCount=ParentPackageID=ValuePerPackage=ValuePerProduct=0;

	var control_type = 'decval';

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type == 'package')
			{
			if (ParentPackageID > 0) {
				//alert("Package ID: " + ParentPackageID + ", PackageProductCount: " + PackageProductCount);
				PackageProductsCountDetails[ParentPackageID] = +PackageProductCount;
				}
			ParentPackageID=row_ID;
			PackageProductCount=0
			++TotalPackageCount;
			}
		else
			{
			++PackageProductCount;
			++TotalProductCount;
			}
		});

	if (TotalProductCount==0) TotalProductCount = 1; //Set default product count to 1 if no product
	if (PackageProductCount==0) PackageProductCount = 1; //Set default package product count to 1 if no product

	if (ParentPackageID > 0) {
		//alert("Package ID: " + ParentPackageID + ", PackageProductCount: " + PackageProductCount);
		PackageProductsCountDetails[ParentPackageID] = +PackageProductCount;
		}

	ValuePerProduct = +insurance_value / +TotalProductCount;

	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		//alert("Row ID: " + row_ID);
		if (type == 'package')
			{
			ValuePerPackage = +ValuePerProduct * +PackageProductsCountDetails[row_ID];
			//alert("ValuePerProduct: " + ValuePerProduct + ", PackageProductsCountDetails: " + PackageProductsCountDetails[row_ID] + ", ValuePerPackage: " + ValuePerPackage);
			$("#"+control_type+"_"+row_ID).val(ValuePerPackage.toFixed(2));
			}
		else
			{
			$("#"+control_type+"_"+row_ID).val(ValuePerProduct.toFixed(2));
			}
		});
	}

function updateShipmentSummary()
	{
	$('input[id^=rownum_id_]').each(function() {

		var res = this.id.split('_');
		var row_ID = res[2];
		var type = $("#type_"+row_ID).val();

		if (type != 'package') return;

		var packageClass = $("#class_"+row_ID).val();
		var packageQuantity = +$("#quantity_"+row_ID).val();
		var packageWeight = (+$("#weight_"+row_ID).val() > +$("#dimweight_"+row_ID).val() ? +$("#weight_"+row_ID).val() : +$("#dimweight_"+row_ID).val());
		var packageValue = +$("#decval_"+row_ID).val();

		if ($("#quantityxweight-"+row_ID).val() == 0) packageWeight = (packageQuantity * packageWeight);

		$("#ss-class-"+row_ID).text(packageClass == '' ? 'NA' :packageClass);
		$("#ss-quantity-"+row_ID).text(packageQuantity == '' ? '0' : packageQuantity);
		$("#ss-weight-"+row_ID).text(packageWeight == '' ? '0.00' : packageWeight.toFixed(2));
		$("#ss-decval-"+row_ID).text(packageValue == '' ? '0.00' : packageValue.toFixed(2));
		});
	}

function removePackageDetails(row_ID)
	{
	$("#package-"+row_ID).remove();
	$("#ss-row-"+row_ID).remove();
	distributeInsuranceAmongProducts();
	}

function configureShipmentDetails(type)
	{
	resetCSList();
	calculateTotalWeight();
	if(type == undefined)
		{
		distributeInsuranceAmongProducts();
		}
	calculateTotalDeclaredValueInsurance();
	setCustomsCommodityValue();
	updateShipmentSummary();
	}

function populateSpecialServiceList() {

	if (!isEmpty("special-requirements")) return $("#special-requirements").dialog( "open" );

	$("#special-requirements").dialog({
			show: { effect: "blind", duration: 1000 },
			hide: { effect: "explode", duration: 1000 },
			title: "Select Special Service",
			autoOpen: false,
			modal: true,
			width: '800px',
			buttons: {
				Add: function() {
					var boolCloseWindow=false;
					$('#special-requirements input:checkbox:checked').each(function(){
						//addCheckBox('selected-special-requirements', this.id, $(this).val(), $(this).first().next('label').text());
						$('#selected-special-requirements').append("<div id='div_"+this.id+"' style='display: inline'>"+$("#td_" + this.id).html()+"</div>");
						$('#selected-special-requirements').slideDown(1000);
						$("#td_" + this.id).empty();
						$("#" + this.id).attr("checked", true);
						$("#" + this.id).click(function() {
							if (!$(this).is(':checked')) {
								$("#td_" + this.id).html($("#div_" + this.id).html());
								$("#div_" + this.id).remove();
								$("#" + this.id).attr("checked", false);
								}
							});
						resetCSList();
						boolCloseWindow=true;
						});
					if (boolCloseWindow) $( this ).dialog( "close" );
					},
				Close: function() {
					$( this ).dialog( "close" );
					}
				}
		});

	var params = 'coid=' + $("#coid").val();

	send_ajax_request('special-requirements', 'HTML', 'order', 'get_special_service_list', params, function (){
		$( "#special-requirements" ).dialog( "open" );
		});
	}
