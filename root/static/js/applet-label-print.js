/**
* Optionally used to deploy multiple versions of the applet for mixed
* environments.  Oracle uses document.write(), which puts the applet at the
* top of the page, bumping all HTML content down.
*/
deployQZ();

/**
* Deploys different versions of the applet depending on Java version.
* Useful for removing warning dialogs for Java 6.  This function is optional
* however, if used, should replace the <applet> method.  Needed to address
* MANIFEST.MF TrustedLibrary=true discrepency between JRE6 and JRE7.
*/
function deployQZ() {
	var attributes = {id: "qz", code:'qz.PrintApplet.class',
		archive:'/jar/qz-print.jar', width:1, height:1};
	var parameters = {jnlp_href: '/jar/qz-print_jnlp.jnlp',
		cache_option:'plugin', disable_logging:'false',
		initial_focus:'false'};
	if (deployJava.versionCheck("1.7+") == true) {}
	else if (deployJava.versionCheck("1.6+") == true) {
		attributes['archive'] = '/jar/jre6/qz-print.jar';
		parameters['jnlp_href'] = '/jar/jre6/qz-print_jnlp.jnlp';
	}
	deployJava.runApplet(attributes, parameters, '1.5');
}

/**
* Automatically gets called when applet has loaded.
*/
function qzReady() {
	// Setup our global qz object
	window["qz"] = document.getElementById('qz');
	//var title = document.getElementById("title");
	if (qz) {
		try {
			//alert(qz.getVersion());
		} catch(err) { // LiveConnect error, display a detailed meesage
			alert("ERROR:  \nThe applet did not load correctly.  Communication to the " +
				"applet has failed, likely caused by Java Security Settings.  \n\n" +
				"CAUSE:  \nJava 7 update 25 and higher block LiveConnect calls " +
				"once Oracle has marked that version as outdated, which " +
				"is likely the cause.  \n\nSOLUTION:  \n  1. Update Java to the latest " +
				"Java version \n          (or)\n  2. Lower the security " +
				"settings from the Java Control Panel.");
	  }
  }
}

/**
* Returns whether or not the applet is not ready to print.
* Displays an alert if not ready.
*/
function notReady() {
	// If applet is not loaded, display an error
	if (!isLoaded()) {
		return true;
	}
	// If a printer hasn't been selected, display a message.
	else if (!qz.getPrinter()) {
		alert('Please select a printer first by using the "Detect Printer" button.');
		return true;
	}
	return false;
}

/**
* Returns is the applet is not loaded properly
*/
function isLoaded() {
	if (!qz) {
		alert('Error:\n\n\tPrint plugin is NOT loaded!');
		return false;
	} else {
		try {
			if (!qz.isActive()) {
				alert('Error:\n\n\tPrint plugin is loaded but NOT active!');
				return false;
			}
		} catch (err) {
			alert('Error:\n\n\tPrint plugin is NOT loaded properly!');
			return false;
		}
	}
	return true;
}

/**
* Automatically gets called when "qz.print()" is finished.
*/
function qzDonePrinting() {
	// Alert error, if any
	if (qz.getException()) {
		alert('Error printing:\n\n\t' + qz.getException().getLocalizedMessage());
		qz.clearException();
		return;
	}

	// Alert success message
	//alert('Successfully sent print data to "' + qz.getPrinter() + '" queue.');
}

/***************************************************************************
* Prototype function for finding the "default printer" on the system
* Usage:
*    qz.findPrinter();
*    window['qzDoneFinding'] = function() { alert(qz.getPrinter()); };
***************************************************************************/
function useDefaultPrinter(callback_fn) {
	if (isLoaded()) {
		// Searches for default printer
		qz.findPrinter();

		// Automatically gets called when "qz.findPrinter()" is finished.
		window['qzDoneFinding'] = function() {
			// Alert the printer name to user
			var printer = qz.getPrinter();
			//alert(printer !== null ? 'Default printer found: "' + printer + '"' : 'Default printer ' + 'not found');

			if (callback_fn) callback_fn.call();

			// Remove reference to this function
			window['qzDoneFinding'] = null;
		};
	}
}

/***************************************************************************
* Gets the current url's path, such as http://site.com/example/dist/
***************************************************************************/
function getPath() {
	var pathArray = window.location.href.split('/');
	var protocol = pathArray[0];
	var host = pathArray[2];
	var url = protocol + '//' + host;
	return url;
}

/**
* Fixes some html formatting for printing. Only use on text, not on tags!
* Very important!
*   1.  HTML ignores white spaces, this fixes that
*   2.  The right quotation mark breaks PostScript print formatting
*   3.  The hyphen/dash autoflows and breaks formatting
*/
function fixHTML(html) {
	return html.replace(/\n/g, "").replace(/ /g, "&nbsp;").replace(/’/g, "'").replace(/-/g,"&#8209;");
}


/***************************************************************************
* Prototype function for printing an HTML screenshot of the existing page
* Usage: (identical to appendImage(), but uses html2canvas for png rendering)
*    qz.setPaperSize("8.5in", "11.0in");  // US Letter
*    qz.setAutoSize(true);
*    qz.appendImage($("canvas")[0].toDataURL('image/png'));
***************************************************************************/
function printHTML5Page() {
	html2canvas(document.body, {
		canvas: hidden_screenshot,
		onrendered: function() {
			if (notReady()) { return; }
			// Optional, set up custom page size.  These only work for PostScript printing.
			// setPaperSize() must be called before setAutoSize(), setOrientation(), etc.
			qz.setPaperSize("8.5in", "11.0in");  // US Letter
			//qz.setAutoSize(true);
			var dataUrl = $("canvas")[0].toDataURL('image/png');
			qz.appendImage(dataUrl);
			//window.open(dataUrl, "toDataURL() image", "width=600, height=200");
			// Automatically gets called when "qz.appendFile()" is finished.
			window['qzDoneAppending'] = function() {
				// Tell the applet to print.
				qz.printPS();

				// Remove reference to this function
				window['qzDoneAppending'] = null;
				};
			}
		});
	}
