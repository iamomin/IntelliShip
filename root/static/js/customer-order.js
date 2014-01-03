
function check_due_date()
	{
	var ShipDate = $('#datetoship').val();
	var DueDate = $('#dateneeded').val();
	var OffsetEqual = 7;
	var OffsetLessThan = -7;

	var query_param = '&shipdate=' + ShipDate + '&duedate=' + DueDate + '&offset=' + OffsetEqual + '&lessthanoffset=' + OffsetLessThan;
	send_ajax_request('', 'JSON', '', 'adjust_due_date', query_param, function (){
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
	send_ajax_request('', 'JSON', '', 'add_pkg_detail_row', query_param, function (){
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
		send_ajax_request('', 'JSON', '', 'get_freight_class', query_param, function (){
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

		if (event_row_ID != undefined && $("#type_"+event_row_ID).val() == 'package') return;
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

	if (ParentPackageID > 0) {
		//alert("Package ID: " + ParentPackageID + ", PackageProductCount: " + PackageProductCount);
		PackageProductsCountDetails[ParentPackageID] = +PackageProductCount;
		}

	ValuePerProduct = +insurance_value / +TotalProductCount

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
		send_ajax_request('', 'JSON', '', 'get_sku_detail', query_param, function () {
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

function checkInternationalSection() {
	if($("#tocountry").val() != $("#fromcountry").val()) {
		send_ajax_request('intlCommoditySec', 'HTML', '', 'display_international', '', function (){
			$("#intlCommoditySec").slideDown(1000);
			});
		} else {
		$("#intlCommoditySec").slideUp("slow");
		$("#intlCommoditySec").empty();
		}
	}

function setCityAndState()
	{
	var tozip = $("#tozip").val();
	if (tozip.length < 5) return;

	$("#tocity").val('');
	$("#tostate").val('');
	$("#tocountry").val('');

	var query_param = "&zipcode=" + tozip;
	if($("#tozip").val() != "") {
		send_ajax_request('', 'JSON', '', 'get_city_state', query_param, function () {
			$("#tocity").val(JSON_data.city);
			$("#tostate").val(JSON_data.state);
			$("#tocountry").val(JSON_data.country);
			});
		}
	}

function validate_package_details()
	{
	var boolInvalidData=false;
	var controls = ['quantity', 'sku', 'weight', 'dimlength', 'dimwidth', 'dimheight'];

	$('#package-detail-list li').each(function() {

		if (!this.id.match(/^new_/)) return;

		var row_ID = this.id.split('_')[2];

		for (var i=0; i<controls.length; i++) {
			var element = controls[i];
			if (validNumericField(element+'_'+row_ID))
				{
				if ($("#"+element+"_"+row_ID).hasClass('ui-state-error'))
					$("#"+element+"_"+row_ID).removeClass('ui-state-error');
				}
			else
				{
				$("#"+element+"_"+row_ID).addClass( "ui-state-error" );
				boolInvalidData=true;
				}
			}

		});

	return boolInvalidData;
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
function checkCarrierServiceSection()
	{
	if($('input:radio[name=deliverymethod]:checked').val() == "3rdparty") 
		{
		if(has_TP) {
			$(".tp").show(1000, function () {get_customer_service_list();});
		} else
		send_ajax_request('', 'JSON', '', 'third_party_delivery', "", function () {
			if (JSON_data.rowHTML) $(JSON_data.rowHTML).insertAfter("#delivery_method_table tr:first");
			has_TP = true;
			get_customer_service_list();
			});
		}
	else if($('input:radio[name=deliverymethod]:checked').val() == "collect") 
		{
		$(".tp").slideUp(1000, function () {get_customer_service_list();});
		}
	else
		{
		$("#divFreightCharges").slideUp(1000, function () {$(".tp").slideUp();});
		}
	}

var has_FC=false;
function get_customer_service_list()
	{
	if (has_FC)
		$("#divFreightCharges").slideDown(1000);
	else
	send_ajax_request('divFreightCharges', 'HTML', '', 'get_customer_service_list', "", function (){
		$("#divFreightCharges").slideDown(1000);
		has_FC = true;
		});
	}

function populate_ship_to_address(addressid)
	{
	var query_param = '&addressid='+addressid;

	if (addressid.length > 0) {
		send_ajax_request('', 'JSON', '', 'get_address_detail', query_param, function (){
			if (JSON_data.address1) {
				$("#toaddress1").val(JSON_data.address1);
				$("#toaddress2").val(JSON_data.address2);
				$("#tocity").val(JSON_data.city);
				$("#tostate").val(JSON_data.state);
				$("#tozip").val(JSON_data.zip);
				$("#tocountry").val(JSON_data.country);
				}
			});
		}
	}
