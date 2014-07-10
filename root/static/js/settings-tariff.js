var GRID, CSGRID, TREE, COLWIDTH;
var ISGRIDLOADED = false, ISTREELOADED = false, ISADDMODE = false;

function loadServicesTree() {
	//alert("loadServicesTree");
	TREE = $('#services_tree').on("changed.jstree", function (e, data) {

			if (data.node.original.hasOwnProperty('sid')) {
				ISGRIDLOADED = false;
				toggleToolbarButtons();
				$('#csid').val(data.node.id);
				getTariff(data.node.id);
			}

			//alert("DATA: " + JSON.stringify(data.node));
			var parents = data.node.parents;
			//alert(parents);
			var breadcrumbStr = $("#customername").val() + " / ";

			for (var i = 0; i < parents.length; i++) {
				var parentId = parents[i];
				if (parentId != "#") {
					//alert(JSON.stringify($("#" + parentId)));
					breadcrumbStr += $("#" + parentId).find("a").first().text() + " / ";
				}
			}
			breadcrumbStr += data.node.text;
			$('#lbl_breadcrumb').html(breadcrumbStr);
			
			setAddMode(false);

		}).jstree({
			"plugins" : ['themes', 'json_data', 'ui', 'state'],
			"core" : {
				"animation" : 0,
				"check_callback" : true,
				"themes" : {
					"classic" : true
				},
				'data' : JSON_data
			}
		});
	//alert(JSON.stringify(TREE));
	ISTREELOADED = true;
}

function getAllServices() {
	//alert("getAllServices");
	var params = 'customerid=' + $("#customerid").val();
	send_ajax_request('', 'JSON', 'settings/tariff', 'get_customer_service_list', params, function () {
		loadServicesTree();
		toggleToolbarButtons();
		$('#lbl_breadcrumb').html($("#customername").val() + " / ");
		$('#tbl_tariff').show();
	});
}

function initToolbar() {
	/*$("#btn_add_service").button({
		text : false,
		icons : {
			primary : "ui-icon-add-service"
		}
	});
	$("#btn_delete_service").button({
		text : false,
		icons : {
			primary : "ui-icon-delete-service"
		}
	});
	$("#btn_update_tariff").button({
		text : false,
		icons : {
			primary : "ui-icon-play"
		}
	});
	$("#btn_delete_all_rows").button({
		text : false,
		icons : {
			primary : "ui-icon-play"
		}
	});*/
}

function toggleToolbarButtons() {
	if (ISTREELOADED) {
		$("#btn_add_service").prop("disabled", false);
		$("#btn_delete_service").prop("disabled", false);
	} else {
		$("#btn_add_service").prop("disabled", true);
		$("#btn_delete_service").prop("disabled", true);
	}

	if (ISGRIDLOADED) {
		$("#btn_update_tariff").prop("disabled", false);
		$("#btn_delete_all_rows").prop("disabled", false);
	} else {
		$("#btn_update_tariff").prop("disabled", true);
		$("#btn_delete_all_rows").prop("disabled", true);
	}
}

/*
	ENTRY POINT !
*/
function entryPoint(event){
	console.log("entryPoint");
	if($("#tbl_tariff").is(":visible")){
		return;
	}
	if (!$('#services_tree').html()) {
		console.log("Loading....");
		initToolbar();
		getAllServices();
	}
}

function doAddSelectedServices(){
	var selectedIndexes = CSGRID.getSelectedRows();
	var selectedServiceIds = [];
	jQuery.each(selectedIndexes, function (index, value) {
	  selectedServiceIds.push(CSGRID.getData()[value].serviceid);
	});
	var params = "serviceids=" + JSON.stringify(selectedServiceIds) + "&customerid="+ $("#customerid").val();
	my_ajax_request('settings/tariff/add_services', params, function () {
		if (JSON_data.status == "success") {
			var msg = JSON_data.message;
			$('#div_add_service').slideUp('slow');
			reloadUI();
			showMessage(msg);
		} else {
			showMessage("Failed to update");
		}
	});
}

function reloadUI() {
	$('#div_add_service').slideUp('slow');
	$('#services_tree').jstree('destroy');
	$('#services_tree').html("");
	$('#operations').hide();
	$('#serviceIds').hide();
	$('#myGrid').empty();
	getAllServices();
}

