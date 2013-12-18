
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

var pkg_detail_row_count = 1;

function add_pkg_detail_row(detail_type)
	{
	var query_param = '&row_ID=' + ++pkg_detail_row_count + '&detail_type=' + detail_type;

	send_ajax_request('', 'JSON', '', 'add_pkg_detail_row', query_param, function (){
			add_new_row('package_detail_list', JSON_data.rowHTML);
			});
	}

function calculate_density(row_num)
	{
	var Weight = $("#weight_"+row_num).val();
	var Quantity = $("#quantity_"+row_num).val();
	var DimLength = $("#dimlength_"+row_num).val();
	var DimWidth = $("#dimwidth_"+row_num).val();
	var DimHeight = $("#dimheight_"+row_num).val();

	if ( DimLength > 0 && DimWidth > 0 && DimHeight > 0  && Weight > 0 && Quantity > 0) 
		{
		var Density = (( (Weight/Quantity) / ( DimLength * DimWidth * DimHeight ) ) * 1728 );
		$("#density_"+row_num).val(Density.toFixed(2));

		var Class = $("#class_"+row_num).val();
		if (Class.length == 0)
			{
			var query_param = '&density='+Density;
			send_ajax_request('', 'JSON', '', 'get_freight_class', query_param, function (){
				if (JSON_data.freight_class) {
					$("#class_"+row_num).val(JSON_data.freight_class);
					}
				});
			}
		}
	}

function calculate_total_packages()
	{
	var TotalQuantity = 0;
	TotalQuantity -= 0;

	$('#package_detail_list li').each(function() {
		var row_id = this.id;

		if (row_id.match(/^new_package/))
			{
			var row_num = row_id.split('_')[2];
			var Quantity = $("#quantity_"+row_num).val();
			Quantity -= 0;
			TotalQuantity += Quantity;
			}
		});

	$('#totalpackages_div').html(TotalQuantity);
	}

function calculate_total_weight()
	{
	var TotalWeight = 0;
	$('#package_detail_list li').each(function() {
		var row_id = this.id;

		if (row_id.match(/^new_/))
			{
			var row_num = row_id.split('_')[2];

			var EnteredWeight = $("#weight_"+row_num).val();
			var DimWeight = $("#dimweight_"+row_num).val();
			var Quantity = $("#quantity_"+row_num).val();

			EnteredWeight -= 0; DimWeight -= 0; Quantity -= 0;
			if($('input[name=quantityxweight]:radio:checked').val() == 1) 
				{
				if (1 == 0)
					{
					// For non aggregate weight cost shipments, weight/quantity *must* be an 
					// integer...adjust the weight to make it so.
					}
				else
					{
					var OriginalEnteredWeight = EnteredWeight;
					if (Quantity > 0) 
						{
						var SingleWeight = Math.ceil(EnteredWeight/Quantity);
						EnteredWeight = SingleWeight * Quantity;
						}
					}

				if (EnteredWeight != OriginalEnteredWeight)
					{
					$("#weight_"+row_num).val(EnteredWeight);
					}

				if (EnteredWeight >= DimWeight) 
					{
					TotalWeight += EnteredWeight;
					}
				else 
					{
					TotalWeight += DimWeight;
					}
				}
			else
				{
				TotalWeight += EnteredWeight;
				}
			}
		});

	if (TotalWeight > 0)
		{
		$('#totalweight_div').html(TotalWeight.toFixed(2));
		}

// If total weight has changed, recalculate the rates
//	if ( RecalcOK == '1' && TotalWeight != OldWeight && CSIndex != 0 )
//		{
//		ReviewCS();
//		}

//	if ( '<var name=pseudoscreen>' != 'view' && '<var name=loginlevel>' != '25' )
//		{
//		DisplayBookingNumber();
//		DisplaySLAC();
//		}
	}

function calculate_total_declared_value_insurance()
	{
	var TotalInsurance = 0;
	$('#package_detail_list li').each(function() {
		var row_id = this.id;
		if (row_id.match(/^new_/))
			{
			var row_num = row_id.split('_')[2];

			var DecVal = $("#decval_"+row_num).val();
			DecVal -= 0;

			TotalInsurance += DecVal;
			}
		});

	if (TotalInsurance > 0)
		{
		$('#insurance').val(TotalInsurance.toFixed(2));
		}
	}

