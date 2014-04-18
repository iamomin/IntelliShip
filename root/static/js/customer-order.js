var requiredFieldHash = {};

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
	var country			= direction ? $('#' + direction + 'country').val() : '';
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
function ConfigureAddressSection(address, direction, type)
	{
	var editable     = (type == 'EDITABLE' ? true : false);
	var add_class    = (editable ? 'broad-text' : 'labellike');
	var remove_class = (editable ? 'labellike' : 'broad-text');

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
		$('#'+targetCtrl).prop('width', $('#'+targetCtrl).val().length);
		});
		RestoreAddress(address, direction, type);
	}

var addressArray  = {};
var previousCheck;
var fieldArray = ['name', 'address1', 'address2', 'city', 'state', 'zip', 'country', 'contact', 'phone', 'department', 'customernumber', 'email'];
function ConfigureInboundOutboundDropship()
	{
	
	var selectedType = $('input:radio[name=shipmenttype]:checked').val();
	
	if (previousCheck == 'outbound')
		{
		addressArray['COMPANY_ADDRESS'] = GetAddress('from');
		addressArray['ADDRESS_1'] = GetAddress('to');
		}
	else if (previousCheck == 'inbound')
		{
		addressArray['ADDRESS_1'] = GetAddress('from');
		addressArray['COMPANY_ADDRESS'] = GetAddress('to');
		}
	else
		{
		addressArray['ADDRESS_1'] = GetAddress('from');
		addressArray['ADDRESS_2'] = GetAddress('to');
		}

	if (selectedType == 'inbound')
		{
		$('#fromdepartment_tr').hide();
		$('#todepartment_tr').show();
		$('#fromcustomernumber_tr').show();
		$('#tocustomernumber_tr').hide();
		ConfigureAddressSection('COMPANY_ADDRESS', 'to', 'READONLY');
		ConfigureAddressSection('ADDRESS_1', 'from', 'EDITABLE');
		

		//RestoreAddress('COMPANY_ADDRESS', 'to');
		//RestoreAddress('ADDRESS_1','from');
		}
	else if(selectedType == 'outbound')
		{

		$('#fromdepartment_tr').show();
		$('#todepartment_tr').hide();
		$('#fromcustomernumber_tr').hide();
		$('#tocustomernumber_tr').show();
		ConfigureAddressSection('ADDRESS_1', 'to', 'EDITABLE');
		ConfigureAddressSection('COMPANY_ADDRESS', 'from', 'READONLY');
		

		//RestoreAddress('COMPANY_ADDRESS', 'from');
		//RestoreAddress('ADDRESS_1','to');
		}
	else if(selectedType == 'dropship')
		{
		$('#fromdepartment_tr').show();
		$('#todepartment_tr').hide();
		$('#fromcustomernumber_tr').hide();
		$('#tocustomernumber_tr').show();
		
		ConfigureAddressSection('ADDRESS_1', 'from', 'EDITABLE');
		ConfigureAddressSection('ADDRESS_2', 'to', 'EDITABLE');

		//RestoreAddress('ADDRESS_1', 'from');
		//RestoreAddress('ADDRESS_2','to');
		}

	previousCheck = selectedType;
	}
/*
########################################################################################
*/

function check_due_date()
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

function add_pkg_detail_row(detail_type)
	{
	var pkg_detail_row_count=0;
	$('#package-detail-list li').each(function() { if (this.id.match(/^new_/)) pkg_detail_row_count++ });
	var query_param = '&row_ID=' + ++pkg_detail_row_count + '&detail_type=' + detail_type;

	$("#add_package_product").attr("disabled", true);
	send_ajax_request('', 'JSON', 'order', 'add_pkg_detail_row', query_param, function (){
			add_new_row('package-detail-list', JSON_data.rowHTML);
			$("#add_package_product").attr("disabled", false);
			});
	}

function calculate_density(row_ID)
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

function calculate_total_packages()
	{
	var TotalQuantity = 0;

	$("#package-detail-list li").each(function() {
		var row_id = this.id;

		if (row_id.match(/^new_package/))
			{
			var row_ID = row_id.split('_')[2];
			var Quantity = parseInt($("#quantity_"+row_ID).val());
			Quantity = (isNaN(Quantity) ? 0 : Quantity);
			TotalQuantity += Quantity;
			}
		});

	$("#totalpackages").val(TotalQuantity);
	}