function loadServiceInfo() {
	//alert(JSON.stringify(JSON_data));
	$('#service_acctnum').val(JSON_data['accountnumber']);
	$('#service_meternum').val(JSON_data['meternumber']);
}

function loadGrid() {
	//alert("loadGrid");
	$('#myGrid').empty();
	var options = {
		selectable : false,
		editable : true,
		enableCellNavigation : true,
		asyncEditorLoading : false,
		autoEdit : false,
		dataItemColumnValueExtractor : getItemColumnValue
	};

	var columns = [];
	var headers = JSON_data['headers'];
	COLWIDTH = 700 / headers.length + 3;

	//Now define your buttonFormatter function
	var buttonFormatter = function (row, cell, value, columnDef, dataContext) {
		/*console.log("row: " + JSON.stringify(row));
		console.log("cell: " + JSON.stringify(cell));
		console.log("value: " + JSON.stringify(value));
		console.log("columnDef: " + JSON.stringify(columnDef));
		console.log("dataContext: " + JSON.stringify(dataContext));*/
		var button = "<input class='slick-deletebutton' type='button' id='" + dataContext.id + "' onclick='deleteTariffRow(" + row + ")' />";
		//the id is so that you can identify the row when the particular button is clicked
		return button;
		//Now the row will display your button
	};

	columns.push({
		id : "delCol",
		field : 'del',
		name : '',
		width : 30,
		formatter : buttonFormatter,
		editable : false
	});

	columns.push({
		id : "title_wtrange",
		name : "Wt. Range",
		field : "wtrange",
		//width : (COLWIDTH * 2) + 30,
		minWidth : 140,
		cssClass : "cell-title",
		editor : NumericRangeEditor,
		formatter : NumericRangeFormatter
	});
	columns.push({
		id : "title_mincost",
		name : "mincost",
		field : "mincost",
		maxWidth : COLWIDTH,
		cssClass : "cell-title",
		editor : RealNumberEditor
	});

	headers.forEach(function (entry) {
		columns.push({
			id : "header_" + entry,
			name : "" + entry,
			field : "" + entry,
			maxWidth : COLWIDTH,
			cssClass : "cell-title",
			editor : RealNumberEditor,
			sortable : false
		});
	});

	var data = JSON_data['rows'];

	GRID = new Slick.Grid("#myGrid", data, columns, options);
	GRID.setSelectionModel(new Slick.CellSelectionModel());
	//GRID.registerPlugin(checkboxSelector);
	var columnpicker = new Slick.Controls.ColumnPicker(columns, GRID, options);

	ISGRIDLOADED = true;
}

function getTariff(csid) {
	//alert("getTariff " + csid);
	var params = 'csid=' + csid;
	send_ajax_request('', 'JSON', 'settings/tariff', 'get_service_tariff', params, function () {
		loadGrid();
		loadServiceInfo();
		$('#operations').show();
		$('#serviceIds').show();
		toggleToolbarButtons();
	});
}

function extractAndSubmit() {
	if (window.confirm("Committed changes are irrevocable. Do you want to commit your changes?")) {
		//alert($('#csid').val());
		var d = GRID.getData();
		var info = {
			accountnumber : $('#service_acctnum').val(),
			meternumber : $('#service_meternum').val(),
			csid : $('#csid').val()
		};

		var params = "csid=" + $('#csid').val() + "&data=" + JSON.stringify(d) + "&info=" + JSON.stringify(info);
		my_ajax_request('settings/tariff/save', params, function () {
			if (JSON_data.status == "success") {
				showMessage(JSON_data.message);
				GRID.invalidate();
			} else {
				showMessage("Failed to update");
			}
		});
	}
}

function addTariffRow() {
	var data =  GRID.getData();
	//console.log("data length: " + data.length);
	var lastRow = data[data.length - 1];
	//console.log(lastRow);	
	
	//Clone the new row from the last row so that the user doesn't have to enter all the data.
	var newRow = JSON.parse(JSON.stringify(lastRow)); 
	newRow.rownum = lastRow.rownum + 1;
	newRow.wtmin = lastRow.wtmax + 1; 
	newRow.wtmax = lastRow.wtmax + 2;
		
	newRow = removeRateIds(newRow);
	newRow["isnew"] = true;
	//console.log(newRow);
	data.push(newRow);
	
	//update the GRID and open the wtrange field of the new row in edit mode.
	refreshGrid();
	GRID.setActiveCell(newRow.rownum, 1);
	GRID.editActiveCell();
	
	setAddMode(true);
}