function calculate_total_freight_insurance()
	{
	var TotalInsurance = 0;
	$('#package_detail_list li').each(function() {
		var row_id = this.id;
		if (row_id.match(/^new_/))
			{
			var row_num = row_id.split('_')[2];

			var FrtIns = $("#frtins_"+row_num).val();
			FrtIns -= 0;

			TotalInsurance += FrtIns;
			}
		});

	if (TotalInsurance > 0)
		{
		$('#freightinsurance').val(TotalInsurance.toFixed(2));
		}
	}

function setSkuDetails(row_num, sku_id)
	{
	var query_param = '&sku_id='+sku_id;

	if(sku_id > 0) {
		send_ajax_request('', 'JSON', '', 'get_sku_detail', query_param, function (){
			if (JSON_data.error) {
				clear_product_details(row_num);
				}
			else {
				$("#description_"+row_num).val(JSON_data.description);
				$("#weight_"+row_num).val(JSON_data.weight);
				$("#dimlength_"+row_num).val(JSON_data.length);
				$("#dimwidth_"+row_num).val(JSON_data.width);
				$("#dimheight_"+row_num).val(JSON_data.height);
				$("#nmfc_"+row_num).val(JSON_data.nmfc);
				//$("#class_"+row_num).val(JSON_data.class);
				$("#unittype_"+row_num+" option:selected").val(JSON_data.unittypeid);
				}
			});

		calculate_density(row_num);
		} 
	else {
		clear_product_details(row_num);
		}
	}

function clear_product_details(row_num) 
	{
	$("#description_"+row_num).val('');
	$("#weight_"+row_num).val('');
	$("#dimlength_"+row_num).val('');
	$("#dimwidth_"+row_num).val('');
	$("#dimheight_"+row_num).val('');
	$("#nmfc_"+row_num).val('');
	$("#class_"+row_num).val('');
	$("#density_"+row_num).val('');
	$("#quantity_"+row_num).val('1');
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
	$("#tocity").val('');
	$("#tostate").val('');
	$("#tocountry").val('');

	var query_param = "&zipcode=" + $("#tozip").val(); 
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
	$('#package_detail_list li').each(function() {
		var row_id = this.id;

		if (row_id.match(/^new_/)) {
			var row_num = row_id.split('_')[2];

			for (var i=0; i<controls.length; i++) {
				var element = controls[i];
				if (validNumericField(element+'_'+row_num))
					{
					if ($("#"+element+"_"+row_num).hasClass('ui-state-error'))
						$("#"+element+"_"+row_num).removeClass('ui-state-error');
					}
				else
					{
					$("#"+element+"_"+row_num).addClass( "ui-state-error" );
					boolInvalidData=true;
					}
				}
			}
		});

	return boolInvalidData;
	}

var has_FC=false;
function get_customer_service_list()
	{
	if (has_FC)
			$(".fc").show();
	else
	send_ajax_request('', 'JSON', '', 'get_customer_service_list', "", function (){
		if (JSON_data.rowHTML) $(JSON_data.rowHTML).insertAfter("#freight_charges_table tr");
		$("#freight_charges_table").show();
		has_FC = true;
		});
	}

var has_TP=false;
function checkCarrierServiceSection()
	{
	if($('input:radio[name=deliverymethod]:checked').val() == "3rdparty") 
		{
		if(has_TP) {
			$(".tp").show();
			get_customer_service_list();
		} else
		send_ajax_request('', 'JSON', '', 'third_party_delivery', "", function () {
			if (JSON_data.rowHTML) $(JSON_data.rowHTML).insertAfter("#delivery_method_table tr:first");
			get_customer_service_list();
			$(".tp").show();
			has_TP = true;
			});
		}
	else if($('input:radio[name=deliverymethod]:checked').val() == "collect") 
		{
		$(".tp").hide("slow");
		get_customer_service_list();
		}
	else
		{
		$(".fc").hide("slow");
		$(".tp").hide("slow");
		}
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
