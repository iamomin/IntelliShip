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

function RestoreAddress(address, direction)
	{
	$('#' + direction + 'name').val(addressArray[address].name);
	$('#' + direction + 'address1').val(addressArray[address].address1);
	$('#' + direction + 'address2').val(addressArray[address].address2);
	$('#' + direction + 'city').val(addressArray[address].city);
	$('#' + direction + 'city').next("span").text($('#' + direction + 'city').val());
	$('#' + direction + 'state').val(addressArray[address].state);
	$('#' + direction + 'state').next("span").text($('#' + direction + 'state').val());
	$('#' + direction + 'zip').val(addressArray[address].zip);
	$('#' + direction + 'country').val(addressArray[address].country);
	$('#' + direction + 'contact').val(addressArray[address].contact);
	$('#' + direction + 'phone').val(addressArray[address].phone);

	$('#' + direction + 'department').val(addressArray[address].department);
	$('#' + direction + 'customernumber').val(addressArray[address].customernumber);
	$('#' + direction + 'email').val(addressArray[address].email);
	}

var from_to_Hash = {};
function ConfigureAddressSection(direction,type)
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
				$('#'+targetDiv).html(inputCtrl + '<span class="labellike">' + $('#'+targetCtrl).val() + "</span>,");
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
	}

var addressArray  = {};
var previousCheck = 'outbound';
var fieldArray = ['name', 'address1', 'address2', 'city', 'state', 'zip', 'country', 'contact', 'phone', 'department', 'customernumber', 'email'];
function ConfigureInboundOutboundDropship()
	{
	
	var selectedType = $('input:radio[name=shipmenttype]:checked').val();
	
	if(selectedType == previousCheck) return;
	
	if (previousCheck == 'outbound')
		{
		addressArray['ADDRESS_1'] = GetAddress('to');
		}
	else if (previousCheck == 'inbound')
		{
		addressArray['ADDRESS_1'] = GetAddress('from');
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

		ConfigureAddressSection('from', 'EDITABLE');
		ConfigureAddressSection('to', 'READONLY');

		RestoreAddress('COMPANY_ADDRESS', 'to');
		RestoreAddress('ADDRESS_1','from');
		}
	else if(selectedType == 'outbound')
		{

		$('#fromdepartment_tr').show();
		$('#todepartment_tr').hide();
		$('#fromcustomernumber_tr').hide();
		$('#tocustomernumber_tr').show();

		ConfigureAddressSection('from', 'READONLY');
		ConfigureAddressSection('to', 'EDITABLE');

		RestoreAddress('COMPANY_ADDRESS', 'from');
		RestoreAddress('ADDRESS_1','to');
		}
	else if(selectedType == 'dropship')
		{
		ConfigureAddressSection('from', 'EDITABLE');
		ConfigureAddressSection('to', 'EDITABLE');

		RestoreAddress('ADDRESS_1', 'from');
		RestoreAddress('ADDRESS_2','to');
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
	var customscommodityvalue = (insurance > freightinsurance ? insurance : freightinsurance);
	$("#customscommodityvalue").val(customscommodityvalue.toFixed(2));
	}

function checkInternationalSection() {

	if ($('#intlCommoditySec').length == 0) return;

	if ($("#tocountry").val() != $("#fromcountry").val()) {

		if ($('#intlCommoditySec').html().length > 0) {
			$("#intlCommoditySec").slideDown(1000, setCustomsCommodityValue);
			return;
			}
		send_ajax_request('intlCommoditySec', 'HTML', 'order', 'display_international', '', function (){
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
/*
	if($('input:radio[name=deliverymethod]:checked').val() == "3rdparty")
		{
		if(has_TP) {
			$(".tp").show(1000);
		} else
		send_ajax_request('', 'JSON', 'order', 'third_party_delivery', "", function () {
			if (JSON_data.rowHTML) $(JSON_data.rowHTML).insertAfter("#delivery_method_table tr:first");
			has_TP = true;
			});
		}
	else
		{
		if(has_TP) {
			$(".tp").slideUp(1000);
			}
		}
*/
	/* deliverymethod,
		0: Prepaid
		1: Collect
		2: Third party
	*/
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
	var origVal = $("#route").val();
	$("#route").attr("disabled",true);
	$("#route").val("Please Wait...");

	$("#service-level-summary").slideUp(1000, function() {

		$('#service-level-summary').empty();

		var params = $("#"+form_name).serialize();

		send_ajax_request('service-level-summary', 'HTML', 'order', 'get_carrier_service_list', params, function() {

			$("#route").attr("disabled",false);
			$("#route").val(origVal);
			has_FC=true;

			$("#carrier-service-list").tabs({ beforeActivate: function( event, ui ) {
					var panelID = $(ui.newPanel).prop('id');
					var customerserviceid = $( "input:radio[name=customerserviceid]:checked" ).val();
					$("#"+panelID+" input:radio[name=customerserviceid]").each(function() {
						if ($(this).val() == customerserviceid) $(this).prop('checked', true) ;
						});
					}
				});

			$("#service-level-summary").slideDown(1000);
			});
		});
	}

function resetCSList()
	{
	$("#customerserviceid").val('');
	$("#carrier").val('');

	if (has_FC) $("#service-level-summary").slideUp(1000);
	}

function sortTableData(table_ID, column_1, col_TYPE_1, order_BY_1, column_2, col_TYPE_2, order_BY_2)
	{
	var rows = $('#'+table_ID+' tbody  tr.sc-sortable').get();

	rows.sort(function(a, b) {
		var A = $(a).children('td').eq(column_1).text().toUpperCase();
		var B = $(b).children('td').eq(column_1).text().toUpperCase();
		//alert("a: |" + A + "|, b: |" + B + "|");

		var second_check_required = (column_2 != undefined) && (col_TYPE_1 == 'numeric' ? (+A == +B) : (A == B));

		if (second_check_required)
			{
			//alert('SECOND CHECK REQUIRED');
			var C = $(a).children('td').eq(column_2).text().toUpperCase();
			var D = $(b).children('td').eq(column_2).text().toUpperCase();

			return (order_BY_2 == 'desc' ? compareValues(col_TYPE_2, C, D) : !compareValues(col_TYPE_2, C, D));
			}
		else
			{
			return (order_BY_1 == 'desc' ? compareValues(col_TYPE_1, A, B) : !compareValues(col_TYPE_1, A, B));
			}
		});

	$.each(rows, function(index, row) {
		$('#'+table_ID).children('tbody').append(row);
		});
	}

function compareValues(type, Val_1, Val_2)
	{
	return (type == 'numeric' ? (+Val_1 > +Val_2) : (Val_1 > Val_2));
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

function CSSelectFunctions()
	{
	var value ;

	set_cs_value(value);
//	set_saturday_sticker_display();
//	set_tracking_display();
//	set_delivery_warning_display();
//	set_fc_override();
//	calculate_shipment_charges(index);
//	display_pickup_request();
//	calculate_dimweights(value);
//	calculate_aggregate_weight_total();
//
//	set_billing_account_display();
//	set_billing_account();
//	set_billing_address_display();
//	dry_ice_display();

// setdaterouted();
// displaysecuritytypes();
// setdefaultdates('csselect');
	}

//function set_cs_value(cs_id)
//	{
//	if ( '<var name=loginlevel>' == '20' )
//		{
//		return;
//		}
//
//	if ( cs_id == '' || cs_id == 0 )
//		{
//		return;
//		}
//
//	if (req)
//		{
//		url = "index.cgi?screen=ajax&action=GetCSValues&tokenid=<var name=tokenid>&randomnumber=<var name=randomnumber>&arg1=" + CSID;
//
//		req.open("GET", url, false);
//
//		req.onreadystatechange = function()
//			{
//			if ( req.readyState == 4 )
//				{
//				if ( req.responseText != "0\n" )
//					{
//					var ResponseString = req.responseText.substr(0,req.responseText.length - 1);
//					var CSValues = ResponseString.split("\t");
//					document.shipconfirm.allowcod.value = CSValues[0];
//					document.shipconfirm.codfee.value = CSValues[2];
//					document.shipconfirm.cutofftime.value = CSValues[5];
//					document.shipconfirm.decvalinsmax.value = CSValues[6];
//					document.shipconfirm.decvalinsmaxperlb.value = CSValues[7];
//					document.shipconfirm.decvalinsmin.value = CSValues[8];
//					document.shipconfirm.decvalinsmincharge.value = CSValues[9];
//					document.shipconfirm.decvalinsrate.value = CSValues[10];
//					document.shipconfirm.dimfactor.value = CSValues[11];
//					document.shipconfirm.freightinsincrement.value = CSValues[12];
//					document.shipconfirm.freightinsrate.value = CSValues[13];
//					document.shipconfirm.fscrate.value = CSValues[14];
//					document.shipconfirm.pickuprequest.value = CSValues[18];
//					document.shipconfirm.servicetypeid.value = CSValues[21];
//					document.shipconfirm.valuedependentrate.value = CSValues[23];
//					document.shipconfirm.thirdpartyfreightcharge.value = CSValues[24];
//					document.shipconfirm.requirecollectaddress.value = CSValues[25];
//					document.shipconfirm.requirethirdpartyaddress.value = CSValues[26];
//					document.shipconfirm.dryice_cs.value = CSValues[27];
//					document.shipconfirm.aggregateweightcost.value = CSValues[28];
//					}
//				}
//			}
//		}
//	}
//
//function set_saturday_sticker_display()
//{
//	saturdaystickerdisplay.style.display = "none";
//
//	if
//	(
//		'<var name=pseudoscreen>' != 'view' &&
//		'<var name=loginlevel>' != '10' &&
//		'<var name=loginlevel>' != '15' &&
//		'<var name=loginlevel>' != '20' &&
//		'<var name=loginlevel>' != '25' &&
//		'<var name=vendorpologin>' != '1'
//	)
//	{
//		var regex = new RegExp("Airborne Express - Express Saturday");
//		var carrierservice = document.shipconfirm.customerserviceid.options[document.shipconfirm.customerserviceid.selectedIndex].text;
//
//   	if ( regex.test(carrierservice) )
//   	{
//      	saturdaystickerdisplay.style.display = "block";
//   	}
//	}
//}
//
//function set_tracking_display()
//{
//	var regex = new RegExp("Airborne Express - International Freight");
//
//	var carrierservice = '';
//	if ( '<var name=pseudoscreen>' != 'view' && '<var name=loginlevel>' != '25' && '<var name=vendorpologin>' != '1' )
//	{
//		carrierservice = document.shipconfirm.customerserviceid.options[document.shipconfirm.customerserviceid.selectedIndex].text;
//	}
//
//	if
//	(
//		(
//			regex.test(carrierservice) ||
//			'<var name=showtrackingfield>' == '1' ||
//			'<var name=usingaltsop>' == '1' ||
//			document.shipconfirm.usealtsop.checked == true ||
//			document.shipconfirm.freightcharges[1].checked == true ||
//			document.shipconfirm.freightcharges[2].checked == true ||
//			'<var name=pseudoscreen>' == 'view'
//		)
//		&&
//		( '<var name=loginlevel>' != '10' && '<var name=loginlevel>' != '20' && '<var name=loginlevel>' != '15' )
//	)
//	{
//		trackingdisplay.style.display = "block";
//		poddisplay.style.display = "block";
//
//		if ( '<var name=pseudoscreen>' != 'view' )
//		{
//			document.all("trackingnumbervalue").innerHTML =
//				'<input type=text maxlength="100" name=tracking1 value="<var name=tracking1>" tabindex=7010>';
//		}
//		else
//		{
//			document.all("trackingnumbervalue").innerHTML =
//				'<font color=0000ff face="Arial, Helvetica, sans-serif" size="2"><var name=tracking1></font>';
//		}
//	}
//	else
//	{
//		trackingdisplay.style.display = "none";
//		poddisplay.style.display = "none";
//	}
//}
//
//function set_delivery_warning_display()
//{
//	maydeliverlatedisplay.style.display = "none";
//
//	if ( '<var name=pseudoscreen>' != 'view' && '<var name=vendorpologin>' != '1' )
//	{
//		var regex = new RegExp("^\\*\\*");
//		var carrierservice = document.shipconfirm.customerserviceid.options[document.shipconfirm.customerserviceid.selectedIndex].text;
//
//		if ( regex.test(carrierservice) )
//		{
//			maydeliverlatedisplay.style.display = "block";
//		}
//	}
//}
//
//function set_fc_override()
//	{
//	if ( typeof(document.shipconfirm.fcoverride) != "undefined"  )
//		{
//		document.shipconfirm.fcoverride.value = '';
//		}
//	}
//
//function calculate_shipment_charges(SelectedCSIndex)
//	{
//	if ( '<var name=usealtsop>' == '1' || '<var name=loginlevel>' == '20' || '<var name=vendorpologin>' == '1' )
//		{
//		//alert("CalculateShipmentCharges CALL DisplayShipmentCharges");
//		DisplayShipmentCharges();
//		return;
//		}
//	document.shipconfirm.freightcharge.value = CalculateFreightCharge(SelectedCSIndex);
//	document.shipconfirm.fuelsurcharge.value = CalculateFuelSurcharge();
//	document.shipconfirm.declaredvalueinsurancecharge.value = CalculateDeclaredValueInsurance();
//	document.shipconfirm.freightinsurancecharge.value = CalculateFreightInsurance();
//
//	var TotalCharges = 0;
//	var Freight = 0;
////alert(Freight);
//	if ( parseFloat(document.shipconfirm.freightcharge.value) > 0 )
//		{
//		TotalCharges += parseFloat(document.shipconfirm.freightcharge.value);
//		Freight = TotalCharges;
////alert(Freight);
//		}
//
//	if ( parseFloat(document.shipconfirm.fuelsurcharge.value) > 0 )
//		{
//		TotalCharges += parseFloat(document.shipconfirm.fuelsurcharge.value);
//		}
//
//	if ( parseFloat(document.shipconfirm.declaredvalueinsurancecharge.value) )
//		{
//		TotalCharges += parseFloat(document.shipconfirm.declaredvalueinsurancecharge.value);
//		}
//
//	if ( parseFloat(document.shipconfirm.freightinsurancecharge.value) )
//		{
//		TotalCharges += parseFloat(document.shipconfirm.freightinsurancecharge.value);
//		}
//
//	if ( document.shipconfirm.billingaccount.value != '' && document.shipconfirm.billingaccount.value != undefined )
//		{
//		document.shipconfirm.freightcharge.value = ''
//		document.shipconfirm.fuelsurcharge.value = ''
//
//		TotalCharges = 0;
//		Freight = 0;
//		}
//
//	if
//		(
//		document.shipconfirm.declaredvalueinsurancecharge.value == 0 ||
//		(document.shipconfirm.billingaccount.value != '' && document.shipconfirm.billingaccount.value != undefined)
//		)
//		{
//		document.shipconfirm.declaredvalueinsurancecharge.value = '';
//		}
//
//	if
//		(
//		document.shipconfirm.freightinsurancecharge.value == 0 ||
//		(document.shipconfirm.billingaccount.value != '' && document.shipconfirm.billingaccount.value != undefined)
//		)
//		{
//		document.shipconfirm.freightinsurancecharge.value = '';
//		}
//
//   var CollectFreightCharge = document.shipconfirm.collectfreightcharge.value;
//	if
//		(
//		( CollectFreightCharge >= 0 && document.shipconfirm.freightcharges[1].checked == true )
//		&& (document.shipconfirm.billingaccount.value == '' || document.shipconfirm.billingaccount.value == undefined)
//		)
//		{
//		var CollectFreightChargeChargesObj = new Number(CollectFreightCharge);
//		document.shipconfirm.cfcharge.value = CollectFreightChargeChargesObj.toFixed(2);
//		TotalCharges += parseFloat(document.shipconfirm.cfcharge.value);
//		}
//	else
//		{
//		document.shipconfirm.cfcharge.value = '';
//		}
//
//	var AssessorialNames = new Array (<var name="assessorial_names">);
//
//	for ( var i=0; i<AssessorialNames.length; i++ )
//		{
//		//var thisassvalue = eval('document.shipconfirm.' + AssessorialNames[i] + ' != undefined');
//
//		//if ( eval('document.shipconfirm.' + AssessorialNames[i] + ' != undefined') )
//		//{
//			//eval('document.shipconfirm.' + AssessorialNames[i] + '.value = 0');
//		//}
//
//		if
//			(
//			eval('document.shipconfirm.' + AssessorialNames[i] + ' != undefined') &&
//			eval('document.shipconfirm.' + AssessorialNames[i] + '.checked == true')
//			)
//			{
//			//alert("CalculateAssCharges: " + AssessorialNames[i] + " freight_cost=" + Freight);
//			eval('CalculateAssessorialCharge("' + AssessorialNames[i] + '","' + Freight + '")');
//
//			if ( eval('parseFloat(document.shipconfirm.' + AssessorialNames[i] + '.value) > 0') )
//				{
//				TotalCharges += parseFloat(eval('document.shipconfirm.' + AssessorialNames[i] + '.value'));
//				}
//			}
//		}
//
//	// Calculate Total Charges
//	var TotalChargesObj = new Number(TotalCharges);
//	document.shipconfirm.totalshipmentcharges.value = TotalChargesObj.toFixed(2);
//
//	DisplayShipmentCharges();
//	DryIceDisplay();
//	}
//
//function display_pickup_request()
//	{
//	if ( typeof(document.shipconfirm.fcoverride) == "undefined" )
//		{
//		pickuprequestdisplay.style.display = "none";
//		return;
//		}
//
//	if
//	(
//		document.shipconfirm.pickuprequest.value > 0 &&
//		document.shipconfirm.customerserviceid.value != '' &&
//		document.shipconfirm.customerserviceid.value != '0' &&
//		'<var name=pseudoscreen>' != 'view' &&
//		'<var name=loginlevel>' != '10' &&
//		'<var name=loginlevel>' != '15' &&
//		'<var name=loginlevel>' != '20' &&
//		'<var name=loginlevel>' != '25'
//	)
//		{
//		pickuprequestdisplay.style.display = "block";
//
//		if ( document.shipconfirm.pickuprequest.value == 2 || document.shipconfirm.pickuprequest.value == 4 || document.shipconfirm.pickuprequest.value == 1)
//			{
//			document.shipconfirm.pickuprequest.checked = true;
//			}
//		}
//	else
//		{
//		document.shipconfirm.pickuprequest.checked = false;
//		pickuprequestdisplay.style.display = "none";
//		document.shipconfirm.codcheck[0].checked = false;
//		document.shipconfirm.codcheck[1].checked = false;
//		}
//	}
//
//function calculate_dimweights(cs_id)
//	{
//	var PPOrder = document.shipconfirm.pporder.value.split(",");
//	for ( var i = 1; i < PPOrder.length; i ++ )
//		{
//		CalculateDimWeight(PPOrder[i],CSID);
//		}
//	}
//
//function calculate_aggregate_weight_total()
//	{
//	// Don't do this for collect/3p...nothing good comes of it
//	if ( document.shipconfirm.freightcharges[1].checked == true || document.shipconfirm.freightcharges[2].checked == true )
//		{
//		return;
//		}
//
//	// Vendor logins and no customerserviceid...don't go here, or it'll just loop
//	if
//	(
//		'<var name=vendorpologin>' == 1 &&
//		document.shipconfirm.customerserviceid.value == ''
//	)
//		{
//		return;
//		}
//
//	setTimeout('ReallyCalculateAggregateWeightTotal()',750);
//	}
//
//function set_billing_account_display()
//	{
//	if
//	(
//		'<var name=myorders>' != '1' || '<var name=loginlevel>' == '10' ||
//		'<var name=loginlevel>' == '20' || '<var name=loginlevel>' == '15'
//	)
//		{
//		return
//		}
//
//	if ( document.shipconfirm.customerserviceid.value == document.shipconfirm.initcsid.value )
//		{
//		document.shipconfirm.daterouted.value = document.shipconfirm.initdaterouted.value;
//		}
//	else
//		{
//		if ( document.shipconfirm.customerserviceid.value != '' && document.shipconfirm.customerserviceid.value != '0' )
//			{
//			document.shipconfirm.daterouted.value = GetNow();
//			}
//		else
//			{
//			document.shipconfirm.daterouted.value = '';
//			}
//		}
//	}
//
//function set_billing_account()
//	{
////alert("SetBillingAccountDisplay");
//
//	var carrierservice = '';
//	if ( '<var name=pseudoscreen>' != 'view' && '<var name=loginlevel>' != '25' && '<var name=vendorpologin>' != '1' )
//		{
//		carrierservice = document.shipconfirm.customerserviceid.options[document.shipconfirm.customerserviceid.selectedIndex].text;
//		}
//	var regex = new RegExp("UPS -*");
//
//	if
//	(
//		( document.shipconfirm.freightcharges[1].checked == true || document.shipconfirm.freightcharges[2].checked == true ) &&
//		'<var name=loginlevel>' != '10' && '<var name=loginlevel>' != '20' && '<var name=loginlevel>' != '15'
//	)
//		{
////alert("... show billingaccount without route");
//		billingaccounttextbox.style.display = "block";
//		routebutton.style.display = "none";
//		}
//	else if ( document.shipconfirm.sibling.value == 1 && regex.test(carrierservice)  && '<var name=loginlevel>' != '10' && '<var name=loginlevel>' != '20' && '<var name=loginlevel>' != '15')
//		{
////alert("... show billingaccount with route");
//		billingaccounttextbox.style.display = "block";
//		}
//	else
//		{
////alert("... show route without billingaccount");
//		routebutton.style.display = "block";
//		billingaccounttextbox.style.display = "none";
//		thirdpartycompany.style.display = "none";
//		thirdpartyaddress1.style.display = "none";
//		thirdpartyaddress2.style.display = "none";
//		thirdpartycity.style.display = "none";
//		thirdpartystate.style.display = "none";
//		thirdpartyzip.style.display = "none";
//		thirdpartycountry.style.display = "none";
//		thirdpartyspacer.style.display = "none";
//
//		if ( '<var name=shipmentid>' == '' && '<var name=loginlevel>' != '25' )
//			{
//			document.shipconfirm.billingaccount.value = '';
//			document.shipconfirm.tpcompanyname.value = '';
//			document.shipconfirm.tpaddress1.value = '';
//			document.shipconfirm.tpaddress2.value = '';
//			document.shipconfirm.tpcity.value = '';
//			document.shipconfirm.tpstate.value = '';
//			document.shipconfirm.tpzip.value = '';
//			document.shipconfirm.tpcountry.value = '';
//			}
//		}
//	}
//
//function set_billing_address_display()
//	{
//	var CSID = document.shipconfirm.customerserviceid.value;
//
//	if ( (document.shipconfirm.freightcharges[1].checked == true || document.shipconfirm.freightcharges[2].checked == true) )
//		{
//		if ( document.shipconfirm.manualthirdparty.value == 0 )
//			{
//			if ( CSID == '' || CSID == '0' )
//				{
//				return;
//				}
//			if (req)
//				{
//				url = "index.cgi?screen=ajax&action=GetBillingAccount&tokenid=<var name=tokenid>&randomnumber=<var name=randomnumber>&arg1=" + CSID;
//
//				req.open("GET", url, false);
//				req.onreadystatechange = function()
//					{
//					if ( req.readyState == 4 )
//						{
//						if ( req.responseText != "0\n" )
//							{
//							document.shipconfirm.billingaccount.value = req.responseText.substr(0,req.responseText.length - 1);
//							}
//						else
//							{
//							document.shipconfirm.billingaccount.value = '';
//							}
//						}
//					}
//				req.send(null)
//				}
//			}
//		else if ( document.shipconfirm.manualthirdparty.value == 1 )
//			{
//			ForceBillingDisplay();
//			}
//		else
//			{
//			}
//		}
//	}
//
//function dry_ice_display()
//	{
//	if ( document.shipconfirm.dryice_cs.value == '1' )
//		{
//		dryicedisplay.style.display = "block";
//
//		var TotalDryIce = 0;
//
//		var PPOrder = document.shipconfirm.pporder.value.split(",");
//		for ( var i = 1; i < PPOrder.length; i ++ )
//			{
//			TotalDryIce += ( eval('document.shipconfirm.dryicewt' + PPOrder[i] + '.value') - 0 );
//			}
//
//		if ( !isNaN(TotalDryIce) && TotalDryIce > 0 )
//			{
//			document.shipconfirm.dryicewt.value = TotalDryIce;
//			}
//		}
//	else
//		{
//		dryicedisplay.style.display = "none";
//		document.shipconfirm.dryicewt.value = '';
//		PopulatePackageColumn(document.shipconfirm.dryicewt.value,'dryicewt')
//		}
//	}
//
//function ForceBillingDisplay()
//	{
//	if ( '<var name=loginlevel>' != '10' && '<var name=loginlevel>' != '20' && '<var name=loginlevel>' != '15' && thirdpartycompany.style.display == 'none')
//		{
//		thirdpartycompany.style.display = "block";
//		thirdpartyaddress1.style.display = "block";
//		thirdpartyaddress2.style.display = "block";
//		thirdpartycity.style.display = "block";
//		thirdpartystate.style.display = "block";
//		thirdpartyzip.style.display = "block";
//		thirdpartycountry.style.display = "block";
//		thirdpartyspacer.style.display = "block";
//
//		document.shipconfirm.require3rdpartyaddress.value = 1;
//
//		if ( document.shipconfirm.freightcharges[1].checked == true || document.shipconfirm.freightcharges[2].checked == true)
//			{
//			// if it's collect with no billing account # then make one up
//			if ( document.shipconfirm.freightcharges[1].checked == true || document.shipconfirm.freightcharges[2].checked == true )
//				{
//				if ( document.shipconfirm.billingaccount.value == '' )
//					{
//					document.shipconfirm.usingdefaultbillingaccount.value = 1;
//					document.shipconfirm.billingaccount.value = GetDefaultBilling(document.shipconfirm.toaddress1.value,document.shipconfirm.tozip.value);
//					}
//				}
//
//			SetBillingAddress('true');
//			}
//		}
//	else
//		{
//		thirdpartycompany.style.display = "none";
//		thirdpartyaddress1.style.display = "none";
//		thirdpartyaddress2.style.display = "none";
//		thirdpartycity.style.display = "none";
//		thirdpartystate.style.display = "none";
//		thirdpartyzip.style.display = "none";
//		thirdpartycountry.style.display = "none";
//		thirdpartyspacer.style.display = "none";
//
//		document.shipconfirm.require3rdpartyaddress.value = 0;
//		}
//	}
//
//function SetBillingAddress(asynch)
//	{
//	var BillingAccount = document.shipconfirm.billingaccount.value;
//	var UsingAltSOP = document.shipconfirm.usingaltsop.value;
//	var CustNum = document.shipconfirm.custnum.value;
//
//	var url = "index.cgi?screen=ajax&action=GetBillingAddress&tokenid=<var name=tokenid>&randomnumber=<var name=randomnumber>&arg1=" + BillingAccount + "&arg2=" + UsingAltSOP + "&arg3=" + CustNum;
//
//	var req = new ActiveXObject("Microsoft.XMLHTTP");
//	if (req)
//		{
//		eval('req.open("GET", url, ' + asynch + ')');
//
//		req.onreadystatechange = function()
//			{
//			if ( req.readyState == 4 )
//				{
//				if ( req.responseText != "0\n" )
//					{
//					var Response = req.responseText.substr(0,req.responseText.length - 1);
//					var AddressValues = Response.split("\t");
//					document.shipconfirm.tpcompanyname.value = AddressValues[0];
//					document.shipconfirm.tpaddress1.value = AddressValues[1];
//					document.shipconfirm.tpaddress2.value = AddressValues[2];
//					document.shipconfirm.tpcity.value = AddressValues[3];
//					document.shipconfirm.tpstate.value = AddressValues[4];
//					document.shipconfirm.tpzip.value = AddressValues[5];
//					document.shipconfirm.tpcountry.value = AddressValues[6];
//					}
//				else
//					{
//					document.shipconfirm.tpcompanyname.value = document.shipconfirm.toname.value;
//					document.shipconfirm.tpaddress1.value = document.shipconfirm.toaddress1.value;
//					document.shipconfirm.tpaddress2.value = document.shipconfirm.toaddress2.value;
//					document.shipconfirm.tpcity.value = document.shipconfirm.tocity.value;
//					document.shipconfirm.tpstate.value = document.shipconfirm.tostate.value;
//					document.shipconfirm.tpzip.value = document.shipconfirm.tozip.value;
//					document.shipconfirm.tpcountry.value = document.shipconfirm.tocountry.value;
//					}
//				}
//			}
//		req.send(null)
//		}
//	}