function setAddMode(isOn){
	if(isOn){
		//hide Add, Update, Delete All Rows
		//show Save and Cancel
		$('#btn_add_tariff_rows').hide();
		$('#btn_update_tariff_rows').hide();
		$('#btn_delete_all_rows').hide();
		$('#btn_save_tariff_rows').show();
		$('#btn_cancel_tariff_rows').show();
	}else{
		//hide Save and Cancel
		//show Add, Update, Delete All Rows
		$('#btn_add_tariff_rows').show();
		$('#btn_update_tariff_rows').show();
		$('#btn_delete_all_rows').show();
		$('#btn_save_tariff_rows').hide();
		$('#btn_cancel_tariff_rows').hide();		
	}
	
	ISADDMODE = isOn;	
}

function saveTariffRows() {
	var data =  GRID.getData();
	
	//extract new rates.
	var ratearray = [];
	for(var i = 0; i < data.length; i++){
		var row = data[i];
		if(row.isnew){
			ratearray.push(row);
		}
	}
	
	//send the rates.
	var params = "rates=" + JSON.stringify(ratearray);
	console.log(params);
	my_ajax_request('settings/tariff/save_tariff_rows', params, function () {
		if (JSON_data.status == "success") {
			var message = JSON_data.message;
			setAddMode(false);
			var csids = $("#services_tree").jstree("get_selected");
			getTariff(csids[0]);			
			showMessage(message);			
		} else {
			showMessage("Failed to update");
		}
	});
}

function cancelTariffRows(){
	var data =  GRID.getData();
	for(var i = 0 ; i < data.length; i++){
		var row =  data[i];
		if(row.isnew){
			data.splice(row.rownum,1);
		}
		refreshGrid();
	}
	setAddMode(false);	
}

function removeRateIds(row){	
	for (var propertyName in row){
		var value = row[propertyName];
		if(value && typeof(value) == "object" && value.hasOwnProperty("rateid")){
			delete value.rateid;
		}
	}
	return row;	
}

function deleteTariffRow(rownum){
	var row = GRID.getDataItem(rownum);
	var range = row.wtmin + "-" + row.wtmax;
	if(window.confirm("WARNING: Deletes are irrevocable. Do you want to delete the range " + range + "?")){
		if(row.isnew){
			//delete the row locally.
			var data = GRID.getData();			
			data.splice(row.rownum,1);
			var r = row.rownum;
			while (r < data.length){
				GRID.invalidateRow(r);
				r++;
			}
			refreshGrid();
			GRID.scrollRowIntoView(row.rownum-1)
		}else{
			//delete the row from db
			doDeleteTariffRows(extractRateIds(row));
		}
		
	}
}

function refreshGrid(){
	GRID.updateRowCount();
	GRID.render();
}

function extractRateIds(row){
	var arr = [];
	for (var propertyName in row){
		var value = row[propertyName];
		if(typeof(value) == "object" && value.hasOwnProperty("rateid")){
			arr.push(value.rateid);
		}
	}
	return arr;
}

function doDeleteTariffRows(rowids){
	var params = "rateids=" + JSON.stringify(rowids);
	my_ajax_request('settings/tariff/deleteTariffRows', params, function () {
			if (JSON_data.status == "success") {
				showMessage(JSON_data.message);
				//$("#myGrid").empty();
				var csids = $("#services_tree").jstree("get_selected");
				getTariff(csids[0]);
			} else {
				showMessage("Failed to update");
			}
		});
}

function deleteAllTariffRows() {
	if (window.confirm("WARNING: You are about to delete ALL the tariff rows for the service. This will not delete the customer-service association. Do you want to proceed?")) {
		var rows =  GRID.getDataLength();
		var rateids = [];
		for(var i = 0; i < rows; i++){
			var row = GRID.getDataItem(i);
			var arr = extractRateIds(row);
			rateids.push.apply(rateids, arr);
		}
		doDeleteTariffRows(rateids);
	}
}

function addCustomerService() {
	TREE = $('#services_tree').jstree(true);
	var carrierNode = TREE.get_node(TREE.get_selected());
	
	var params = "customerid="+ $("#customerid").val();
	my_ajax_request('settings/tariff/get_carrier_services', params, function () {
		loadCSGrid();
		$("#div_add_service").slideDown("slow");
	});
	
}