function calculate_total_weight(event_row_ID)
	{
	var ParentPackageID=TotalPackageWeight=TotalProductWeight=0;

	$('#package-detail-list li').each(function() {

		if (!isNaN(event_row_ID) && $("#type_"+event_row_ID).val() == 'package') return;
		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type == 'package')
			{
			if (ParentPackageID > 0) $("#weight_"+ParentPackageID).val(TotalProductWeight);
			ParentPackageID=row_ID;
			var PackageWeight = parseInt($("#weight_"+row_ID).val());
			if (isNaN(PackageWeight)) PackageWeight=0;
			TotalProductWeight=0;
			}
		else
			{
			TotalProductWeight += +$("#weight_"+row_ID).val();
			}
		});

	if (ParentPackageID > 0 && TotalProductWeight > 0) {
		$("#weight_"+ParentPackageID).val(TotalProductWeight);
		}

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type != 'package') return;

		var PackageWeight = parseInt($("#weight_"+row_ID).val());
		if (isNaN(PackageWeight)) PackageWeight=0;

		if ($("#quantityxweight").is(':checked'))
			{
			var Quantity = +$("#quantity_"+row_ID).val();
			TotalPackageWeight += PackageWeight * Quantity;
			}
		else
			{
			TotalPackageWeight += PackageWeight;
			}
		});

	$("#totalweight").val(TotalPackageWeight.toFixed(2));
	}

function calculate_total_declared_value_insurance()
	{
	var ParentPackageID=TotalDeclaredInsurance=TotalProductDeclaredInsurance=0;

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

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

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type != 'package') return;

		TotalDeclaredInsurance += +$("#decval_"+row_ID).val();
		});

	$('#insurance').val(TotalDeclaredInsurance.toFixed(2));
	}

function calculate_total_freight_insurance()
	{
	var ParentPackageID=TotalFreightInsurance=TotalProductFreightInsurance=0;

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type == 'package')
			{
			if (ParentPackageID > 0) $("#frtins_"+ParentPackageID).val(TotalProductFreightInsurance);
			TotalProductFreightInsurance=0
			ParentPackageID=row_ID;
			}
		else
			{
			TotalProductFreightInsurance += +$("#frtins_"+row_ID).val();
			}
		});

	if (ParentPackageID > 0 && TotalProductFreightInsurance > 0) $("#frtins_"+ParentPackageID).val(TotalProductFreightInsurance);

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type != 'package') return;

		TotalFreightInsurance += +$("#frtins_"+row_ID).val();
		});

	$('#freightinsurance').val(TotalFreightInsurance.toFixed(2));
	}