function deleteCustomerService() {
	if (window.confirm("WARNING: You are about to delete a customer-service association. Do you want to proceed?")) {
		var csids = $("#services_tree").jstree("get_selected");
		var selectednode = $("#services_tree").jstree("get_node", csids[0]);
		if(selectednode && selectednode.original.hasOwnProperty('sid')){
			//alert("Deleting " + csids[0]);
			var params = "csid=" + csids[0];
			my_ajax_request('settings/tariff/delete_customer_service', params, function () {
				if (JSON_data.status == "success") {
					var msg = JSON_data.message;
					reloadUI();
					showMessage(msg);
				} else {
					showMessage("Failed to delete");
				}
			});
		}else{
			showMessage("Please select a service to delete");
		}
	}
}

function loadCSGrid(){
	$('#csGrid').empty();
	
	var options = {
		selectable: true,
		editable: false,
		enableCellNavigation: false,
		forceFitColumns: true
	};
	
	var headers = ["serviceid", "carrierid", "servicename", "international", "heavy", "servicecode"];
	var columns = [];
	
	var checkboxSelector = new Slick.CheckboxSelectColumn({
      cssClass: "slick-cell-checkboxsel"
    });
	
	columns.push(checkboxSelector.getColumnDefinition());
	
	columns.push({
		id : "header_carriername",
		name : "Carrier Name" ,
		field : "carriername",
		width : 200,
		cssClass : "cell-title",
		sortable : true
	});
	
	columns.push({
		id : "header_servicename",
		name : "Service Name" ,
		field : "servicename",
		width : 300,
		cssClass : "cell-title",
		sortable : true
	});
	
	columns.push({
		id : "header_international",
		name : "International" ,
		field : "international",
		width : 100,
		cssClass : "cell-title",
		sortable : true
	});
	
	columns.push({
		id : "header_heavy",
		name : "Heavy" ,
		field : "heavy",
		width : 100,
		cssClass : "cell-title",
		sortable : true
	});
	
	columns.push({
		id : "header_servicecode",
		name : "Service Code" ,
		field : "servicecode",
		width : 100,
		cssClass : "cell-title",
		sortable : true
	});
	
	var data = JSON_data['services'];
	
	CSGRID = new Slick.Grid("#csGrid", data, columns, options);
	CSGRID.setSelectionModel(new Slick.RowSelectionModel({selectActiveRow: false}));
    CSGRID.registerPlugin(checkboxSelector);

    var columnpicker = new Slick.Controls.ColumnPicker(columns, CSGRID, options);
}

// Get the item column value using a custom 'fieldIdx' column param
function getItemColumnValue(item, column) {
	var values = item[column.field];
	if (values !== null && typeof values === 'object' && values.hasOwnProperty('actualcost')) {
		return values.actualcost;
	} else {
		return values;
	}
}

/**
RealNumberEditor
 */

function RealNumberEditor(args) {
	var $numVal;
	var scope = this;

	this.init = function () {
		$numVal = $("<INPUT type='text' class='editor-text'/>")
			.appendTo(args.container)
			.bind("keydown", scope.handleKeyDown);
		scope.focus();
	};

	this.handleKeyDown = function (e) {
		if (e.keyCode == $.ui.keyCode.LEFT || e.keyCode == $.ui.keyCode.RIGHT || e.keyCode == $.ui.keyCode.TAB) {
			e.stopImmediatePropagation();
		}
	};

	this.destroy = function () {
		$(args.container).empty();
	};

	this.focus = function () {
		$numVal.focus();
	};

	this.serializeValue = function () {
		//alert("serializeValue");
		return parseFloat($numVal.val(), 10);
	};

	this.applyValue = function (item, state) {
		//alert("applyValue " + args.column.field);
		item[args.column.field].actualcost = state;
	};

	this.loadValue = function (item) {
		$numVal.val(item[args.column.field].actualcost);
	};

	this.isValueChanged = function () {
		return args.item.actualcost != parseFloat($numVal.val(), 10);
	};

	this.validate = function () {
		if ($numVal.val().trim()) {
			if (isNaN(parseFloat($numVal.val(), 10))) {
				return {
					valid : false,
					msg : "Please type in valid numbers."
				};
			}
		}
		return {
			valid : true,
			msg : null
		};
	};

	this.init();
}

/**
NumericRangeEditor
 */

function NumericRangeEditor(args) {
	var $from,
	$to;
	var scope = this;

	this.init = function () {
		$from = $("<INPUT type=text style='width:40px' />")
			.appendTo(args.container)
			.bind("keydown", scope.handleKeyDown);

		$(args.container).append("&nbsp; to &nbsp;");

		$to = $("<INPUT type=text style='width:40px' />")
			.appendTo(args.container)
			.bind("keydown", scope.handleKeyDown);

		scope.focus();
	};

	this.handleKeyDown = function (e) {
		if (e.keyCode == $.ui.keyCode.LEFT || e.keyCode == $.ui.keyCode.RIGHT || e.keyCode == $.ui.keyCode.TAB) {
			e.stopImmediatePropagation();
		}
	};

	this.destroy = function () {
		$(args.container).empty();
	};

	this.focus = function () {
		$from.focus();
	};

	this.serializeValue = function () {
		return {
			from : parseInt($from.val(), 10),
			to : parseInt($to.val(), 10)
		};
	};

	this.applyValue = function (item, state) {
		item.wtmin = state.from;
		item.wtmax = state.to;
	};

	this.loadValue = function (item) {
		$from.val(item.wtmin);
		$to.val(item.wtmax);
	};

	this.isValueChanged = function () {
		return args.item.wtmin != parseInt($from.val(), 10) || args.item.wtmax != parseInt($from.val(), 10);
	};

	this.validate = function () {
		//alert(JSON.stringify(args.item.rateids));
		if (isNaN(parseInt($from.val(), 10)) || isNaN(parseInt($to.val(), 10))) {
			return {
				valid : false,
				msg : "Please type in valid numbers."
			};
		}

		if (parseInt($from.val(), 10) > parseInt($to.val(), 10)) {
			return {
				valid : false,
				msg : "'from' cannot be greater than 'to'"
			};
		}

		var inRange = function (v, m, M) {
			return m <= v && v <= M;
		};

		var gridData = GRID.getData();
		for (var key in gridData) {
			var row = gridData[key];
			var myRowNum = args.item.rownum;
			var min = row.wtmin;
			var max = row.wtmax;

			if (myRowNum > row.rownum && inRange($from.val(), min, max)) {
				//alert("Overlapping minimum");
				return {
					valid : false,
					msg : "Overlapping minimum"
				};
			}

			if (myRowNum < row.rownum && inRange($to.val(), min, max)) {
				//alert("Overlapping maximum");
				return {
					valid : false,
					msg : "Overlapping maximum"
				};
			}

			if ($from.val() < min && $to.val() > max) {
				//alert("Range or sub-range is already defined");
				return {
					valid : false,
					msg : "Range or sub-range is already defined"
				};
			}

			if ($from.val() > min && $to.val() < max) {
				//alert("Range or super-range is already defined");
				return {
					valid : false,
					msg : "Range or super-range is already defined"
				};
			}
		}

		return {
			valid : true,
			msg : null
		};
	};

	this.init();
}

/**
NumericRangeFormatter
 */
function NumericRangeFormatter(row, cell, value, columnDef, dataContext) {
	return dataContext.wtmin + " - " + dataContext.wtmax;
}

function my_ajax_request(section_value, optional_param, call_back_function) {

	waiting_COUNT++;
	$('#preload').show();

	var data_string = "ajax=1&eventtimestamp=" + jQuery.now();

	if (optional_param)
		data_string += '&' + optional_param;

	var request_url = (section_value ? '/customer/' + section_value : '/customer/ajax');

	var charPattern = /#/g;
	if (data_string.match(charPattern)) {
		data_string = data_string.replace(charPattern, "%23");
	}

	JSON_data = null;
	$.ajax({
		type : "POST",
		url : request_url,
		data : data_string,
		//contentType : "application/json; charset=utf-8",
		dataType : 'json',
		success : function (data) {
			waiting_COUNT--;
			if (waiting_COUNT == 0)
				$('#preload').hide();
			JSON_data = data;
			if (JSON_data.error)
				showMessage("<div class='error'>" + JSON_data.error + "</div>", "Reseponse Error");

			afterSuccessCallBack("JSON", "", call_back_function);
		},
		error : function (data) {
			showMessage("An internal error has occurred, Please contact support. " + data, "Internal Server Error");
			waiting_COUNT--;
			if (waiting_COUNT == 0)
				$('#preload').hide();
		},
		complete : function (data) {
			//$('#preload').hide();
		}
	});

}