function distribute_insurance_among_products()
	{
	var insurance_type = this.id;
	var insurance_value = +$(this).val();

	if (insurance_value == 0) return;

	var PackageProductsCountDetails = {};
	var TotalPackageCount=TotalProductCount=PackageProductCount=ParentPackageID=ValuePerPackage=ValuePerProduct=0;

	var control_type = (insurance_type == 'freightinsurance' ? 'frtins' : 'decval');

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

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

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

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

function setSkuDetails(row_ID, sku_id)
	{
	var query_param = '&sku_id='+sku_id;

	if (sku_id > 0) {
		$("#description_"+row_ID).val('');
		send_ajax_request('', 'JSON', 'order', 'get_sku_detail', query_param, function () {
			if (JSON_data.error) {
				clear_product_details(row_ID);
				} else {
				$("#description_"+row_ID).val(JSON_data.description);
				$("#weight_"+row_ID).val(JSON_data.weight);
				$("#dimlength_"+row_ID).val(JSON_data.length);
				$("#dimwidth_"+row_ID).val(JSON_data.width);
				$("#dimheight_"+row_ID).val(JSON_data.height);
				$("#nmfc_"+row_ID).val(JSON_data.nmfc);
				//$("#class_"+row_ID).val(JSON_data.class);
				if (JSON_data.unittypeid != "") $("#unittype_"+row_ID+" option:selected").val(JSON_data.unittypeid);
				}
			});

		calculate_density(row_ID);
		} else {
		clear_product_details(row_ID);
		}
	}

function clear_product_details(row_ID)
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

function update_package_product_sequence()
	{
	var pkg_detail_row_count=0;

	$('#package-detail-list li').each(function( index ) {
		var row_id = this.id;
		if (row_id.match(/^new_/))
			{
			var row_num = row_id.split('_')[2];
			$("#rownum_id_"+row_num).val(index);
			pkg_detail_row_count++;
			}
		});

	//alert("pkg_detail_row_count:  " + pkg_detail_row_count);
	$("#pkg_detail_row_count").val(pkg_detail_row_count);
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
			/*
				Save: function() {
					//$("#special-requirements > .ui-button-text").text("Please Wait...");
					var params = $("#frm_SC").serialize();
					if (params == "") {
						$("#sc_error").html("Please select at least one special service");
						$("#sc_error").addClass("ui-state-error");
						return;
						} else {
						$("#sc_error").html("");
						if ($("#sc_error").hasClass('ui-state-error')) $("#sc_error").removeClass('ui-state-error');
						}
					params = 'coid=' + $("#coid").val() + '&' + params;
					//alert("PARAMS: " + params);

					send_ajax_request('', 'JSON', 'order', 'save_special_services', params, function () {
						if (JSON_data.UPDATED == 1) $("#special-requirements").dialog( "close" );
						});
					},
				*/
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

	//$('#selected-special-requirements input:checkbox:checked').each(function(){
	//	params += '&' + this.id + '=1';
	//	});
	//alert("PARAMS: " + params);

	send_ajax_request('special-requirements', 'HTML', 'order', 'get_special_service_list', params, function (){
		$( "#special-requirements" ).dialog( "open" );
		});
	}

function setCustomsCommodityValue()
	{
	if ($("#insurance").length == 0 && $("#freightinsurance").length == 0) return;

	var insurance = parseFloat($("#insurance").val());
	var freightinsurance = parseFloat($("#freightinsurance").val());
	var commoditycustomsvalue = (insurance > freightinsurance ? insurance : freightinsurance);
	$("#commoditycustomsvalue").val(commoditycustomsvalue.toFixed(2));
	}

function checkInternationalSection() {

	if ($('#intlCommoditySec').length == 0) return;

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

function setCityAndState(type)
	{
	var tozip = $("#"+type+"zip").val();
	if (tozip.length < 5) return;

	//$("#tocity").val('');
	//$("#tostate").val('');
	//$("#tocountry").val('');

	var query_param = "&zipcode=" + tozip + '&city=' + $("#"+type+"city").val() + '&state=' + $("#"+type+"state").val() + '&country=' + $("#"+type+"country").val();
	if($("#"+type+"zip").val() != "") {
		send_ajax_request('', 'JSON', 'order', 'get_city_state', query_param, function () {
			$("#"+type+"city").val(JSON_data.city);
			$("#"+type+"state").val(JSON_data.state);
			$("#"+type+"country").val(JSON_data.country);
			if ($("#fromstatespan").length && type == 'from') $("#fromstatespan").text(JSON_data.state);
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

function validate_package_details()
	{
	var boolInvalidData=false;
	//var controls = ['quantity', 'sku', 'weight', 'dimlength', 'dimwidth', 'dimheight'];
	var controls = ['quantity', 'description', 'weight'];

	var requiredPkgProduct = {};
	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var row_ID = this.id.split('_')[2];

		if ($('#type_'+row_ID).val() == 'product') return;

		for (var i=0; i<controls.length; i++) {
			var element = controls[i];
			if (element == 'quantity') requiredPkgProduct[element+'_'+row_ID] = { nonzero: true };
			if (element == 'description' && $('#ppd_'+row_ID).val() == 'product') requiredPkgProduct[element+'_'+row_ID] = { minlength: 2 };
			if (element == 'weight') requiredPkgProduct[element+'_'+row_ID] = { nonzero: true };
			}
		});

	return !validateForm(requiredPkgProduct);
	}

function update_package_product_details(event, ui)
	{
	var old_position = ui.item.data("old");
	var new_position = $("#package-detail-list li").index(ui.item);
	var change = +new_position - +old_position;
	if (change == 0) return;

	var ParentPackageID=0;
	var pkg_detail_row_count=0;
	var ProductTotal=DeclValTotal=FreightInsTotal=0;

	$('#package-detail-list li').each(function(index) {

		if (!this.id.match(/^new_/)) return;

		pkg_detail_row_count++;

		var res = this.id.split('_');
		var type = res[1];
		var row_ID = res[2];

		if (type == 'package')
			{
			if (ParentPackageID > 0) $("#weight_"+ParentPackageID).val(ProductTotal.toFixed(2));
			if (ParentPackageID > 0) $("#decval_"+ParentPackageID).val(DeclValTotal.toFixed(2));
			if (ParentPackageID > 0) $("#frtins_"+ParentPackageID).val(FreightInsTotal.toFixed(2));

			ParentPackageID=row_ID;
			ProductTotal=DeclValTotal=FreightInsTotal=0;
			}
		else
			{
			var ProductWeight = +$("#weight_"+row_ID).val();
			ProductTotal += ProductWeight;

			var DeclVal = +$("#decval_"+row_ID).val();
			DeclValTotal += DeclVal;

			var FreightIns = +$("#frtins_"+row_ID).val();
			FreightInsTotal += FreightIns;

			$("#rownum_id_"+row_ID).val(index);
			}

		});

	if (ParentPackageID > 0) {
		$("#weight_"+ParentPackageID).val(ProductTotal.toFixed(2));
		$("#decval_"+ParentPackageID).val(DeclValTotal.toFixed(2));
		$("#frtins_"+ParentPackageID).val(FreightInsTotal.toFixed(2));
		}

	$("#pkg_detail_row_count").val(pkg_detail_row_count);
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
function get_customer_service_list(form_name)
	{
	//var origVal = $("#route").val();
	//$("#route").attr("disabled",true);
	//$("#route").val("Please Wait...");

	$("#carrier-service-list").slideUp(1000, function() {

		$('#carrier-service-list').empty();

		var params = $("#"+form_name).serialize();

		send_ajax_request('carrier-service-list', 'HTML', 'order', 'get_carrier_service_list', params, function() {

			//$("#route").attr("disabled",false);
			//$("#route").val(origVal);
			has_FC=true;

			$("#carrier-service-list").tabs({ beforeActivate: function( event, ui ) {
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

function CalculateDimentionalWeight(customerserviceid)
	{
	if ($("#dimweight_1").val() == undefined || customerserviceid == undefined || customerserviceid.length == 0) return;

	update_package_product_sequence();
	var total_package_rows = $("#pkg_detail_row_count").val();
	for(var package_row=1; package_row <= total_package_rows; package_row++)
		{
		var query_param = '&row=' + package_row + '&CSID=' + customerserviceid + '&dimlength=' + $("#dimlength_" + package_row).val() + '&dimwidth=' + $("#dimwidth_" + package_row).val() + '&dimheight=' + $("#dimheight_" + package_row).val();

		send_ajax_request('', 'JSON', 'order', 'get_dim_weight', query_param, function() {
			$("#dimweight_" + JSON_data.row).val(JSON_data.dimweight);
			});
		}
	}

function addNewPackageProduct(package_id,type)
	{
	var pkg_detail_row_count=0;
	var product_table_id = 'product-list-' + package_id;
	$('input[name^="type_"]').each(function() { var arr = this.id.split('_'); pkg_detail_row_count = (arr[1] > pkg_detail_row_count ? arr[1] : pkg_detail_row_count); });

	var query_param = '&row_ID=' + ++pkg_detail_row_count + '&detail_type=' + type;

	send_ajax_request('', 'JSON', 'order', 'add_package_product_row', query_param, function (){

			if (type == 'package') $('#add-package-btn').before(JSON_data.rowHTML);
			if (type == 'product') $('#'+product_table_id+' > tbody:last').append(JSON_data.rowHTML);

			updatePackageProductSequence();
			});
	}

function updatePackageProductSequence()
	{
	var pkg_detail_row_count=0;

	$('input[id^=rownum_id_]').each(function( index ) {
		var row_id = this.id;
		alert("row_id : " + row_id);

		var row_num = row_id.split('_')[2];
		$("#rownum_id_"+row_num).val(index+1);
		pkg_detail_row_count++;
		});

	alert("pkg_detail_row_count:  " + pkg_detail_row_count);
	$("#pkg_detail_row_count").val(pkg_detail_row_count);
	}
