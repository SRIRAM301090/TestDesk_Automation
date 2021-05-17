<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:trc="urn:IEEE-1636.1:2011:01:TestResultsCollection" xmlns:tr="urn:IEEE-1636.1:2011:01:TestResults" xmlns:c="urn:IEEE-1671:2010:Common" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ts="www.ni.com/TestStand/ATMLTestResults/2.0" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:user="http://www.ni.com/TestStand" id="TS17.0.0">
	<xsl:namespace-alias stylesheet-prefix="xsl" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="c" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="trc" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="tr" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="xsi" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="ts" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="msxsl" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="user" result-prefix="#default"/>
	<msxsl:script language="javascript" implements-prefix="user">
          <![CDATA[
	//Utility functions for escaping stylesheetpath, getting absolute image paths	
    //Image Paths are added from msxsl script because if xslt templates are used the path
    //containing unicode characters are converted into %ascicode characters which won't work on a japanese machine
	
	var gStyleSheetPathPrefix = "";


	
	function InitializeStylesheetPath(stylesheetPath)
	{
		
		gStyleSheetPathPrefix = GetFolderPath(stylesheetPath);
		return "";
	}
	
	// This function first converts all back-slashes into forward-slashes and then
	// removes the file name part of the input file path
	function GetFolderPath(sFilePath)
	{
		var sConvertedFilePath;
		var index = sFilePath.indexOf("\\");
		if (index == -1)
			sConvertedFilePath = sFilePath;
		else
		{
			sConvertedFilePath = "";
			do
			{
				sConvertedFilePath += sFilePath.substring(0,index) + "/";
				sFilePath = sFilePath.substring(index+1,sFilePath.length);
				index = sFilePath.indexOf("\\");
			}
			while (index != -1);
			sConvertedFilePath += sFilePath;
		}

		var sFolderPath = "";

		index = sConvertedFilePath.lastIndexOf("/");
		if (index != -1)
			sFolderPath = sConvertedFilePath.substring(0,index) + "/";

		return sFolderPath;
	}
	
	function GetAbsolutePath(fName) 
	{
		return gStyleSheetPathPrefix + fName; 
	}	
	
	function GetImageHTMLForImageName(imageName, className)
	{
		var imgsrc = GetAbsolutePath(imageName);
		return "<img onclick='" + className +"(event)' src='"+ imgsrc + "' class='" + className + "' style='' alt='Expand/Collapse'/>";		
	}
	
	
	//Graph Functions
	
	function IsGraphControlInstalled()
	{
		var haveGraphControl = 0;
		try
		{
			var xObj = new ActiveXObject("TsGraphControl3.GraphControl3");
			if(xObj != null)
				haveGraphControl =  1;
		}
		catch(ex)
		{
			haveGraphControl = 0;
		}
		return haveGraphControl;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
	
	/* gIncludeArrayMeasurement can take the following values:
		0 : Do Not Include Arrays
		1 : Insert as Table
		2 : Insert as Graph */
	var gIncludeArrayMeasurement = 0;
	
	/* gArrayMeasurementFilter can take the following values:
		0 : Include All
		1 : Include Upto Max
		2 : Exclude If Larger Than Max
		3 : Decimate If Larger Than Max */
	var gArrayMeasurementFilter = 0;
	
	// gArrayMeasurementMax specifies the maximum number of array elements to display
	var gArrayMeasurementMax = 0;
	
	function InitArrayMeasurementGlobalVariables(includeArrayMeasurement, arrayMeasurementFilter, arrayMeasurementMax)
	{
		gIncludeArrayMeasurement = parseInt(includeArrayMeasurement);	
		gArrayMeasurementFilter = parseInt(arrayMeasurementFilter);
		gArrayMeasurementMax = parseInt(arrayMeasurementMax);
		return '';
	}
	function GetIncludeArrayMeasurement()
	{
		return gIncludeArrayMeasurement;
	}
	function GetArrayMeasurementFilter()
	{
		return gArrayMeasurementFilter;
	}
	function GetArrayMeasurementMax()
	{
		return gArrayMeasurementMax;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
	
	var gGraphCounter = 0;
	function GetGraphCounter()
	{
		return gGraphCounter++;
	}
	function GetDimensions(arrayElements)
	{
		var numOfElements = arrayElements.length;
		var numDimensions = 0;
		if (numOfElements != 0)
		{
			var firstElement = arrayElements.item(0);
			var firstElementAttributes = firstElement.attributes;
			var position = firstElementAttributes.getNamedItem("position").value;
			numDimensions = position.split(",").length;			
		}
		return numDimensions;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	function Get1DimensionGraphScript(arrayElements, graphId)
	{
		var str = "";
		var numOfElements = arrayElements.length;
		var yPlot = new Array();
		var numOfDisplayElements = ((gArrayMeasurementFilter == 1 || gArrayMeasurementFilter == 3) && numOfElements  > gArrayMeasurementMax) ? gArrayMeasurementMax : numOfElements;
		var bDoDecimation = (gArrayMeasurementFilter == 3 && numOfElements  > gArrayMeasurementMax);
		var inc = bDoDecimation ? Math.floor(numOfElements/gArrayMeasurementMax) : 1;
		var elementIndex = 0;
		for(var i=0;i < numOfDisplayElements; ++i)
		{
			var currentElement = arrayElements.item(elementIndex);
			var currentElementAttributes = currentElement.attributes;
			var position = currentElementAttributes.getNamedItem("position").value;
			yPlot[i] = currentElementAttributes.getNamedItem("value").value;		
			elementIndex += inc;
		}
		str = "[" + yPlot.join(", ") + "]";
		str = "TSGRAPH" + graphId + ".PlotY(" + str + ",0," + inc + ")";
		return str;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
		function Get2DimensionGraphScript(arrayElements, graphId, sDataOrientation, sDataLayout, dimensions)
	{
		var arrayString = "";	
		var numOfElements = arrayElements.length;
		var graphs = new Array();
		var bIsColBasedDataOrientation = (sDataOrientation.toLowerCase() == "column based");
		var bDoDecimation = (gArrayMeasurementFilter == 3);
		var indexOfDimensionsSeparator = dimensions.indexOf(",");
		var numberOfRows = parseInt(dimensions.substring(1, indexOfDimensionsSeparator));
		var numberOfCols = parseInt(dimensions.substring(indexOfDimensionsSeparator+1, dimensions.length-1));
		var colInc = 1;
		var rowInc = 1;
		var inc = 1;
		var numberOfRowsToDisplay = numberOfRows;
		var numberOfColsToDisplay = numberOfCols;
		var i = 0;

		if( gArrayMeasurementFilter == 1 || gArrayMeasurementFilter == 3) // "Include upto max" or "Decimate if larger than max"
		{
			if(bIsColBasedDataOrientation)
			{
				// A plot is drawn for each column in the 2D array
				if(numberOfRows > gArrayMeasurementMax)
				{
					inc = rowInc = (bDoDecimation) ? Math.floor(numberOfRows / gArrayMeasurementMax) : 1;
					numberOfRowsToDisplay = gArrayMeasurementMax;
				}
			}
			else
			{
				// A plot is drawn for each row in the 2D array
				if(numberOfCols > gArrayMeasurementMax)
				{
					inc = colInc = (bDoDecimation) ? Math.floor(numberOfCols / gArrayMeasurementMax) : 1;
					numberOfColsToDisplay = gArrayMeasurementMax;
				}
			}
		}
		
		for(i = 0; i<numberOfRows; i++)
			graphs[i] = new Array();
			
		for(i=0;i < numOfElements; ++i)
		{
			var currentElement = arrayElements.item(i);
			var currentElementAttributes = currentElement.attributes;
			var position = currentElementAttributes.getNamedItem("position").value;
			var graphIndex = parseInt(position.substr(1, position.search(",")-1));
			graphs[graphIndex].push(currentElementAttributes.getNamedItem("value").value);					
		}
		
		arrayString += "[[";
		var countOfRowsAdded = 0;
		for(i = 0; i < numberOfRows; i += rowInc)
		{
			if(++countOfRowsAdded > numberOfRowsToDisplay || graphs[i].length <= 0)
				break;
			if (i  >0)
				arrayString += ", [";
			var countOfColsAdded = 0;
			for (var j = 0; j < graphs[i].length; j += colInc)
			{
				if(++countOfColsAdded > numberOfColsToDisplay)
					break;
				if (j> 0)
					arrayString += ", ";
				arrayString += graphs[i][j];
			}
			arrayString += "]";
		}
		arrayString += "]";
		
		var returnStr = 'TSGRAPH' + graphId + '.Plot2DArrayData(' + arrayString +  ',"' + sDataLayout + '", "' + sDataOrientation + '", "True", ' + inc + ')\n';
		return returnStr;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	/**
		 Functions to escape special xml characters.
	**/
	var tagsToReplace = {
		'&': '&amp;',
		'<': '&lt;',
		'>': '&gt;'
	};
	
	function replaceTag(tag) {
		return tagsToReplace[tag] || tag;
	}
	
	function safe_tags_replace(str) {
		return str.replace(/[&<>]/g, replaceTag);
	}	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	/**
		 Put UUT link in Batch Report.
	**/
	function GetLinkURL(nodelist)
	{
		var node = nodelist.item(0);
		var anchorName = node.getAttribute("anchorName"); 
		var uutURI = node.getAttribute("uutURI");
		var linkName = safe_tags_replace(node.getAttribute("linkName"));
		var socketIndex = node.getAttribute("socketIndex");
		var normalizedLinkName = linkName.replace(/^\s*|\s*$/g, "");
		
		if(normalizedLinkName=="")
			linkName = "NONE";
		
		var sRet = "<a"; 
		
		if (anchorName != "")
			sRet += " href = \"" +  uutURI + "#" + socketIndex + "-" + anchorName + "\" ";
			
		sRet += ">" +  linkName + "</a>";
		
		return sRet;
	}
	/**
		 Get Localized date string
	**/
	function GetLocalizedDate(year, month, day)
	{
		var localizedDate = new Date(year, month-1, day);
		return localizedDate.toLocaleDateString();
	}
	/**
		 Get Localized time string
	**/
	function GetLocalizedTime(hours, minutes, seconds, milliseconds)
	{
		var localizedTime = new Date(0, 0, 0, hours, minutes, seconds, milliseconds);
		return localizedTime.toLocaleTimeString();
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/**
		Functions to compute the limit threshold values
	**/
	function GetLimitThresholdValue(thresholdType, limitType, nominal, lowHigh, isLow)
	{
		var computedLimitValue = 0;
		var returnValue = "";
		
		thresholdType = thresholdType.item(0).text;
		limitType = limitType.item(0).nodeValue;
		nominal = nominal.item(0).nodeValue;
		lowHigh = lowHigh.item(0).nodeValue;
		
		var base = 0;
		var prefix = "";
		var isDecimal = false;
    var isUnsigned = false;
		var missingTestStandNumberPrefix = "";
		
		switch (limitType)
		{
			case "ts:TS_binary" :
				base = 2;
				prefix = missingTestStandNumberPrefix = "0b";
				break;
			case "ts:TS_octal" :
				base = 8;
				prefix = missingTestStandNumberPrefix = "0c";
				break;
			case "ts:TS_hexadecimal" :
				base = 16;
				prefix = missingTestStandNumberPrefix = "0x";
				break;
			case "ts:TS_unsignedInteger" :
				base = 10;
				isUnsigned = true;
				break;
			case "ts:TS_integer" :
				base = 10;
				break;
			default :
				base = 10;
				prefix = "";
				isDecimal = true;
				break;
		}
		
		var nominalDecimal = Number(nominal);
		var lowHighDecimal = Number(lowHigh); 
		var lowhigh = lowHigh.toString();
		var nominalString = nominal.toString();
		
		if(lowhigh == "INF")
			lowHighDecimal = +Infinity;
		else if(lowhigh == "-INF")
			lowHighDecimal = -Infinity;
		
		if(nominalString == "INF")
			nominalDecimal = +Infinity;
		else if(nominalString == "-INF")
			nominalDecimal = -Infinity;
		
		var sign = "-";
		var thresholdTypeSymbol = "%";
		var space = " ";
		
		var sign = "-";
		var thresholdTypeSymbol = "%";
		var space = " ";
		
		switch (thresholdType)
		{
			case "PERCENTAGE" :
				if (isLow == true)
				{
					if(nominalDecimal > 0)
					{
					computedLimitValue = nominalDecimal - lowHighDecimal/100*nominalDecimal;
					}
					else
					{
					computedLimitValue = nominalDecimal + lowHighDecimal/100*nominalDecimal;
					sign = "+";
					}
				}
				else
				{   if(nominalDecimal > 0)
					{
					computedLimitValue = nominalDecimal + lowHighDecimal/100*nominalDecimal;
					sign = "+";
					}
					else
					{
					computedLimitValue = nominalDecimal - lowHighDecimal/100*nominalDecimal;
					}
				}
				break;
			
			case "PPM" :
				if (isLow == true)
				{
					if(nominalDecimal > 0)
					{
					computedLimitValue = nominalDecimal - lowHighDecimal/1000000*nominalDecimal;
					}
					else
					{
					computedLimitValue = nominalDecimal + lowHighDecimal/1000000*nominalDecimal;
					sign = "+";
					}
				}
				else
				{	if(nominalDecimal > 0)
					{
					computedLimitValue = nominalDecimal + lowHighDecimal/1000000*nominalDecimal;
					sign = "+";
					}
					else
					{
					computedLimitValue = nominalDecimal - lowHighDecimal/1000000*nominalDecimal;
					}
				}
				thresholdTypeSymbol = "PPM";
				break;
				
			case "DELTA" :
				if (isLow == true)
				{
					computedLimitValue = nominalDecimal - lowHighDecimal;
				}
				else
				{
					computedLimitValue = nominalDecimal + lowHighDecimal;
					sign = "+";
				}
				thresholdTypeSymbol = "";
				space = "";
				break;
		}
		
		if (isDecimal == false)
		{
			computedLimitValue = Math.floor(computedLimitValue);
			lowHighDecimal = Math.floor(lowHighDecimal);
		}
					
		
		if (isNaN(computedLimitValue) == true)
		{
			if(isNaN(lowHighDecimal) == true )
			{
				returnValue = prefix + "NAN" + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                    "NAN" + space + thresholdTypeSymbol + ")";
			}
			else if(lowHighDecimal == +Infinity || lowHighDecimal == -Infinity)
			{
				returnValue = prefix + "NAN" + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                    (lowHighDecimal < 0 ? "-INF" : "+INF") + space + thresholdTypeSymbol + ")";
			}
			else
			{
				returnValue = prefix + "NAN"  + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                    (isUnsigned? (lowHighDecimal >>> 0).toString(base): lowHighDecimal.toString(base)) + space + thresholdTypeSymbol + ")";
			}
	
		}
		else if(computedLimitValue == +Infinity || computedLimitValue == -Infinity || lowHighDecimal == +Infinity || lowHighDecimal == -Infinity)
		{				
			if(lowHighDecimal == +Infinity || lowHighDecimal == -Infinity)
			{
				returnValue = prefix + (computedLimitValue < 0 ? "-INF" : "+INF")  + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                    (lowHighDecimal < 0 ? "-INF" : "+INF") + space + thresholdTypeSymbol + ")";
			}
			else
			{
				returnValue = prefix + (computedLimitValue < 0 ? "-INF" : "+INF")  + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                    (isUnsigned? (lowHighDecimal >>> 0).toString(base): lowHighDecimal.toString(base)) + space + thresholdTypeSymbol + ")";
			}
		}
		else
		{
			returnValue = prefix + (isUnsigned?(computedLimitValue >>> 0).toString(base) : computedLimitValue.toString(base)) + " (Nominal " + sign + " " + missingTestStandNumberPrefix + 
                              (isUnsigned?(lowHighDecimal >>> 0).toString(base) : lowHighDecimal.toString(base)) + space + thresholdTypeSymbol + ")";
		}
				
		return returnValue;
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	]]></msxsl:script>
	<xsl:output method="html" indent="no" omit-xml-declaration="yes" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"/>
	<!-- Customization variables-->
	<xsl:variable name="gIndentSequenceCalls" select="true()"/>
	<xsl:variable name="gDisplayNewLineAndHTMLElementInStringProperty" select="false()"/>
	<xsl:variable name="gRemoveIndentationFunctionality" select="false()"/>
	<xsl:variable name="gSequenceCallNegativeIndent">
		<xsl:choose>
			<xsl:when test="$gIndentSequenceCalls = true() and $gRemoveIndentationFunctionality = false()">
				<xsl:value-of select="0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="-40"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:template name="GetTotalTimeInHHMMSSFormat">
		<xsl:param name="timeInSeconds" select="0"/>
		<xsl:variable name="totalSeconds" select="number($timeInSeconds)"/>
		<xsl:variable name="noOfHours" select="floor($totalSeconds div 3600)"/>
		<xsl:variable name="noOfMinutesInSeconds" select="$totalSeconds mod 3600"/>
		<xsl:variable name="noOfMinutes" select="floor($noOfMinutesInSeconds div 60)"/>
		<xsl:variable name="noOfSeconds" select="$noOfMinutesInSeconds mod 60"/>
		<xsl:variable name="noOfMilliSeconds" select="number(substring(substring-after($timeInSeconds,'.'),1,4)) div 10"/>
		<xsl:value-of select="concat(format-number($noOfHours,'00'),':',format-number($noOfMinutes,'00'),':',format-number($noOfSeconds,'00'),'.',format-number($noOfMilliSeconds,'000'))"/>
	</xsl:template>
	<!--End of Customization-->
	<xsl:variable name="gStylesheetPath">
		<xsl:call-template name="GetStylesheetPath"/>
	</xsl:variable>
	<xsl:variable name="gSingleSpaceValue" select="20"/>
	<xsl:variable name="gPlusPassedImage" select="'plusPassed.gif'"/>
	<xsl:variable name="gPlusDoneImage" select="'plusDone.gif'"/>
	<xsl:variable name="gPlusErrorImage" select="'plusError.gif'"/>
	<xsl:variable name="gPlusFailedImage" select="'plusFailed.gif'"/>
	<xsl:variable name="gPlusRunningImage" select="'plusRunning.gif'"/>
	<xsl:variable name="gPlusSkippedImage" select="'plusSkipped.gif'"/>
	<xsl:variable name="gPlusTerminatedImage" select="'plusTerminated.gif'"/>
	<xsl:variable name="gMinusPassedImage" select="'minusPassed.gif'"/>
	<xsl:variable name="gMinusDoneImage" select="'minusDone.gif'"/>
	<xsl:variable name="gMinusErrorImage" select="'minusError.gif'"/>
	<xsl:variable name="gMinusFailedImage" select="'minusFailed.gif'"/>
	<xsl:variable name="gMinusRunningImage" select="'minusRunning.gif'"/>
	<xsl:variable name="gMinusSkippedImage" select="'minusSkipped.gif'"/>
	<xsl:variable name="gMinusTerminatedImage" select="'minusTerminated.gif'"/>
	<xsl:variable name="gGraphControlInstalled">
		<xsl:choose>
			<xsl:when test="function-available('user:IsGraphControlInstalled')">
				<xsl:value-of select="number(user:IsGraphControlInstalled())"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="0"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="gSecondColumnWidth" select="'37%'"/>
	<xsl:variable name="gSpace">
		<xsl:text disable-output-escaping="yes"> </xsl:text>
	</xsl:variable>
	<xsl:template match="/">
		<html>
			<head>
				<title> Report</title>
				<style type="text/css">
					body {font-family:VERDANA;}
					img {margin-right:5px;}
					img.expandCollapseAll{width:26px; height:28px; border-style:none; cursor:pointer;}
					img.expandCollapse{border-style:none; cursor:pointer}
					table.uutTable{width:70%;font-weight:bold;}
					table.stepTable{width:60%;border-width:1px;border-style:double;}
					table.stepTable td{border-width:1px;border-style:double;font-size:80%;}
					table.batchTable{width:70%;font-weight:bold;}
					table.uutHrefTable{width:80%;border-width:1px;border-style:double;}
					table.uutHrefTable td{border-width:1px;border-style:double; text-align:center}
					hr.headerSeparator{text-align:left;height:3px;width:50%;margin-left:0px;border-width:0px;}
					hr.uutSeparator{text-align:center;height:5px;width:90%;}
					hr.batchSeparator{text-align:center;height:5px;width:90%;}
					div{position:relative; padding:5px;}
					div.expanded{diplay:inline;}
					div.collapsed{display:none;}
					span.stepName{font-weight:bold;}
					span.stepText{font-size:100%;}
					table.criticalFailureTable{width:70%;border-width:1px;border-style:double;margin-left:5px;}
					table.criticalFailureTable td{border-width:1px;border-style:double;font-size:94%;}
					span.stepText{font-size:94%;}
					/*The following styles are added so that xmlpack can correctly pack the icons. 
					The javascript or the xslt handles displaying the icons/images correctly by converting them to absolute paths.*/
                   .gPlusPassedImage {background-image:url("plusPassed.gif");}
				   .gPlusDoneImage {background-image:url("plusDone.gif");}
				   .gPlusErrorImage{background-image:url("plusError.gif");}
				   .gPlusFailedImage{background-image:url("plusFailed.gif");}
				   .gPlusRunningImage{background-image:url("plusRunning.gif");}
				   .gPlusSkippedImage{background-image:url("plusSkipped.gif");}
				   .gPlusTerminatedImage{background-image:url("plusTerminated.gif");}
				   .gMinusPassedImage {background-image:url("minusPassed.gif");}
				   .gMinusDoneImage {background-image:url("minusDone.gif");}
				   .gMinusErrorImage{background-image:url("minusError.gif");}
				   .gMinusFailedImage{background-image:url("minusFailed.gif");}
				   .gMinusRunningImage{background-image:url("minusRunning.gif");}
				   .gMinusSkippedImage{background-image:url("minusSkipped.gif");}
				   .gMinusTerminatedImage{background-image:url("minusTerminated.gif");}				   
				</style>
				<script type="text/javascript">
					//<![CDATA[		
					var gStylesheetpath = "";	
					/** A function to initialize the global variable with the stylesheet path**/	
					setStylesheetPath = function(path)
					{
						gStylesheetpath = path;
					}	
					/** A function to return the image path depending on whether the file was packed using the XMLPack utility.
					**/	
					getImageAbsolutePath = function(imageFileName)
					{
						var path ="";	
						path = gStylesheetpath +  imageFileName;
						return path;	
					}

					/**A function to get a list of child elements with className attribute set to the style specified using className
					FireFox has inbuilt method, IE does'nt have one.
					**/	
					getElementsByClassName = function(className, childElement) 
					{
						var found = [];
						var childTagName = childElement ? childElement : "*";
						//In case childTagName is not null search only child elements of the type specified using that parameter otherwise
						//search all child elements.	
						var elements = this.getElementsByTagName(childTagName);
						for (var i = 0; i < elements.length; ++i) 
						{
							var elementClassName = elements[i].className;
							if (elementClassName == className) 
								found.push(elements[i]);
						}
						return found;
					}

					var gExpandCollapseState = "collapsed";

					/** An array cache of all divs in HTML body, this will calculate all expand collapse divs once and 
					 store in this global array so that performance is improved for expand/collapse actions from second time**/
					var gExpandCollapseImagesArray; 


					/**Apply Expand/Collapse functionality for image element, this will be called by onClick event of img element
					**/
					expandCollapse = function(event)
					{
						var imgElem = event.target || event.srcElement;			
						expandCollapseImageDiv(imgElem);
					}

					/**Apply Expand/Collapse functionality for div element which contains imgElem
						imgElem - DOM object of img element
					**/
					expandCollapseImageDiv = function(imgElem)
					{
						var parentDiv =imgElem;
						while(parentDiv.tagName != "DIV")
							parentDiv = parentDiv.parentNode;
						var expCollDiv = parentDiv.getElementsByTagName("div")[0]
						if(expCollDiv)
						{
							var imgSrc = imgElem.src;
							var indexOfLastSlash  = imgSrc.lastIndexOf('/') + 1;
							var imgPath = imgSrc.slice(0,indexOfLastSlash);
							var imgName = imgSrc.slice(indexOfLastSlash);
							if(expCollDiv.className == "expanded")
							{
								expCollDiv.className="collapsed";
								imgName = imgName.replace("minus","plus");
							}	
							else
							{
								expCollDiv.className="expanded";
								imgName = imgName.replace("plus","minus");
							}	
							imgElem.src=imgPath+imgName;
						}
					}

					/**Change classname for DIV element, so that it is visible and expanded
						imgElem - DOM object of img element
					**/
					expandImageDiv = function(imgElem)
					{
						var parentDiv =imgElem;
						while(parentDiv.tagName != "DIV")
							parentDiv = parentDiv.parentNode;
						var expCollDiv = parentDiv.getElementsByTagName("div")[0]
						if(expCollDiv)
						{
							var imgSrc = imgElem.src;
							var indexOfLastSlash  = imgSrc.lastIndexOf('/') + 1;
							var imgPath = imgSrc.slice(0,indexOfLastSlash);
							var imgName = imgSrc.slice(indexOfLastSlash);
							expCollDiv.className="expanded";
							imgName = imgName.replace("plus","minus");					
							imgElem.src=imgPath+imgName;
						}
					}
					/**Change classname for DIV element, so that it is hidden and collapsed
						imgElem - DOM object of img element
					**/
					collapseImageDiv = function(imgElem)
					{
						var parentDiv =imgElem;
						while(parentDiv.tagName != "DIV")
							parentDiv = parentDiv.parentNode;
						var expCollDiv = parentDiv.getElementsByTagName("div")[0]
						if(expCollDiv)
						{
							var imgSrc = imgElem.src;
							var indexOfLastSlash  = imgSrc.lastIndexOf('/') + 1;
							var imgPath = imgSrc.slice(0,indexOfLastSlash);
							var imgName = imgSrc.slice(indexOfLastSlash);
							expCollDiv.className="collapsed";
							imgName = imgName.replace("minus","plus");	
							imgElem.src=imgPath+imgName;
						}
					}
					/** A High level expand/collapse function which will expand or collapse all the DIVs in HTML body 
					**/
					expandCollapseAll = function(event)
					{
						var rootImgElem = event.target || event.srcElement;			
						if(!gExpandCollapseImagesArray)
						{
							document.getElementsByClassName = getElementsByClassName;
							gExpandCollapseImagesArray =  document.getElementsByClassName("expandCollapse", "img");
						}						
						if (gExpandCollapseState == "expanded")
						{
							for(var i=0; i<gExpandCollapseImagesArray.length;++i)
							{
								collapseImageDiv(gExpandCollapseImagesArray[i]);
							}
							rootImgElem.src =getImageAbsolutePath("button_expand.gif");
							gExpandCollapseState="collapsed";
						}
						else
						{
							for(var i=0; i<gExpandCollapseImagesArray.length;++i)
							{
								expandImageDiv(gExpandCollapseImagesArray[i]);
							}
							rootImgElem.src =getImageAbsolutePath("button_collapse.gif");
							gExpandCollapseState="expanded";

						}
					}
					
					expandTable = function(event)
					{
						
						var anchorElement = event.target || event.srcElement;		
						var anchorHref = anchorElement.href;
						var indexOfHash = anchorHref.lastIndexOf('#');
						var id = anchorHref.substring(indexOfHash + 1);
						var tableElement = document.getElementById(id);
						var parentElement = tableElement.parentNode;
						while(parentElement.tagName != "BODY")
						{
							if(parentElement.tagName=='DIV' && parentElement.className=='collapsed')
							{
								var imgElem = parentElement.parentNode.getElementsByTagName("IMG")[0];
								var imgSrc = imgElem.src;
								var indexOfLastSlash  = imgSrc.lastIndexOf('/') + 1;
								var imgPath = imgSrc.slice(0,indexOfLastSlash);
								var imgName = imgSrc.slice(indexOfLastSlash);
								parentElement.className="expanded";
								imgName = imgName.replace("plus","minus");					
								imgElem.src=imgPath+imgName;
							}
							parentElement = parentElement.parentNode;
						}
						window.location.href = anchorHref;
						return false;
					}
					
					
					//Perform any initialization in this method and add dynamic event handlers here	
					init = function(path)
					{																	
						setStylesheetPath(path);
					}
						//]]></script>
			</head>
			<body onload="init('{$gStylesheetPath}');">
				<!-- ADD_HEADER_INFO Section to add some header Text/Image to the entire report-->
				<!--img src = 'C:/Images/CompanyLogo.jpg'/>
					<span style="font-size:1.13em;color:#003366;">Computer Motherboard Test</span>
					<br/-->
				<xsl:if test="function-available('user:InitializeStylesheetPath')">
					<xsl:value-of select="user:InitializeStylesheetPath(string($gStylesheetPath))"/>
				</xsl:if>
				<xsl:value-of select="user:GetImageHTMLForImageName('button_Expand.gif','expandCollapseAll')" disable-output-escaping="yes"/>
				<b> Expand/Collapse All Step Results</b>
				<xsl:for-each select="//trc:TestResults|//trc:Extension">
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<!-- ADD_FOOTER_INFO Section to add some footer Text/Image to the entire report-->
				<!--span style="font-size:1.13em;color:#003366;">TestStand Generated Report</span-->
			</body>
		</html>
	</xsl:template>
	<xsl:template match="trc:Extension">
		<h3>Batch Report</h3>
		<table class="batchTable">
			<tr>
				<td>Station ID:</td>
				<td>
					<xsl:value-of select="ts:TSBatchTable/@stationID"/>
				</td>
			</tr>
			<tr>
				<td>Serial Number:</td>
				<td>
					<xsl:choose>
						<xsl:when test="ts:TSBatchTable/@batchSerialNumber != ''">
							<xsl:value-of select="ts:TSBatchTable/@batchSerialNumber"/>
						</xsl:when>
						<xsl:otherwise>NONE</xsl:otherwise>
					</xsl:choose>
				</td>
			</tr>
			<tr>
				<td>Date:</td>
				<td>
					<xsl:call-template name="GetUUTDate">
						<xsl:with-param name="date" select="substring-before(ts:TSBatchTable/@startDateTime,'T')"/>
					</xsl:call-template>
				</td>
			</tr>
			<tr>
				<td>Time:</td>
				<td>
					<xsl:call-template name="GetUUTTime">
						<xsl:with-param name="dateTime" select="ts:TSBatchTable/@startDateTime"/>
					</xsl:call-template>
				</td>
			</tr>
			<tr>
				<td>Operator:</td>
				<td>
					<xsl:value-of select="ts:TSBatchTable/@operator"/>
				</td>
			</tr>
			<xsl:if test="ts:TSBatchTable/ts:TSRData">
				<tr>
					<td>TSR File Name:</td>
					<td>
						<xsl:value-of select="ts:TSBatchTable/ts:TSRData/@TSRFileName"/>
					</td>
				</tr>
				<tr>
					<td>TSR File ID:</td>
					<td>
						<xsl:value-of select="ts:TSBatchTable/ts:TSRData/@TSRFileID"/>
					</td>
				</tr>
				<tr>
					<td>TSR File Closed:</td>
					<td>
						<xsl:choose>
							<xsl:when test="ts:TSBatchTable/ts:TSRData/@TSRFileClosed = 'true'">OK</xsl:when>
							<xsl:otherwise>The .tsr file was not closed normally when written. This can indicate that the testing process was interrupted or aborted.</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
			</xsl:if>
		</table>
		<br/>
		<xsl:variable name="colors" select="ts:TSBatchTable/ts:ReportOptions/c:Item[@name='Colors']/c:Collection"/>
		<table class="uutHrefTable" style="border-color:{$colors/c:Item[@name='TableBorder']/c:Datum/c:Value};margin-left:20px;">
		<xsl:variable name="batchBgColor" select="$colors/c:Item[@name='BatchHeadingBg']/c:Datum/c:Value"/>
			<tr style="background-color:{$batchBgColor};font-weight:bold">
				<td>Test Socket</td>
				<td>UUT Serial Number</td>
				<td>UUT Result</td>
			</tr>
			<xsl:apply-templates select="ts:TSBatchTable/ts:UUTHref">
				<xsl:with-param name="colors" select="$colors"/>
			</xsl:apply-templates>
		</table>
		<br/>
		<h3>End Batch Report</h3>
		<xsl:variable name="uutSeparatorColor" select="$colors/c:Item[@name='UUTSeparator']/c:Datum/c:Value"/>
		<hr style="color:{$uutSeparatorColor};background-color:{$uutSeparatorColor}" class="batchSeparator"/>
	</xsl:template>
	<xsl:template match="ts:UUTHref">
		<xsl:param name="colors"/>
		<tr>
			<td>
			<xsl:choose>
				<xsl:when test="string(@socketIndex) != ''">
					<xsl:value-of select="@socketIndex"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			</td>
			<td>
				<xsl:value-of select="user:GetLinkURL(.)" disable-output-escaping="yes"/>
			</td>
			<xsl:variable name="uutResultBgColor">
				<xsl:call-template name="GetUutResultBgColor">
					<xsl:with-param name="status" select="@uutResult"/>
					<xsl:with-param name="colors" select="$colors"/>
				</xsl:call-template>
			</xsl:variable>
			<td style="background-color:{$uutResultBgColor}">
				<xsl:choose>
					<xsl:when test="string(@uutResult) != ''">
						<xsl:value-of select="@uutResult"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="ts:ModuleTime">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td style="background-color:{$labelBgColor};">Module Time:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="@value"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="ts:LoopingProperties">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td style="background-color:{$labelBgColor};">Number of Loops:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="ts:NumLoops/@value"/>
			</td>
		</tr>
		<tr>
			<td style="background-color:{$labelBgColor};">Number of Passes:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="ts:NumPassed/@value"/>
			</td>
		</tr>
		<tr>
			<td style="background-color:{$labelBgColor};">Number of Failures:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="ts:NumFailed/@value"/>
			</td>
		</tr>
		<tr>
			<td style="background-color:{$labelBgColor};">Final Loop Index:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="ts:EndingLoopIndex/@value"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="trc:TestResults">
		<xsl:variable name="reportOptions" select="tr:TestProgram/tr:Configuration/c:Collection"/>		
		<xsl:variable name="labelBgColor" select="$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='LabelBg']/c:Datum/c:Value"/>
		<xsl:variable name="valueBgColor" select="$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='ValueBg']/c:Datum/c:Value"/>
		<xsl:variable name="includeAttributes" select="$reportOptions/c:Item[@name='IncludeAttributes']/c:Datum/@value = 'true'"/>
		<xsl:variable name="includeMeasurements" select="$reportOptions/c:Item[@name='IncludeMeasurements']/c:Datum/@value = 'true'"/>
		<xsl:variable name="includeLimits" select="$reportOptions/c:Item[@name='IncludeLimits']/c:Datum/@value = 'true'"/>
		<xsl:variable name="includeArrayMeasurement" select="concat($reportOptions/c:Item[@name='IncludeArrayMeasurement']/c:Datum/@value,'')"/>
		<xsl:variable name="arrayMeasurementFilter" select="concat($reportOptions/c:Item[@name='ArrayMeasurementFilter']/c:Datum/@value,'')"/>
		<xsl:variable name="arrayMeasurementMax" select="concat($reportOptions/c:Item[@name='ArrayMeasurementMax']/c:Datum/@value,'')"/>
		<xsl:if test="function-available('user:InitArrayMeasurementGlobalVariables')">
			<xsl:value-of select="user:InitArrayMeasurementGlobalVariables($includeArrayMeasurement, $arrayMeasurementFilter, $arrayMeasurementMax)"/>
		</xsl:if>  
        <xsl:call-template name="PutBatchUutLink"/>
		<h3>
			UUT Report
		</h3>
		<table class="uutTable">
			<tr>
				<td>Station ID:</td>
				<td>
					<xsl:value-of select="tr:TestStation/c:SerialNumber"/>
				</td>
			</tr>
			<xsl:if test="string-length(tr:Extension/ts:TSResultSetProperties/ts:BatchSerialNumber/@value)!=0">
				<tr>
					<td>Batch Serial Number:</td>
					<td>
						<xsl:value-of select="tr:Extension/ts:TSResultSetProperties/ts:BatchSerialNumber/@value"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="tr:Extension/ts:TSResultSetProperties/ts:TestSocketIndex">
				<tr>
					<td>Test Socket Index:</td>
					<td>
						<xsl:value-of select="tr:Extension/ts:TSResultSetProperties/ts:TestSocketIndex/@value"/>
					</td>
				</tr>
			</xsl:if>
			<tr>
				<td>Serial Number:</td>
				<td>
					<xsl:value-of select="tr:UUT/c:SerialNumber"/>
				</td>
			</tr>
			<tr>
				<td>Date:</td>
				<td>
					<xsl:call-template name="GetUUTDate">
						<xsl:with-param name="date" select="substring-before(tr:ResultSet/@startDateTime,'T')"/>
					</xsl:call-template>
				</td>
			</tr>
			<tr>
				<td>Time:</td>
				<td>
					<xsl:call-template name="GetUUTTime">
						<xsl:with-param name="dateTime" select="tr:ResultSet/@startDateTime"/>
					</xsl:call-template>
				</td>
			</tr>
			<tr>
				<td>Operator:</td>
				<td>
					<xsl:value-of select="tr:Personnel/tr:SystemOperator/@name"/>
				</td>
			</tr>
			<xsl:if test="tr:ResultSet/tr:Extension/ts:TSStepProperties/ts:TotalTime">
				<tr>
					<td>Execution Time:</td>
					<td>
						<xsl:value-of select="tr:ResultSet/tr:Extension/ts:TSStepProperties/ts:TotalTime/@value"/> seconds
						<!--CHANGE_TOTAL_TIME_FORMAT-->
						<!--xsl:call-template name="GetTotalTimeInHHMMSSFormat">
							<xsl:with-param name="timeInSeconds" select="tr:ResultSet/tr:Extension/ts:TSStepProperties/ts:TotalTime/@value"/>
						</xsl:call-template-->
					</td>
				</tr>
			</xsl:if>
			<tr>
				<td>Number of Results:</td>
				<td>
					<xsl:value-of select="tr:Extension/ts:TSResultSetProperties/ts:NumOfResults/@value"/>
				</td>
			</tr>
			<xsl:variable name="statusColor">
				<xsl:call-template name="GetStatusColor">
					<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
					<xsl:with-param name="status" select="tr:ResultSet/tr:Outcome/@value"/>
					<xsl:with-param name="qualifier" select="tr:ResultSet/tr:Outcome/@qualifier"/>
				</xsl:call-template>
			</xsl:variable>
			<tr>
				<td>UUT Result:</td>
				<td>
					<xsl:choose>
						<xsl:when test="tr:ResultSet/tr:Outcome/@qualifier">
							<span style="color:{$statusColor}">
								<xsl:value-of select="tr:ResultSet/tr:Outcome/@qualifier"/>
							</span>
							<span style="font-weight:normal">
								<xsl:if test="tr:ResultSet/tr:Outcome/@qualifier='Error'">
									<xsl:if test="tr:ResultSet/tr:Events/tr:Event[@ID='Error Message']">, <xsl:variable name="errorString">
											<xsl:apply-templates select="tr:ResultSet/tr:Events/tr:Event[@ID='Error Message']/tr:Data/c:Datum">
												<xsl:with-param name="addProperty" select="true()"/>
											</xsl:apply-templates>
										</xsl:variable>
										<xsl:call-template name="ReplaceNewLineWithBreak">
											<xsl:with-param name="inputString" select="$errorString"/>
										</xsl:call-template>
									</xsl:if>
									<xsl:if test="tr:ResultSet/tr:Events/tr:Event[@ID='Error Code']">[Error Code: <xsl:apply-templates select="tr:ResultSet/tr:Events/tr:Event[@ID='Error Code']/tr:Data/c:Datum"><xsl:with-param name="addProperty" select="true()"/></xsl:apply-templates>
										<xsl:if test="tr:ResultSet/tr:Events/tr:Event[@ID='Error Code']/tr:Message">, <xsl:value-of select="tr:ResultSet/tr:Events/tr:Event[@ID='Error Code']/tr:Message" disable-output-escaping="yes"/>
										</xsl:if>]</xsl:if>
								</xsl:if>
							</span>
						</xsl:when>
						<xsl:otherwise>
							<span style="color:{$statusColor}">
								<xsl:value-of select="tr:ResultSet/tr:Outcome/@value"/>
							</span>
						</xsl:otherwise>
					</xsl:choose>
				</td>
			</tr>
			<xsl:if test="tr:UUT/c:Definition/c:Identification/c:IdentificationNumbers/c:IdentificationNumber[@type='Part']">
				<tr>
					<td>Part Number:</td>
					<td><xsl:value-of select="tr:UUT/c:Definition/c:Identification/c:IdentificationNumbers/c:IdentificationNumber[@type='Part']/@number"/></td>
				</tr>
			</xsl:if>
			<xsl:if test="tr:Extension/ts:TSResultSetProperties/ts:TSRData">
				<tr>
					<td>TSR File Name:</td>
					<td>
						<xsl:value-of select="tr:Extension/ts:TSResultSetProperties/ts:TSRData/@TSRFileName"/>
					</td>
				</tr>
				<tr>
					<td>TSR File ID:</td>
					<td>
						<xsl:value-of select="tr:Extension/ts:TSResultSetProperties/ts:TSRData/@TSRFileID"/>
					</td>
				</tr>
				<tr>
					<td>TSR File Closed:</td>
					<td>
						<xsl:choose>
							<xsl:when test="tr:Extension/ts:TSResultSetProperties/ts:TSRData/@TSRFileClosed = 'true'">OK</xsl:when>
							<xsl:otherwise>The .tsr file was not closed normally when written. This can indicate that the testing process was interrupted or aborted.</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
			</xsl:if>
      <xsl:variable name="shouldIncludeInReport">
        <xsl:for-each select="tr:UUT/c:Definition/c:Extension/ts:TSCollection/c:Item[@name='AdditionalData']/c:Collection">
          <xsl:call-template name="GetIsIncludeInReport"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:apply-templates select="tr:UUT/c:Definition/c:Extension/ts:TSCollection/c:Item[@name='AdditionalData']/c:Collection/c:Item">
        <xsl:with-param name="labelBgColor" select="$labelBgColor"/>
        <xsl:with-param name="valueBgColor" select="$valueBgColor"/>
        <xsl:with-param name="numSpaces" select="0"/>
        <xsl:with-param name="parentNode" select="tr:UUT/c:Definition/c:Extension/ts:TSCollection/c:Item[@name='AdditionalData.Attributes']"/>
        <xsl:with-param name="objectPath" select="'AdditionalData'"/>
        <xsl:with-param name="includeAttributes" select="$includeAttributes"/>
        <xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
        <xsl:with-param name="includeLimits" select="$includeLimits"/>
        <xsl:with-param name="addProperty" select="$shouldIncludeInReport='true'"/>
        <xsl:with-param name="putAsFlatData" select="true()"/>
      </xsl:apply-templates>
	  <!-- CREATE_UUTHEADER_INFO: Section to insert additional column to UUT report header-->
		<!--tr>
			 <td>ResultSet ID</td>
			 <td>
				 <xsl:value-of select="tr:ResultSet/@ID"/>
			 </td>
		</tr-->    
		</table>
		<xsl:variable name="criticalFailureStackNode" select="tr:Extension/ts:TSResultSetProperties/ts:CriticalFailureStack"/>
		<xsl:if test="$criticalFailureStackNode">
			<b>
				<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>Failure Chain: </b>
			<br/>
			<xsl:call-template name="AddCriticalFailureStack">
				<xsl:with-param name="criticalFailureStackNode" select="$criticalFailureStackNode"/>
				<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:variable name="headerSeperatorColor" select="$reportOptions/c:Item[@name = 'Colors']/c:Collection/c:Item[@name = 'HeaderSeparator']/c:Datum/c:Value"/>
		<hr style="color:{$headerSeperatorColor};background-color:{$headerSeperatorColor}" class="headerSeparator"/>
		<xsl:apply-templates select="tr:Extension/ts:TSResultSetProperties/ts:ResultListPresent"/>
		<xsl:apply-templates select="tr:ResultSet">
			<xsl:with-param name="reportOptions" select="$reportOptions"/>
			<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
			<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
			<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
			<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
			<xsl:with-param name="includeLimits" select="$includeLimits"/>
		</xsl:apply-templates>
		<h3>End UUT Report</h3>
		<xsl:variable name="uutSeparatorColor" select="$reportOptions/c:Item[@name = 'Colors']/c:Collection/c:Item[@name = 'UUTSeparator']/c:Datum/c:Value"/>
		<hr style="color:{$uutSeparatorColor};background-color:{$uutSeparatorColor}" class="uutSeparator"/>
	</xsl:template>
	<xsl:template match="ts:ResultListPresent">
		<xsl:variable name="indentation">
			<xsl:choose>
				<xsl:when test="@value = 'false'">40</xsl:when>
				<xsl:otherwise>0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="@value = 'false'">
			<h5>
				<span style="margin-left:20px;">
			Begin Sequence:  MainSequence</span>
				<br/>
				<xsl:choose>
				  <xsl:when test="contains(../../../tr:ResultSet/@name,'#')">
				<span style="margin-left:20px;">
					(<xsl:value-of select="substring-before(../../../tr:ResultSet/@name, '#')"/>)
				</span>
				  </xsl:when>
				  <xsl:otherwise>
				<span style="margin-left:20px;">
					(<xsl:value-of select="../../../tr:ResultSet/@name"/>)
				</span>
				  </xsl:otherwise>
			    </xsl:choose>
			</h5>
		</xsl:if>
		<h5 style="margin-left:{$indentation}px;">
			No Sequence Results Found
		</h5>
		<xsl:if test="@value = 'false'">
			<h5>
				<span style="margin-left:20px;">
			End Sequence: MainSequence
				</span>
			</h5>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:ResultSet">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:if test="count(tr:Test|tr:SessionAction|tr:TestGroup)>0">
			<h5>
				<span style="margin-left:20px;">
				Begin Sequence:  MainSequence</span>
				<br/>
					<xsl:choose>
					  <xsl:when test="contains(@name,'#')">	
				<span style="margin-left:20px;">
						(<xsl:value-of select="substring-before(@name, '#')"/>)
					</span>
					  </xsl:when>
					  <xsl:otherwise>
				<span style="margin-left:20px;">
						(<xsl:value-of select="@name"/>)
					</span>
					  </xsl:otherwise>
					</xsl:choose>
			</h5>
			<xsl:apply-templates select="tr:Test|tr:SessionAction|tr:TestGroup">
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
				<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
				<xsl:with-param name="includeLimits" select="$includeLimits"/>
			</xsl:apply-templates>
			<h5>
				<span style="margin-left:20px;">
				End Sequence: MainSequence
				</span>
			</h5>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:Test">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="isLoopIndexStep" select="false()"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="endingLoopIndex" select="tr:Extension/ts:TSStepProperties/ts:LoopingProperties/ts:EndingLoopIndex"/>
		<xsl:variable name="loopIndex" select="tr:Extension/ts:TSStepProperties/ts:LoopingProperties/ts:LoopIndex"/>
		<xsl:variable name="indentation">
			<xsl:call-template name="GetIndentationMargin"/>
		</xsl:variable>
		<xsl:variable name="expandCollapseState">
			<xsl:call-template name="GetExpandCollapseState">
				<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
				<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="not($loopIndex) or $isLoopIndexStep">
			<div class="expandCollapse" style="left:{$indentation}px;">
				<xsl:call-template name="GetStepResultImage">
					<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
					<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
					<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
				</xsl:call-template>
				<span class="stepName">
					<xsl:choose>
						<xsl:when test="@callerName">
							<xsl:value-of select="@callerName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</span>
				<div class="{$expandCollapseState}" style="left:40px;">
					<table class="stepTable" id="{concat('ResultId',@ID)}" style="border-color:{$reportOptions/c:Item[@name = 'Colors']/c:Collection/c:Item[@name = 'TableBorder']/c:Datum/c:Value};">
						<tr>
							<xsl:variable name="stepGroupBgColor">
								<xsl:call-template name="GetStepGroupBgColor">
									<xsl:with-param name="stepGroupName" select="tr:Extension/ts:TSStepProperties/ts:StepGroup"/>
									<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
								</xsl:call-template>
							</xsl:variable>
							<td colspan="2" style="background-color:{$stepGroupBgColor};">
								
									<a name="{concat('ResultId',@ID)}"/>
								
								<span class="stepText">
									<xsl:choose>
										<xsl:when test="@callerName">
											<xsl:value-of select="@callerName"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@name"/>
										</xsl:otherwise>
									</xsl:choose>
								</span>
							</td>
						</tr>
						<xsl:apply-templates select="tr:Outcome">
							<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
						</xsl:apply-templates>
						<xsl:if test="tr:Outcome/@qualifier='Error'">
							<xsl:call-template name="ReportError">
								<xsl:with-param name="eventsNode" select="tr:Events"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:call-template>
						</xsl:if>
						<xsl:apply-templates select="tr:TestResult[(@name='Numeric' or @name='String') and (count(tr:TestLimits)=1 or count(tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog)=1)]">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:call-template name="PutMeasurements">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:call-template>
						<xsl:apply-templates select="tr:Parameters">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:variable name="dataValue">
							<xsl:apply-templates select="tr:TestResult[count(tr:TestLimits)=0 and count(tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog)=0 and @name!='ReportText']">
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="numSpaces" select="1"/>
								<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
								<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
								<xsl:with-param name="includeLimits" select="$includeLimits"/>
							</xsl:apply-templates>
						</xsl:variable>
						<xsl:if test="$dataValue!=''">
							<tr>
								<td colspan="2" style="background-color:{$labelBgColor};">TestResults/Data:</td>
							</tr>
							<xsl:copy-of select="$dataValue"/>
						</xsl:if>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:ModuleTime">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:if test="$endingLoopIndex">
							<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:LoopingProperties">
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:apply-templates select="tr:TestResult[@name='ReportText']">
							<xsl:with-param name="bgColor" select="$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='ReportTextBg']"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:InteractiveExecutionId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:RemoteServerId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<!-- ADD_EXTRA_ROWS-->
						<!--tr>
								<td>StepID</td>
								<td><xsl:value-of select="@testReferenceID"/></td>
							</tr-->
					</table>
				</div>
			</div>
		</xsl:if>
		<xsl:if test="$endingLoopIndex">
			<div class="expandCollapse" style="left:{$indentation}px;">
				<xsl:call-template name="GetStepResultImage">
					<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
					<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
					<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
				</xsl:call-template>
				<span class="stepName">
					<xsl:choose>
						<xsl:when test="@callerName">
							<xsl:value-of select="@callerName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>(Loop Indices)
				</span>
				<div class="{$expandCollapseState}" style="left:0px;">
					<xsl:variable name="endingPositionValue">
						<xsl:call-template name="GetNumberInDecimal">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="number" select="$endingLoopIndex/@value"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:for-each select="following-sibling::*[position() &lt;= $endingPositionValue]">
						<xsl:apply-templates select=".">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="isLoopIndexStep" select="true()"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
					</xsl:for-each>
				</div>
			</div>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:SessionAction">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="isLoopIndexStep" select="false()"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="indentation">
			<xsl:call-template name="GetIndentationMargin">
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="loopIndex" select="tr:Extension/ts:TSStepProperties/ts:LoopingProperties/ts:LoopIndex"/>
		<xsl:if test="not($loopIndex) or $isLoopIndexStep">
			<div class="expandCollapse" style="left:{$indentation}px;">
				<xsl:variable name="expandCollapseState">
					<xsl:call-template name="GetExpandCollapseState">
						<xsl:with-param name="outcome" select="tr:ActionOutcome/@value"/>
						<xsl:with-param name="qualifier" select="tr:ActionOutcome/@qualifier"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:call-template name="GetStepResultImage">
					<xsl:with-param name="outcome" select="tr:ActionOutcome/@value"/>
					<xsl:with-param name="qualifier" select="tr:ActionOutcome/@qualifier"/>
					<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
				</xsl:call-template>
				<span class="stepName">
					<xsl:value-of select="@name"/>
				</span>
				<div class="{$expandCollapseState}" style="left:40px;">
					<table class="stepTable" id="{concat('ResultId',@ID)}" style="border-color:{$reportOptions/c:Item[@name = 'Colors']/c:Collection/c:Item[@name = 'TableBorder']/c:Datum/c:Value};">
						<xsl:variable name="isFlowType">
							<xsl:call-template name="CheckIfTypeFlow"/>
						</xsl:variable>
						<tr>
							<xsl:variable name="stepGroupBgColor">
								<xsl:call-template name="GetStepGroupBgColor">
									<xsl:with-param name="stepGroupName" select="tr:Extension/ts:TSStepProperties/ts:StepGroup"/>
									<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
								</xsl:call-template>
							</xsl:variable>
							<td colspan="2" style="background-color:{$stepGroupBgColor};">								
									<a name="{concat('ResultId',@ID)}"/>
								<span class="stepText">
									<xsl:value-of select="@name"/>
									<xsl:if test="$isFlowType='True'">
										<xsl:apply-templates select="tr:Data/c:Collection/c:Item[@name='ReportText']/c:Datum">
											<xsl:with-param name="addProperty" select="true()"/>
										</xsl:apply-templates>
									</xsl:if>
								</span>
							</td>
						</tr>
						<xsl:apply-templates select="tr:ActionOutcome">
							<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
						</xsl:apply-templates>
						<xsl:if test="tr:ActionOutcome/@qualifier='Error'">
							<xsl:call-template name="ReportError">
								<xsl:with-param name="eventsNode" select="tr:Events"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:call-template>
						</xsl:if>
						<xsl:apply-templates select="tr:Parameters">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:variable name="dataValue">
							<xsl:apply-templates select="tr:Data">
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="isSessionAction" select="true()"/>
								<xsl:with-param name="parentNode" select="."/>
								<xsl:with-param name="numSpaces" select="1"/>
								<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
								<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
								<xsl:with-param name="includeLimits" select="$includeLimits"/>
								<xsl:with-param name="objectPath" select="'TestResult'"/>
							</xsl:apply-templates>
						</xsl:variable>
						<xsl:if test="$dataValue!=''">
							<tr>
								<td colspan="2" style="background-color:{$labelBgColor};">TestResults/Data:</td>
							</tr>
							<xsl:copy-of select="$dataValue"/>
						</xsl:if>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:ModuleTime">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:if test="$isFlowType='False' and tr:Data/c:Collection/c:Item[@name='ReportText']">
							<tr>
								<td colspan="2" style="background-color:{$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='ReportTextBg']};">
									<xsl:call-template name="ReplaceNewLineWithBreak">
										<xsl:with-param name="inputString" select="tr:Data/c:Collection/c:Item[@name='ReportText']/c:Datum/c:Value"/>
									</xsl:call-template>
								</td>
							</tr>
						</xsl:if>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:InteractiveExecutionId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:RemoteServerId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<!-- ADD_EXTRA_ROWS-->
						<!--tr>
								<td>StepID</td>
								<td><xsl:value-of select="@testReferenceID"/></td>
							</tr-->
					</table>
				</div>
			</div>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:TestGroup">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="isLoopIndexStep" select="false()"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="indentation">
			<xsl:call-template name="GetIndentationMargin">
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="isPostAction" select="contains(@ID,'_PostAction')"/>
		<xsl:variable name="loopIndex" select="tr:Extension/ts:TSStepProperties/ts:LoopingProperties/ts:LoopIndex"/>
		<xsl:if test="not($isPostAction) and (not($loopIndex) or $isLoopIndexStep)">
			<div class="expandCollapse" style="left:{$indentation}px;">
				<xsl:variable name="expandCollapseState">
					<xsl:call-template name="GetExpandCollapseState">
						<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
						<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:call-template name="GetStepResultImage">
					<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
					<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
					<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
				</xsl:call-template>
				<span class="stepName">
					<xsl:choose>
						<xsl:when test="@callerName">
							<xsl:value-of select="@callerName"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@name"/>
						</xsl:otherwise>
					</xsl:choose>
				</span>
				<div class="{$expandCollapseState}" style="left:40px;">
					<table class="stepTable" id="{concat('ResultId',@ID)}" style="border-color:{$reportOptions/c:Item[@name = 'Colors']/c:Collection/c:Item[@name = 'TableBorder']/c:Datum/c:Value};">
						<tr>
							<xsl:variable name="stepGroupBgColor">
								<xsl:call-template name="GetStepGroupBgColor">
									<xsl:with-param name="stepGroupName" select="tr:Extension/ts:TSStepProperties/ts:StepGroup"/>
									<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
								</xsl:call-template>
							</xsl:variable>
							<td colspan="2" style="background-color:{$stepGroupBgColor};">
									<a name="{concat('ResultId',@ID)}"/>
								<span class="stepText">
									<xsl:choose>
										<xsl:when test="@callerName">
											<xsl:value-of select="@callerName"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@name"/>
										</xsl:otherwise>
									</xsl:choose>
								</span>
							</td>
						</tr>
						<xsl:apply-templates select="tr:Outcome">
							<xsl:with-param name="colors" select="$reportOptions/c:Item[@name='Colors']/c:Collection"/>
						</xsl:apply-templates>
						<xsl:if test="tr:Outcome/@qualifier='Error'">
							<xsl:call-template name="ReportError">
								<xsl:with-param name="eventsNode" select="tr:Events"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:call-template>
						</xsl:if>					
						<xsl:apply-templates select="tr:TestResult[(@name='Numeric' or @name='String') and (count(tr:TestLimits)=1 or count(tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog)=1)]">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:call-template name="PutMeasurements">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:call-template> 
                        <!-- Process input parameters of a step-->
						<xsl:apply-templates select="tr:Parameters">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:if test="count(tr:TestResult[count(tr:TestLimits)=0 and count(tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog)=0 and @name!='ReportText']) > 0">
							<tr>
								<td colspan="2" style="background-color:{$labelBgColor};">TestResults/Data:</td>
							</tr>
						</xsl:if>
						<xsl:apply-templates select="tr:TestResult[count(tr:TestLimits)=0 and count(tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog)=0 and @name!='ReportText']">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="numSpaces" select="1"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:ModuleTime">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:TestResult[@name='ReportText']">
							<xsl:with-param name="bgColor" select="$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='ReportTextBg']"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:InteractiveExecutionId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="tr:Extension/ts:TSStepProperties/ts:RemoteServerId">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<!-- ADD_EXTRA_ROWS-->
						<!--tr>
								<td>StepID</td>
								<td><xsl:value-of select="@testReferenceID"/></td>
							</tr-->
					</table>
					<xsl:variable name="isNotEmpty" select="count(tr:Test|tr:SessionAction|tr:TestGroup[not(contains(@ID,'_PostAction'))])>0"/>
					<xsl:variable name="testGroupPostActionNode" select="tr:TestGroup[contains(@ID,'_PostAction')]"/>
					<xsl:if test="$isNotEmpty or $testGroupPostActionNode">
						<xsl:if test="$isNotEmpty">
							<div class="expandCollapse" style="left:{$gSequenceCallNegativeIndent}px">
								<h5>
									<xsl:call-template name="GetStepResultImage">
										<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
										<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
										<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
									</xsl:call-template>
					Begin Sequence:  <xsl:call-template name="GetTestGroupNameAndPath">
										<xsl:with-param name="testGroupNameAndPath" select="@name"/>
									</xsl:call-template>
								</h5>
								<div class="{$expandCollapseState}" style="left:{$gSequenceCallNegativeIndent}px">
									<xsl:apply-templates select="tr:Test|tr:SessionAction|tr:TestGroup">
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
										<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
										<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
										<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
										<xsl:with-param name="includeLimits" select="$includeLimits"/>
									</xsl:apply-templates>
								</div>
								<h5>
									<xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text>
End Sequence:  <xsl:call-template name="GetTestGroupNameAndPath">
										<xsl:with-param name="testGroupNameAndPath" select="@name"/>
										<xsl:with-param name="displayPath" select="false()"/>
									</xsl:call-template>
								</h5>
							</div>
						</xsl:if>
						<xsl:if test="$testGroupPostActionNode and ($testGroupPostActionNode/tr:Test|$testGroupPostActionNode/tr:SessionAction|$testGroupPostActionNode/tr:TestGroup)">
							<div class="expandCollapse" style="left:{$gSequenceCallNegativeIndent}px">
								<h5>
									<xsl:call-template name="GetStepResultImage">
										<xsl:with-param name="outcome" select="tr:Outcome/@value"/>
										<xsl:with-param name="qualifier" select="tr:Outcome/@qualifier"/>
										<xsl:with-param name="expandCollapseState" select="$expandCollapseState"/>
									</xsl:call-template>
					Begin Sequence:  <xsl:call-template name="GetTestGroupNameAndPath">
										<xsl:with-param name="testGroupNameAndPath" select="$testGroupPostActionNode/@name"/>
									</xsl:call-template>
								</h5>
								<div class="{$expandCollapseState}" style="left:{$gSequenceCallNegativeIndent}px">
									<xsl:apply-templates select="$testGroupPostActionNode/tr:Test|$testGroupPostActionNode/tr:SessionAction|$testGroupPostActionNode/tr:TestGroup">
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
										<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
										<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
										<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
										<xsl:with-param name="includeLimits" select="$includeLimits"/>
									</xsl:apply-templates>
								</div>
								<h5>
									<xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text>
End Sequence:  <xsl:call-template name="GetTestGroupNameAndPath">
										<xsl:with-param name="testGroupNameAndPath" select="$testGroupPostActionNode/@name"/>
										<xsl:with-param name="displayPath" select="false()"/>
									</xsl:call-template>
								</h5>
							</div>
						</xsl:if>
					</xsl:if>
				</div>
			</div>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:Outcome">
		<xsl:param name="colors"/>
		<tr>
			<td style="background-color:{$colors/c:Item[@name='LabelBg']/c:Datum/c:Value};">Status:</td>
			<xsl:variable name="statusBackgroundColor">
				<xsl:call-template name="GetStatusBgColor">
					<xsl:with-param name="colors" select="$colors"/>
					<xsl:with-param name="status" select="@value"/>
					<xsl:with-param name="qualifier" select="@qualifier"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="outcome">
				<xsl:choose>
					<xsl:when test="@qualifier">
						<xsl:value-of select="@qualifier"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<!--ADD_STATUS-->
			<!--xsl:variable name="cellBackgroundColor">
				<xsl:choose>
					<xsl:when test="$outcome = 'Passed'">#FFFF00</xsl:when>
					<xsl:otherwise><xsl:value-of select="$statusBackgroundColor"/></xsl:otherwise> 
				</xsl:choose>
			</xsl:variable-->
			<!--td style="background-color:{$cellBackgroundColor};width:{$gSecondColumnWidth};"-->
			<td style="background-color:{$statusBackgroundColor};width:{$gSecondColumnWidth};">
				<!--ADD_IMG-->
				<!--xsl:if test="$outcome = 'Failed'">
					<img src = "C:\Images\Failed.jpg"/>
				</xsl:if-->
				<xsl:value-of select="$outcome"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="tr:ActionOutcome">
		<xsl:param name="colors"/>
		<tr>
			<td style="background-color:{$colors/c:Item[@name='LabelBg']/c:Datum/c:Value};">Status:</td>
			<xsl:variable name="statusBackgroundColor">
				<xsl:call-template name="GetStatusBgColor">
					<xsl:with-param name="colors" select="$colors"/>
					<xsl:with-param name="status" select="@value"/>
					<xsl:with-param name="qualifier" select="@qualifier"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="outcome">
				<xsl:choose>
					<xsl:when test="@qualifier">
						<xsl:value-of select="@qualifier"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<!--ADD_STATUS-->
			<!--xsl:variable name="cellBackgroundColor">
				<xsl:choose>
					<xsl:when test="$outcome = 'Passed'">#FFFF00</xsl:when>
					<xsl:otherwise><xsl:value-of select="$statusBackgroundColor"/></xsl:otherwise> 
				</xsl:choose>
			</xsl:variable-->
			<!--td style="background-color:{$cellBackgroundColor};width:{$gSecondColumnWidth};"-->
			<td style="background-color:{$statusBackgroundColor};width:{$gSecondColumnWidth};">
				<!--ADD_IMG-->
				<!--xsl:if test="$outcome = 'Failed'">
					<img src = "C:\Images\Failed.jpg"/>
				</xsl:if-->
				<xsl:value-of select="$outcome"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="tr:Data">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="isSessionAction" select="false()"/>
		<xsl:param name="parentNode" select="''"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:choose>
			<xsl:when test="c:Collection">
				<xsl:choose>
					<xsl:when test="$isSessionAction">
						<xsl:apply-templates select="c:Collection/c:Item[@name!='ReportText' and (not(contains(@name,'.Attributes')))]">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="numSpaces" select="$numSpaces"/>
							<xsl:with-param name="parentNode" select="$parentNode"/>
							<xsl:with-param name="objectPath" select="$objectPath"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="dataValue">
							<xsl:apply-templates select="c:Collection">
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
								<xsl:with-param name="parentNode" select="$parentNode"/>
								<xsl:with-param name="objectPath" select="$objectPath"/>
								<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
								<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
								<xsl:with-param name="includeLimits" select="$includeLimits"/>
							</xsl:apply-templates>
						</xsl:variable>
						<xsl:variable name="shouldInclude">
							<xsl:choose>
								<xsl:when test="$dataValue != ''">
									<xsl:value-of select="true()"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:for-each select="c:Collection">
										<xsl:call-template name="GetIsIncludeInReport"/>
									</xsl:for-each>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:if test="string($shouldInclude) = string(true()) and $dataValue!=''">
							<xsl:if test="not(c:Collection/@xsi:type and c:Collection/@xsi:type ='ts:NI_TDMSReference')">
								<tr>
									<td colspan="2" style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue};">
										<xsl:value-of select="../@name"/>:</td>
								</tr>
							</xsl:if>
							<xsl:if test="$dataValue != ''">
								<xsl:copy-of select="$dataValue"/>
							</xsl:if>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="c:IndexedArray|c:Datum">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="shouldInclude">
					<xsl:choose>
						<xsl:when test="$dataValue != ''">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="c:IndexedArray">
									<xsl:for-each select="c:IndexedArray">
										<xsl:call-template name="GetIsIncludeInReport"/>
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="string($shouldInclude) = string(true()) and $dataValue!=''">
					<xsl:variable name="dataAttribute">
						<xsl:choose>
							<xsl:when test="$parentNode!=''">
								<xsl:call-template name="ProcessAttributes">
									<xsl:with-param name="node" select="$parentNode"/>
									<xsl:with-param name="objectPath" select="$objectPath"/>
									<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
									<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
									<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
									<xsl:with-param name="includeLimits" select="$includeLimits"/>
									<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
									<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="''"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<tr>
						<td style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue};">
							<xsl:value-of select="../@name"/>
							<xsl:if test="c:IndexedArray">
								<xsl:call-template name="GetArraySizeString">
									<xsl:with-param name="dimensionString" select="translate(substring-after(c:IndexedArray/@dimensions,'['),']',',')"/>
									<xsl:with-param name="firstElement" select="translate(substring-after(c:IndexedArray/@lowerBounds,'['),'][',',')"/>
									<xsl:with-param name="lastElement" select="translate(substring-after(c:IndexedArray/@upperBounds,'['),'][',',')"/>
								</xsl:call-template>
							</xsl:if>:
						</td>
						<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
							<xsl:choose>
								<xsl:when test="$dataValue != ''">
									<xsl:copy-of select="$dataValue"/>
								</xsl:when>
								<xsl:otherwise>
									<span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span>
								</xsl:otherwise>
							</xsl:choose>
						</td>
					</tr>
					<xsl:if test="$dataAttribute != ''">
						<xsl:copy-of select="$dataAttribute"/>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="tr:Parameters">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="dataValue">
			<xsl:apply-templates select="tr:Parameter">
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
				<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
				<xsl:with-param name="includeLimits" select="$includeLimits"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:if test="$dataValue!=''">
			<tr>
				<td colspan="2" style="background-color:{$labelBgColor};">Parameters</td>
			</tr>
			<xsl:copy-of select="$dataValue"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:Parameter">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:apply-templates select="tr:Data">
			<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
			<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
			<xsl:with-param name="parentNode" select="../.."/>
			<xsl:with-param name="objectPath" select="concat('Parameter.',@name)"/>
			<xsl:with-param name="numSpaces" select="1"/>
			<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
			<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
			<xsl:with-param name="includeLimits" select="$includeLimits"/>
		</xsl:apply-templates>
	</xsl:template>
	<xsl:template match="tr:TestResult">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="measurementIndex" select="-1"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:if test="count(tr:Outcome)=0 or not($skipMeasurement)">
			<xsl:choose>
				<xsl:when test="$skipMeasurement">
					<xsl:for-each select="tr:TestData|tr:TestLimits">
						<xsl:apply-templates select=".">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="parentNode" select="../.."/>
							<xsl:with-param name="objectPath">
								<xsl:choose>
									<xsl:when test="tr:Limits">
										<xsl:value-of select="../@name"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat('TestResult.',../@name)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
							<xsl:with-param name="numSpaces" select="$numSpaces"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
						</xsl:apply-templates>
					</xsl:for-each>
					<xsl:if test="tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog/@value='true'">
						<xsl:call-template name="LogNoComparison">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="numSpaces" select="$numSpaces"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<tr>
						<td colspan="2" style="background-color:{$labelBgColor}; padding-left:{$gSingleSpaceValue}px;">
							Measurement[<xsl:value-of select="$measurementIndex"/>] (<xsl:value-of select="@name"/>):</td>
					</tr>
					<xsl:apply-templates select="tr:TestLimits">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="2"/>
						<xsl:with-param name="parentNode" select=".."/>
						<xsl:with-param name="objectPath" select="@name"/>
						<xsl:with-param name="skipMeasurement" select="$skipMeasurement"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
					</xsl:apply-templates>
					<xsl:if test="tr:Extension/ts:TSLimitProperties/ts:IsComparisonTypeLog/@value = 'true'">
						<xsl:call-template name="LogNoComparison">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="numSpaces" select="2"/>
						</xsl:call-template>
					</xsl:if>
					<xsl:variable name="testData">
							<xsl:apply-templates select="tr:TestData/c:Datum">
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
								<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
								<xsl:with-param name="includeLimits" select="$includeLimits"/>
								<xsl:with-param name="addProperty" select="true()"/>
							</xsl:apply-templates>
					</xsl:variable>
					<xsl:if test="$testData != '' ">
						<tr>
							<td style="background-color:{$labelBgColor}; padding-left:{2 * $gSingleSpaceValue}px;">Data:</td>
							<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
								<xsl:copy-of select="$testData"/>
						</td>
					</tr>
					</xsl:if>
					<tr>
						<td style="background-color:{$labelBgColor}; padding-left:{2 * $gSingleSpaceValue}px;">Status:</td>
						<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
							<xsl:value-of select="tr:Outcome/@value"/>
						</td>
					</tr>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:TestData">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:choose>
			<xsl:when test="c:Collection">
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="c:Collection">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="shouldInclude">
					<xsl:choose>
						<xsl:when test="$dataValue != ''">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="c:Collection">
								<xsl:call-template name="GetIsIncludeInReport"/>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="string($shouldInclude) = string(true()) and $dataValue!=''">
					<xsl:if test="not(c:Collection/@xsi:type and c:Collection/@xsi:type ='ts:NI_TDMSReference')">
						<tr>
							<td colspan="2" style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue};">
								<xsl:value-of select="../@name"/>:</td>
						</tr>
					</xsl:if>
					<xsl:if test="$dataValue != ''">
						<xsl:copy-of select="$dataValue"/>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="c:IndexedArray|c:Datum">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="shouldInclude">
					<xsl:choose>
						<xsl:when test="$dataValue != ''">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="c:IndexedArray">
									<xsl:for-each select="c:IndexedArray">
										<xsl:call-template name="GetIsIncludeInReport"/>
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="string($shouldInclude) = string(true()) and $dataValue!=''">
					<xsl:variable name="dataAttribute">
						<xsl:choose>
							<xsl:when test="$parentNode!=''">
								<xsl:call-template name="ProcessAttributes">
									<xsl:with-param name="node" select="$parentNode"/>
									<xsl:with-param name="objectPath" select="$objectPath"/>
									<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
									<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
									<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
									<xsl:with-param name="includeLimits" select="$includeLimits"/>
									<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
									<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="''"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<tr>
						<td style="background-color:{$labelBgColor}; vertical-align:top;  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
							<xsl:value-of select="../@name"/>
							<xsl:if test="c:IndexedArray">
								<xsl:call-template name="GetArraySizeString">
									<xsl:with-param name="dimensionString" select="translate(substring-after(c:IndexedArray/@dimensions,'['),']',',')"/>
									<xsl:with-param name="firstElement" select="translate(substring-after(c:IndexedArray/@lowerBounds,'['),'][',',')"/>
									<xsl:with-param name="lastElement" select="translate(substring-after(c:IndexedArray/@upperBounds,'['),'][',',')"/>
								</xsl:call-template>
							</xsl:if>:</td>
						<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
							<xsl:choose>
								<xsl:when test="$dataValue != ''">
									<xsl:copy-of select="$dataValue"/>
								</xsl:when>
								<xsl:otherwise>
									<span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span>
								</xsl:otherwise>
							</xsl:choose>
						</td>
					</tr>
					<xsl:if test="$dataAttribute != ''">
						<xsl:copy-of select="$dataAttribute"/>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="tr:TestLimits">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:if test="$includeLimits">
			<xsl:apply-templates select="tr:Limits">
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="numSpaces" select="$numSpaces"/>
				<xsl:with-param name="parentNode" select="$parentNode"/>
				<xsl:with-param name="objectPath" select="$objectPath"/>
				<xsl:with-param name="skipMeasurement" select="$skipMeasurement"/>
				<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
				<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
				<xsl:with-param name="includeLimits" select="$includeLimits"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>
	<xsl:template match="tr:Limits">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="unit">
			<xsl:choose>
				<xsl:when test="c:Expected|c:SingleLimit|c:LimitPair">
					<xsl:call-template name="GetUnit">
						<xsl:with-param name="node" select="c:Expected/c:Datum|c:SingleLimit/c:Datum|c:LimitPair/c:Limit/c:Datum"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="GetUnit">
						<xsl:with-param name="node" select="../../tr:TestData/c:Datum"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$skipMeasurement or count(c:Expected|c:SingleLimit|c:LimitPair)=0">
			<xsl:if test="$unit!=''">
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">Units:</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$unit"/>
					</td>
				</tr>
			</xsl:if>
		</xsl:if>
			<xsl:if test="c:Expected|c:SingleLimit|c:LimitPair">
				<tr>
					<td colspan="2" style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">Limits:</td>
				</tr>
				<xsl:apply-templates select="c:Expected|c:SingleLimit|c:LimitPair">
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
					<xsl:with-param name="parentNode" select="$parentNode"/>
					<xsl:with-param name="objectPath" select="concat($objectPath,'.','Limits')"/>
					<xsl:with-param name="skipMeasurement" select="$skipMeasurement"/>
					<xsl:with-param name="unit" select="$unit"/>
					<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
					<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
					<xsl:with-param name="includeLimits" select="$includeLimits"/>
				</xsl:apply-templates>
			</xsl:if>
	</xsl:template>
	<xsl:template match="c:Expected">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="unit"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="labelName">
			<xsl:choose>
				<xsl:when test="../../../@name='String'">String</xsl:when>
				<xsl:otherwise>Low</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType">
				<xsl:variable name="thresholdTypeText">
					<xsl:choose>
						<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType='PERCENTAGE'">
							Percentage (% of Nominal Value)
						</xsl:when>
						<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType='PPM'">
							Parts Per Million (PPM of Nominal Value)
						</xsl:when>
						<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType='DELTA'">
							Delta Value (Variation from Nominal Value)
						</xsl:when>
						<xsl:otherwise>
							Unknown Type
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
						<xsl:text>Threshold Type:</xsl:text>
					</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$thresholdTypeText"/>
					</td>
				</tr>
				<xsl:variable name="nominalValue">
					<xsl:apply-templates select="c:Datum">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="parentNode" select="$parentNode"/>
							<xsl:with-param name="objectPath" select="concat($objectPath,'.',$labelName)"/>
							<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
							<xsl:with-param name="addProperty" select="true()"/>
						</xsl:apply-templates>
				</xsl:variable>
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
						<xsl:text>Nominal Value:</xsl:text>
					</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$nominalValue"/>
					</td>
				</tr>
				<xsl:variable name="thresholdTypeSymbol">
					<xsl:choose>
						<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType = 'PERCENTAGE'"> %</xsl:when>
						<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType = 'PPM'"> PPM</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="thresholdTypeNode" select="../c:Extension/ts:TSLimitProperties/ts:ThresholdType"/>
				<xsl:variable name="limitTypeNode" select="c:Datum/@xsi:type"/>
        <xsl:variable name="nominalNode" select="../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:Nominal/@value"/>
        <xsl:variable name="lowNode" select="../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:Low/@value"/>
        <xsl:variable name="highNode" select="../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:High/@value"/>
				<xsl:variable name="computedLow">
					<xsl:choose>
						<xsl:when test="c:Datum/@xsi:type = 'ts:TS_string' or c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'GE']/c:Datum/@xsi:type = 'ts:TS_string' or c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'LE']/c:Datum/@xsi:type = 'ts:TS_string'">
							<xsl:variable name="lowValue">
								<xsl:apply-templates select="c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'GE']/c:Datum">
									<xsl:with-param name="addProperty" select="true()"/>
								</xsl:apply-templates>
							</xsl:variable>
							(Nominal - <xsl:value-of select="$lowValue"/> <xsl:value-of select="$thresholdTypeSymbol"/>)
						</xsl:when>
            <xsl:when test="../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:Nominal/@value and ../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:Low/@value">
              <xsl:value-of select="user:GetLimitThresholdValue($thresholdTypeNode, $limitTypeNode, $nominalNode, $lowNode, true())"/>
            </xsl:when>
            <xsl:otherwise>
              IND
            </xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="computedHigh">
					<xsl:choose>
						<xsl:when test="c:Datum/@xsi:type = 'ts:TS_string' or c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'GE']/c:Datum/@xsi:type = 'ts:TS_string' or c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'LE']/c:Datum/@xsi:type = 'ts:TS_string'">
							<xsl:variable name="highValue">
								<xsl:apply-templates select="c:Datum/c:ErrorLimits/c:LimitPair/c:Limit[@comparator = 'LE']/c:Datum">
									<xsl:with-param name="addProperty" select="true()"/>
								</xsl:apply-templates>
							</xsl:variable>
							(Nominal + <xsl:value-of select="$highValue"/> <xsl:value-of select="$thresholdTypeSymbol"/>)
						</xsl:when>
            <xsl:when test="../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:Nominal/@value and ../c:Extension/ts:TSLimitProperties/ts:RawLimits/ts:High/@value">
              <xsl:value-of select="user:GetLimitThresholdValue($thresholdTypeNode, $limitTypeNode, $nominalNode, $highNode, false())"/>
            </xsl:when>
            <xsl:otherwise>
              IND
            </xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
						<xsl:text>Low:</xsl:text>
					</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$computedLow"/>
					</td>
				</tr>
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
						<xsl:text>High:</xsl:text>
					</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$computedHigh"/>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
						<xsl:value-of select="concat($labelName,':')"/>
					</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:apply-templates select="c:Datum">
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="parentNode" select="$parentNode"/>
							<xsl:with-param name="objectPath" select="concat($objectPath,'.',$labelName)"/>
							<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
							<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
							<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
							<xsl:with-param name="includeLimits" select="$includeLimits"/>
							<xsl:with-param name="addProperty" select="true()"/>
						</xsl:apply-templates>
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:variable name="dataAttribute">
			<xsl:choose>
				<xsl:when test="$parentNode!=''">
					<xsl:call-template name="ProcessAttributes">
						<xsl:with-param name="node" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="concat($objectPath,'.',$labelName)"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$dataAttribute != ''">
			<xsl:copy-of select="$dataAttribute"/>
		</xsl:if>
		<xsl:if test="not($skipMeasurement)">
			<xsl:if test="$unit!=''">
				<tr>
					<td style="background-color:{$labelBgColor};  padding-left:{($numSpaces - 1 ) * $gSingleSpaceValue}px;">Units:</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$unit"/>
					</td>
				</tr>
			</xsl:if>
		</xsl:if>
		<xsl:variable name="comparisonType">
			<xsl:choose>
				<xsl:when test="../../../@name='String'">
					<xsl:choose>
						<xsl:when test="@comparator='EQ'">CaseSensitive</xsl:when>
						<xsl:otherwise>IgnoreCase</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="GetComparisonTypeText">
					     <xsl:with-param name="compText" select="@comparator"/>
				    </xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td style="background-color:{$labelBgColor};  padding-left:{($numSpaces - 1 ) * $gSingleSpaceValue}px;">Comparison Type:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:value-of select="$comparisonType"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="c:SingleLimit">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="unit"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<tr>
			<td style="background-color:{$labelBgColor}; padding-left:{$numSpaces * $gSingleSpaceValue}px;">Low:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:apply-templates select="c:Datum">
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="parentNode" select="$parentNode"/>
					<xsl:with-param name="objectPath" select="concat($objectPath,'.','Low')"/>
					<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
					<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
					<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
					<xsl:with-param name="includeLimits" select="$includeLimits"/>
					<xsl:with-param name="addProperty" select="true()"/>
				</xsl:apply-templates>
			</td>
		</tr>
		<xsl:variable name="dataAttribute">
			<xsl:choose>
				<xsl:when test="$parentNode!=''">
					<xsl:call-template name="ProcessAttributes">
						<xsl:with-param name="node" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="concat($objectPath,'.','Low')"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$dataAttribute != ''">
			<xsl:copy-of select="$dataAttribute"/>
		</xsl:if>
		<xsl:if test="not($skipMeasurement)">
			<xsl:if test="$unit!=''">
				<tr>
					<td style="background-color:{$labelBgColor}; padding-left:{($numSpaces - 1) * $gSingleSpaceValue}px">Units:</td>
					<td style="background-color:{$valueBgColor}">
						<xsl:value-of select="$unit"/>
					</td>
				</tr>
			</xsl:if>
		</xsl:if>
		<tr>
			<td style="background-color:{$labelBgColor}; padding-left:{($numSpaces - 1) * $gSingleSpaceValue}px;">Comparison Type:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:call-template name="GetComparisonTypeText">
					<xsl:with-param name="compText" select="@comparator"/>
				</xsl:call-template>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="c:LimitPair">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="skipMeasurement" select="true()"/>
		<xsl:param name="unit"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:apply-templates select="c:Limit">
			<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
			<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
			<xsl:with-param name="numSpaces" select="$numSpaces"/>
			<xsl:with-param name="parentNode" select="$parentNode"/>
			<xsl:with-param name="objectPath" select="$objectPath"/>
			<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
			<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
			<xsl:with-param name="includeLimits" select="$includeLimits"/>
		</xsl:apply-templates>
		<xsl:if test="not($skipMeasurement)">
			<xsl:if test="$unit!=''">
				<tr>
					<td style="background-color:{$labelBgColor}; padding-left:{($numSpaces - 1) * $gSingleSpaceValue}px;">Units:</td>
					<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
						<xsl:value-of select="$unit"/>
					</td>
				</tr>
			</xsl:if>
		</xsl:if>
		<tr>
			<td style="background-color:{$labelBgColor}; padding-left:{($numSpaces - 1) * $gSingleSpaceValue}px;">Comparison Type:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:call-template name="GetComparisonTypeText">
					<xsl:with-param name="compText" select="concat(c:Limit[1]/@comparator, c:Limit[2]/@comparator)"/>
				</xsl:call-template>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="c:Limit">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:variable name="limitName">
			<xsl:choose>
				<xsl:when test="position()=1">Low</xsl:when>
				<xsl:otherwise>High</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<tr>
			<td style="background-color:{$labelBgColor}; padding-left:{$numSpaces * $gSingleSpaceValue}px;">
				<xsl:value-of select="concat($limitName,':')"/>
			</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
				<xsl:apply-templates select="c:Datum">
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="parentNode" select="$parentNode"/>
					<xsl:with-param name="objectPath" select="concat($objectPath,'.',$limitName)"/>
					<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
					<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
					<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
					<xsl:with-param name="includeLimits" select="$includeLimits"/>
					<xsl:with-param name="addProperty" select="true()"/>
				</xsl:apply-templates>
			</td>
		</tr>
		<xsl:variable name="dataAttribute">
			<xsl:choose>
				<xsl:when test="$parentNode!=''">
					<xsl:call-template name="ProcessAttributes">
						<xsl:with-param name="node" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="concat($objectPath,'.',$limitName)"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$dataAttribute != ''">
			<xsl:copy-of select="$dataAttribute"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="c:Datum">
		<xsl:param name="parentNode" select="''"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="numSpaces" select="1"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:variable name="dataValue">
			<xsl:call-template name="GetFlaggedDatumValue">
				<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
				<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
				<xsl:with-param name="includeLimits" select="$includeLimits"/>
				<xsl:with-param name="addProperty" select="$addProperty"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="@xsi:type='ts:NI_HyperlinkPath'">
				<xsl:variable name="hyperlinkValue">
					<xsl:choose>
						<xsl:when test="$parentNode!=''">
							<xsl:variable name="hyperLinkAttributeNodesName">
								<xsl:value-of select="concat($objectPath,'.Attributes')"/>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="$parentNode/tr:Data/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum">
									<xsl:value-of select="$parentNode/tr:Data/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum/@value"/>
								</xsl:when>
								<xsl:when test="$parentNode/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum">
									<xsl:value-of select="$parentNode/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum/@value"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="'false'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'false'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="isHyperLink" select="$hyperlinkValue='true' and ./c:Value != ''"/>
				<xsl:choose>
					<xsl:when test="$isHyperLink">
						<a href="{$dataValue}">
							<xsl:copy-of select="$dataValue"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$dataValue"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$dataValue"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="c:Collection">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="parentNode" select="''"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:param name="putAsFlatData" select="false()"/>
		<xsl:variable name="shouldAddProperty">
			<xsl:choose>
				<xsl:when test="@flags">
					<xsl:variable name="shouldIncludeInReport">
						<xsl:call-template name="GetIsIncludeInReport"/>
					</xsl:variable>
					<xsl:variable name="isLimit">
						<xsl:call-template name="GetIsLimit"/>
					</xsl:variable>
					<xsl:variable name="isMeasurement">
						<xsl:call-template name="GetIsMeasurement"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="($shouldIncludeInReport='true' or $addProperty) and ($isLimit='false' or ($isLimit='true' and $includeLimits)) and ($isMeasurement='false' or ($isMeasurement='true' and $includeMeasurements))">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$parentNode!='' and $objectPath!='TestResult' and $shouldAddProperty='true'">
			<xsl:call-template name="ProcessAttributes">
				<xsl:with-param name="node" select="$parentNode"/>
				<xsl:with-param name="objectPath" select="$objectPath"/>
				<xsl:with-param name="numSpaces" select="$numSpaces"/>
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
				<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
				<xsl:with-param name="includeLimits" select="$includeLimits"/>
				<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:apply-templates select="c:Item">
			<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
			<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
			<xsl:with-param name="numSpaces" select="$numSpaces"/>
			<xsl:with-param name="parentNode" select="$parentNode"/>
			<xsl:with-param name="objectPath" select="$objectPath"/>
			<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
			<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
			<xsl:with-param name="includeLimits" select="$includeLimits"/>
			<xsl:with-param name="addProperty" select="$shouldAddProperty='true'"/>
			<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
		</xsl:apply-templates>
		<xsl:if test="$shouldAddProperty='true' and count(c:Item)=0">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template match="c:Collection[@xsi:type='ts:NI_TDMSReference']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="parentNode" select="''"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:param name="putAsFlatData" select="false()"/>
		<xsl:variable name="shouldAddProperty">
			<xsl:choose>
				<xsl:when test="@flags">
					<xsl:variable name="shouldIncludeInReport">
						<xsl:call-template name="GetIsIncludeInReport"/>
					</xsl:variable>
					<xsl:variable name="isLimit">
						<xsl:call-template name="GetIsLimit"/>
					</xsl:variable>
					<xsl:variable name="isMeasurement">
						<xsl:call-template name="GetIsMeasurement"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="($shouldIncludeInReport='true' or $addProperty) and ($isLimit='false' or ($isLimit='true' and $includeLimits)) and ($isMeasurement='false' or ($isMeasurement='true' and $includeMeasurements))">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="filePath" select="c:Item[@name='File']/c:Datum/c:Value"/>
		<xsl:variable name="pluginValue" select="c:Item[@name='Plugin']/c:Datum/c:Value"/>
		<xsl:variable name="channelGroupValue" select="c:Item[@name='ChannelGroup']/c:Datum/c:Value"/>
		<xsl:variable name="channelValue" select="c:Item[@name='Channel']/c:Datum/c:Value"/>
		<xsl:variable name="hyperlinkValue">
			<xsl:choose>
				<xsl:when test="$parentNode!=''">
					<xsl:variable name="hyperLinkAttributeNodesName">
						<xsl:value-of select="concat($objectPath,'.File.Attributes')"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$parentNode/tr:Data/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum">
							<xsl:value-of select="$parentNode/tr:Data/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum/@value"/>
						</xsl:when>
						<xsl:when test="$parentNode/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum">
							<xsl:value-of select="$parentNode/c:Collection/c:Item[@name=$hyperLinkAttributeNodesName][1]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='Hyperlink']/c:Datum/@value"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'false'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'false'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="isHyperLink" select="$hyperlinkValue='true'"/>
		<xsl:choose>
			<xsl:when test="$pluginValue!='' or $channelGroupValue!='' or $channelValue!=''">
				<!-- Display As Container-->
				<xsl:if test="$putAsFlatData=false()">
					<tr>
						<td colspan="2" style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue -  $gSingleSpaceValue}px;">
							<xsl:choose>
								<xsl:when test="../@name">
									<xsl:value-of select="../@name"/>:</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="../../@name"/>:</xsl:otherwise>
							</xsl:choose>
						</td>
					</tr>
				</xsl:if>
				<xsl:if test="$parentNode!=''">
					<xsl:call-template name="ProcessAttributes">
						<xsl:with-param name="node" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:apply-templates select="c:Item[@name='File']">
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="numSpaces" select="$numSpaces"/>
					<xsl:with-param name="parentNode" select="$parentNode"/>
					<xsl:with-param name="objectPath" select="$objectPath"/>
					<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
					<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
					<xsl:with-param name="includeLimits" select="$includeLimits"/>
					<xsl:with-param name="addProperty" select="$shouldAddProperty='true'"/>
					<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
				</xsl:apply-templates>
				<xsl:if test="$pluginValue!=''">
					<xsl:apply-templates select="c:Item[@name='Plugin']">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="addProperty" select="$shouldAddProperty='true'"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="$channelGroupValue!=''">
					<xsl:apply-templates select="c:Item[@name='ChannelGroup']">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="addProperty" select="$shouldAddProperty='true'"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:if>
				<xsl:if test="$channelValue!=''">
					<xsl:apply-templates select="c:Item[@name='Channel']">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="addProperty" select="$shouldAddProperty='true'"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<!--Display only  string-->
				<!--Display only if addProperty is true or include in report flag is set for the Container or the File property-->
				<xsl:variable name="shouldAddFileProperty">
				<xsl:choose>
						<xsl:when test="@flags">
							<xsl:variable name="shouldIncludeCollectionInReport">
								<xsl:call-template name="GetIsIncludeInReport"/>
							</xsl:variable>
							<xsl:variable name="shouldIncludeFlagInReport">
								<xsl:for-each select="./c:Item[@name='File']/c:Datum">
									<xsl:call-template name="GetIsIncludeInReport"/>
								</xsl:for-each>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="$addProperty or $shouldIncludeCollectionInReport='true' or $shouldIncludeFlagInReport='true'">
									<xsl:value-of select="true()"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="$shouldAddFileProperty='true'">
				<xsl:choose>
					<xsl:when test="$putAsFlatData">
					    <xsl:variable name="newObjectPath" select="substring($objectPath,16)"/>
						<tr>
							<td style="font-weight:bold;">
								<xsl:choose>
									  <xsl:when test="$newObjectPath!=''">	   
										  <xsl:value-of select="$newObjectPath"/>
									  </xsl:when>
									  <xsl:otherwise> 
										  <xsl:value-of select="@name"/>
									  </xsl:otherwise>
									</xsl:choose>	
							</td>
							<td>
								<xsl:choose>
									<xsl:when test="$filePath!=''">	
										<xsl:choose>
											<xsl:when test="$isHyperLink">
												<a href="{$filePath}">
													<xsl:choose>
														<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
															<xsl:call-template name="ReplaceNewLineWithBreak">
																<xsl:with-param name="inputString" select="$filePath"/>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="$filePath"/>
														</xsl:otherwise>
													</xsl:choose>
												</a>
											</xsl:when>
											<xsl:otherwise>
												<xsl:choose>
													<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
														<xsl:call-template name="ReplaceNewLineWithBreak">
															<xsl:with-param name="inputString" select="$filePath"/>
														</xsl:call-template>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$filePath"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>''</xsl:otherwise>
								</xsl:choose>
							</td>
						</tr>
					</xsl:when>
					<xsl:otherwise>
						<tr>
							<td style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue -  $gSingleSpaceValue}px;">
								<xsl:choose>
									<xsl:when test="../@name">
										<xsl:value-of select="../@name"/>:</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="../../@name"/>:</xsl:otherwise>
								</xsl:choose>
							</td>
							<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
							<xsl:choose>
								<xsl:when test="$filePath!=''">
									<xsl:choose>
										<xsl:when test="$isHyperLink">
											<a href="{$filePath}">
												<xsl:choose>
													<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
														<xsl:call-template name="ReplaceNewLineWithBreak">
															<xsl:with-param name="inputString" select="$filePath"/>
														</xsl:call-template>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$filePath"/>
													</xsl:otherwise>
												</xsl:choose>
											</a>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
													<xsl:call-template name="ReplaceNewLineWithBreak">
														<xsl:with-param name="inputString" select="$filePath"/>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="$filePath"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>''</xsl:otherwise>
							</xsl:choose>
							</td>
						</tr>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$parentNode!=''">
					<xsl:call-template name="ProcessAttributes">
						<xsl:with-param name="node" select="$parentNode"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:call-template>
				</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="c:Item">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="numSpaces" select="0"/>
		<xsl:param name="parentNode" select="''"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:param name="putAsFlatData" select="false()"/>
		<xsl:choose>
			<xsl:when test="c:Collection">
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="c:Collection">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="objectPath">
							<xsl:choose>
								<xsl:when test="$objectPath=''">
									<xsl:value-of select="@name"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat($objectPath,'.',@name)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="addProperty" select="$addProperty"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="isDataValuePresent" select="$dataValue != ''"/>
				<xsl:if test="not(contains(@name,'.Attributes')) and not(c:Collection/@xsi:type and c:Collection/@xsi:type ='ts:NI_TDMSReference')">
					<xsl:variable name="shouldInclude">
						<xsl:choose>
							<xsl:when test="$dataValue != ''">
								<xsl:value-of select="true()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$addProperty">
										<xsl:value-of select="true()"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="c:Collection">
											<xsl:call-template name="GetIsIncludeInReport"/>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="(string($shouldInclude) = string(true())) and $putAsFlatData=false() and $isDataValuePresent">
						<tr>
							<td colspan="2" style="background-color:{$labelBgColor}; vertical-align:top; padding-left:{$numSpaces * $gSingleSpaceValue}px;">
								<xsl:value-of select="@name"/>:
						</td>
						</tr>
					</xsl:if>
				</xsl:if>
				<xsl:if test="$isDataValuePresent">
					<xsl:copy-of select="$dataValue"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="c:IndexedArray|c:Datum">
						<xsl:with-param name="parentNode" select="$parentNode"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="objectPath">
							<xsl:choose>
								<xsl:when test="$objectPath=''">
									<xsl:value-of select="@name"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat($objectPath,'.',@name)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="numSpaces" select="$numSpaces+1"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="addProperty" select="$addProperty"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:variable name="shouldInclude">
					<xsl:choose>
						<xsl:when test="$dataValue != ''">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="c:IndexedArray">
									<xsl:choose>
										<xsl:when test="$addProperty">
											<xsl:value-of select="true()"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="c:IndexedArray">
												<xsl:call-template name="GetIsIncludeInReport"/>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="false()"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="string($shouldInclude) = string(true()) and $dataValue!=''">
					<xsl:variable name="dataAttribute">
						<xsl:choose>
							<xsl:when test="$parentNode!=''">
								<xsl:call-template name="ProcessAttributes">
									<xsl:with-param name="node" select="$parentNode"/>
									<xsl:with-param name="objectPath">
										<xsl:choose>
											<xsl:when test="$objectPath=''">
												<xsl:value-of select="@name"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat($objectPath,'.',@name)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:with-param>
									<xsl:with-param name="numSpaces" select="$numSpaces + 1"/>
									<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
									<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
									<xsl:with-param name="includeLimits" select="$includeLimits"/>
									<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
									<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
									<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="''"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$putAsFlatData">
							<xsl:variable name="newObjectPath" select="substring($objectPath,16)"/>
							<tr>
								<td>	
									<xsl:choose>
									  <xsl:when test="$newObjectPath!=''">	   
										<xsl:value-of select="$newObjectPath"/>.<xsl:value-of select="@name"/>
									  </xsl:when>
									  <xsl:otherwise> 
										  <xsl:value-of select="@name"/>
									  </xsl:otherwise>
									</xsl:choose>									
									<xsl:if test="c:IndexedArray">
										<xsl:call-template name="GetArraySizeString">
											<xsl:with-param name="dimensionString" select="translate(substring-after(c:IndexedArray/@dimensions,'['),']',',')"/>
									<xsl:with-param name="firstElement" select="translate(substring-after(c:IndexedArray/@lowerBounds,'['),'][',',')"/>
									<xsl:with-param name="lastElement" select="translate(substring-after(c:IndexedArray/@upperBounds,'['),'][',',')"/>
										</xsl:call-template>
									</xsl:if>:</td>
								<td>
									<xsl:choose>
										<xsl:when test="$dataValue != ''">
											<xsl:copy-of select="$dataValue"/>
										</xsl:when>
										<xsl:otherwise>
											<span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span>
										</xsl:otherwise>
									</xsl:choose>
								</td>
							</tr>
						</xsl:when>
						<xsl:otherwise>
							<tr>
								<td style="background-color:{$labelBgColor}; vertical-align:top;  padding-left:{$numSpaces * $gSingleSpaceValue}px;">
									<xsl:value-of select="@name"/>
									<xsl:if test="c:IndexedArray">
										<xsl:call-template name="GetArraySizeString">
											<xsl:with-param name="dimensionString" select="translate(substring-after(c:IndexedArray/@dimensions,'['),']',',')"/>
									<xsl:with-param name="firstElement" select="translate(substring-after(c:IndexedArray/@lowerBounds,'['),'][',',')"/>
									<xsl:with-param name="lastElement" select="translate(substring-after(c:IndexedArray/@upperBounds,'['),'][',',')"/>
										</xsl:call-template>
									</xsl:if>:</td>
								<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
									<xsl:choose>
										<xsl:when test="$dataValue != ''">
											<xsl:copy-of select="$dataValue"/>
										</xsl:when>
										<xsl:otherwise>
											<span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span>
										</xsl:otherwise>
									</xsl:choose>
								</td>
							</tr>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="$dataAttribute != ''">
						<xsl:copy-of select="$dataAttribute"/>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="c:IndexedArray">
		<xsl:param name="parentNode"/>
		<xsl:param name="objectPath" select="''"/>
		<xsl:param name="numSpaces" select="1"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:choose>
			<xsl:when test="@flags">
				<xsl:variable name="shouldIncludeInReport">
					<xsl:call-template name="GetIsIncludeInReport"/>
				</xsl:variable>
				<xsl:if test="$shouldIncludeInReport = 'true' or $addProperty">
					<xsl:variable name="isLimit">
						<xsl:call-template name="GetIsLimit"/>
					</xsl:variable>
					<xsl:if test="$isLimit='false' or ($isLimit='true' and $includeLimits)">
						<xsl:variable name="isMeasurement">
							<xsl:call-template name="GetIsMeasurement"/>
						</xsl:variable>
						<xsl:if test="$isMeasurement='false' or ($isMeasurement='true' and $includeMeasurements)">
							<xsl:call-template name="GetArrayValue">
								<xsl:with-param name="objectPath" select="$objectPath"/>
								<xsl:with-param name="parentNode" select="$parentNode"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="GetArrayValue">
					<xsl:with-param name="objectPath" select="$objectPath"/>
					<xsl:with-param name="parentNode" select="$parentNode"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="tr:TestResult[@name='ReportText']">
		<xsl:param name="bgColor"/>
		<tr>
			<td colspan="2" style="background-color:{$bgColor}">
				<xsl:if test="tr:TestData/c:Datum/c:Value">
					<xsl:call-template name="ReplaceNewLineWithBreak">
						<xsl:with-param name="inputString" select="tr:TestData/c:Datum/c:Value"/>
					</xsl:call-template>
				</xsl:if>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="ts:InteractiveExecutionId">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td style="background-color:{$labelBgColor}">Interactive Execution #:</td>
			<td style="background-color:{$valueBgColor}">
				<xsl:value-of select="@value"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="ts:RemoteServerId">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td style="background-color:{$labelBgColor}">Server:</td>
			<td style="background-color:{$valueBgColor}">
				<xsl:value-of select="./text()"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template name="GetFlaggedDatumValue">
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="addProperty" select="false()"/>
		<xsl:choose>
			<xsl:when test="@flags">
				<xsl:variable name="shouldIncludeInReport">
					<xsl:call-template name="GetIsIncludeInReport"/>
				</xsl:variable>
				<xsl:if test="$shouldIncludeInReport = 'true' or $addProperty">
					<xsl:variable name="isLimit">
						<xsl:call-template name="GetIsLimit"/>
					</xsl:variable>
					<xsl:if test="$isLimit='false' or ($isLimit='true' and $includeLimits)">
						<xsl:variable name="isMeasurement">
							<xsl:call-template name="GetIsMeasurement"/>
						</xsl:variable>
						<xsl:if test="$isMeasurement='false' or ($isMeasurement='true' and $includeMeasurements)">
							<xsl:call-template name="GetDatumValue"/>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="GetDatumValue"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetDatumValue">
		<xsl:choose>
			<xsl:when test="@xsi:type = 'ts:TS_enum'">
				<xsl:if test="ts:IsValid/@value = 'true'">&quot;</xsl:if><xsl:choose>
					<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
						<xsl:call-template name="ReplaceNewLineWithBreak">
							<xsl:with-param name="inputString" select="ts:EnumValue"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="ts:EnumValue"/>
					</xsl:otherwise>
				</xsl:choose><xsl:if test="ts:IsValid/@value = 'true'">&quot; (<xsl:value-of select="ts:NumericValue/@value"/>)</xsl:if>				
			</xsl:when>
			<xsl:when test="@xsi:type = 'c:string' or @xsi:type = 'ts:TS_string'">
				<xsl:choose>
					<xsl:when test="c:Value = ''">''</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
								<xsl:call-template name="ReplaceNewLineWithBreak">
									<xsl:with-param name="inputString" select="c:Value"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="c:Value"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@xsi:type = 'ts:NI_HyperlinkPath'">
				<xsl:choose>
					<xsl:when test="c:Value = ''">''</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
								<xsl:call-template name="ReplaceNewLineWithBreak">
									<xsl:with-param name="inputString" select="c:Value"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="c:Value"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@xsi:type = 'c:binary' or @xsi:type = 'ts:TS_binary'">
				<!-- Here, '0b' is prepended to designate binary representation -->
				<xsl:value-of select="concat('0b',@value)"/>
			</xsl:when>
			<xsl:when test="@xsi:type = 'c:octal' or @xsi:type = 'ts:TS_octal'">
				<!-- Here, '0c' is prepended to designate octal representation -->
				<xsl:value-of select="concat('0c',@value)"/>
			</xsl:when>
			<xsl:when test="@xsi:type = 'c:boolean' or @xsi:type = 'ts:TS_boolean'">
				<xsl:choose>
					<xsl:when test="@value='true'">True</xsl:when>
					<xsl:otherwise>False</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@xsi:type = 'c:double' or @xsi:type = 'ts:TS_double'">
				<xsl:choose>
					<xsl:when test="@value='NaN'">NAN</xsl:when>
					<xsl:otherwise><xsl:value-of select="@value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<span style="white-space:nowrap;">
					<xsl:value-of select="@value"/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetArrayValue">
	<xsl:param name="parentNode"/>
	<xsl:param name="objectPath" select="''"/>
		<xsl:variable name="insertArrayType">
			<xsl:value-of select="user:GetIncludeArrayMeasurement()"/>
		</xsl:variable>
		<xsl:variable name="arrayFilter">
			<xsl:value-of select="user:GetArrayMeasurementFilter()"/>
		</xsl:variable>
		<xsl:variable name="maxDisplayElements">
			<xsl:value-of select="user:GetArrayMeasurementMax()"/>
		</xsl:variable>
		<xsl:variable name="numArrayElements" select="count(ts:Element)"/>
		<xsl:variable name="arrayElementList" select="ts:Element"/>
		<xsl:variable name="numDimensions" select="user:GetDimensions($arrayElementList)"/>
		<xsl:variable name="dimensions" select="string(@dimensions)"/>
		<xsl:choose>
			<!--Do not display arrays if the following 2 conditions are true :
					 1. "Do Not Include Arrays" is TRUE
					 2. "Exclude if large than Max" is TRUE-->
			<xsl:when test="$insertArrayType != 0 and ($arrayFilter != 2 or $numArrayElements &lt;= $maxDisplayElements)">
				<xsl:choose>	
					<xsl:when test="$numArrayElements = 0"><span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span></xsl:when>
					<xsl:when test="$insertArrayType=2 and @xsi:type='ts:TS_doubleArray' and $numDimensions &lt; 3 and $numArrayElements != 0">
						<xsl:variable name="graphCounter" select="user:GetGraphCounter()"/>
						<object classid='clsid:1CB7D7EF-7ED3-4D6F-A2AC-F54DCA641862' name='TsGraphControl3.GraphControl3' id='TSGRAPH{$graphCounter}' height='200' style='left: 0px; top: 0px' width='100%'> 
							<xsl:if test="$gGraphControlInstalled != 1">
								<xsl:call-template name="GetArrayValueAsTable">
									<xsl:with-param name="arrayFilter" select="$arrayFilter"/>
									<xsl:with-param name="maxDisplayElements">
										<xsl:choose>
											<xsl:when test="$arrayFilter &gt; 0 and $numArrayElements &gt; $maxDisplayElements"><xsl:value-of select="number($maxDisplayElements)"/></xsl:when>
											<xsl:otherwise><xsl:value-of select="number($numArrayElements)"/></xsl:otherwise>
										</xsl:choose>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:if>
						</object>
						<script defer='defer' type='text/javascript'>
							<xsl:choose>
								<xsl:when test="$numDimensions = 1">
									<xsl:value-of select="user:Get1DimensionGraphScript($arrayElementList, $graphCounter)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:variable name="dataLayout">
										<xsl:choose>
											<xsl:when test="$parentNode/tr:Data/c:Collection/c:Item[@name=concat($objectPath,'.Attributes')]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='DataLayout']/c:Datum/c:Value">
												<xsl:value-of select="$parentNode/tr:Data/c:Collection/c:Item[@name=concat($objectPath,'.Attributes')]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='DataLayout']/c:Datum/c:Value"/>
											</xsl:when>
											<xsl:otherwise>''</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="dataLayoutLowerCase" select="translate($dataLayout,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
									<xsl:variable name="dataOrientation">
										<xsl:choose>
											<xsl:when test="($dataLayoutLowerCase = 'multipley' or $dataLayoutLowerCase = 'singlex-multipley') and $parentNode/tr:Data/c:Collection/c:Item[@name=concat($objectPath,'.Attributes')]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='DataOrientation']/c:Datum/c:Value">
												<xsl:value-of select="$parentNode/tr:Data/c:Collection/c:Item[@name=concat($objectPath,'.Attributes')]/c:Collection/c:Item[@name='TestStand']/c:Collection/c:Item[@name='DataOrientation']/c:Datum/c:Value"/>
											</xsl:when>
											<xsl:otherwise>''</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:value-of select="user:Get2DimensionGraphScript($arrayElementList, $graphCounter, string($dataOrientation), string($dataLayout), $dimensions)"/>
								</xsl:otherwise>
							</xsl:choose>
						</script>								
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="GetArrayValueAsTable">
							<xsl:with-param name="arrayFilter" select="$arrayFilter"/>
							<xsl:with-param name="maxDisplayElements">
								<xsl:choose>
									<xsl:when test="$arrayFilter &gt; 0 and $numArrayElements &gt; $maxDisplayElements"><xsl:value-of select="number($maxDisplayElements)"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="number($numArrayElements)"/></xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetArrayValueAsTable">
		<xsl:param name="arrayFilter" select="0"/>
		<xsl:param name="maxDisplayElements" select="0"/>
		<xsl:variable name="numArrayElements" select="count(ts:Element)"/>
		<xsl:variable name="inc">
			<xsl:choose>
				<xsl:when test="$arrayFilter = 3 and $numArrayElements &gt; $maxDisplayElements">
					<xsl:value-of select="floor($numArrayElements div $maxDisplayElements)"/>
				</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="@xsi:type='c:booleanArray' or @xsi:type='ts:TS_booleanArray'">
				<xsl:for-each select="ts:Element">
					<xsl:if test="(position() - 1) mod $inc = 0 and floor((position()-1) div $inc) &lt; $maxDisplayElements">
						<xsl:call-template name="ReplaceSubString">
							<xsl:with-param name="inputString" select="@position"/>
							<xsl:with-param name="oldSubString" select="','"/>
							<xsl:with-param name="newSubString" select="']['"/>
						</xsl:call-template>
						<xsl:value-of select="concat($gSpace,$gSpace,'=',$gSpace,$gSpace)"/>
						<xsl:choose>
							<xsl:when test="@value='true'">
								<xsl:text disable-output-escaping="yes">&apos;True&apos;</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text disable-output-escaping="yes">&apos;False&apos;</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
						<br/>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="@xsi:type='c:stringArray' or @xsi:type='ts:TS_stringArray'">
				<xsl:for-each select="ts:Element">
					<xsl:if test="(position() - 1) mod $inc = 0 and floor((position()-1) div $inc) &lt; $maxDisplayElements">
						<xsl:call-template name="ReplaceSubString">
							<xsl:with-param name="inputString" select="@position"/>
							<xsl:with-param name="oldSubString" select="','"/>
							<xsl:with-param name="newSubString" select="']['"/>
						</xsl:call-template>
						<xsl:value-of select="concat($gSpace,$gSpace,'=',$gSpace,$gSpace)"/>
						<xsl:text disable-output-escaping="yes">&apos;</xsl:text>
						<xsl:if test="c:Value != ''">
							<xsl:choose>
								<xsl:when test="$gDisplayNewLineAndHTMLElementInStringProperty">
									<xsl:call-template name="ReplaceNewLineWithBreak">
										<xsl:with-param name="inputString" select="c:Value"/>
									</xsl:call-template>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="c:Value"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
						<xsl:text disable-output-escaping="yes">&apos;</xsl:text>
						<xsl:text disable-output-escaping="yes">&lt;br&gt;</xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="prefixToValue">
					<xsl:choose>
						<xsl:when test="@xsi:type='c:binaryArray' or @xsi:type='ts:TS_binaryArray'">0b</xsl:when>
						<xsl:when test="@xsi:type='c:octalArray' or @xsi:type='ts:TS_octalArray'">0c</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<span style="white-space:nowrap;">
					<xsl:for-each select="ts:Element">
						<xsl:if test="(position() - 1) mod $inc = 0 and floor((position()-1) div $inc) &lt; $maxDisplayElements">
							<xsl:call-template name="ReplaceSubString">
								<xsl:with-param name="inputString" select="@position"/>
								<xsl:with-param name="oldSubString" select="','"/>
								<xsl:with-param name="newSubString" select="']['"/>
							</xsl:call-template>
							<xsl:value-of select="concat($gSpace,$gSpace,'=',$gSpace,$gSpace)"/>
							<xsl:text disable-output-escaping="yes">&apos;</xsl:text>
							<xsl:value-of select="concat($prefixToValue,@value)"/>
							<xsl:text disable-output-escaping="yes">&apos;</xsl:text>
							<br/>
						</xsl:if>
					</xsl:for-each>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetIsIncludeInReport">
		<xsl:choose>
			<xsl:when test="@flags">
				<xsl:variable name="flags" select="@flags"/>
				<xsl:variable name="hexDigit" select="substring($flags,string-length($flags)-3,1)"/>
				<xsl:choose>
					<xsl:when test="$hexDigit='2' or $hexDigit='3' or $hexDigit='6' or $hexDigit='7' or $hexDigit='a' or $hexDigit='b' or $hexDigit='e' or $hexDigit='f'">
						<xsl:value-of select="true()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="false()"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetIsLimit">
			<xsl:choose>
				<xsl:when test="@flags">
					<xsl:variable name="flags" select="@flags"/>
					<xsl:variable name="hexDigit" select="substring($flags,string-length($flags)-3,1)"/>
					<xsl:choose>
						<xsl:when test="$hexDigit='1' or $hexDigit='3' or $hexDigit='5' or $hexDigit='7' or $hexDigit='9' or $hexDigit='b' or $hexDigit='d' or $hexDigit='f'">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetIsMeasurement">
		<xsl:choose>
				<xsl:when test="@flags">
					<xsl:variable name="flags" select="@flags"/>
					<xsl:variable name="hexDigit" select="substring($flags,string-length($flags)-2,1)"/>
					<xsl:choose>						
						<xsl:when test="$hexDigit='4' or $hexDigit='5' or $hexDigit='6' or $hexDigit='7' or $hexDigit='c' or $hexDigit='d' or $hexDigit='e' or $hexDigit='f'">
							<xsl:value-of select="true()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="false()"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="false()"/>
				</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ProcessAttributes">
		<xsl:param name="node"/>
		<xsl:param name="objectPath"/>
		<xsl:param name="numSpaces" select="1"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:param name="putAsFlatData" select="false()"/>
		<xsl:variable name="attributesNodeName">
			<xsl:value-of select="concat($objectPath,'.Attributes')"/>
		</xsl:variable>
		<xsl:if test="$includeAttributes">
			<xsl:if test="$node/tr:Data/c:Collection/c:Item[@name=$attributesNodeName]|$node/c:Collection/c:Item[@name=$attributesNodeName]">
				<xsl:variable name="dataValue">
					<xsl:apply-templates select="$node/tr:Data/c:Collection/c:Item[@name = $attributesNodeName][1]|$node/c:Collection/c:Item[@name=$attributesNodeName]">
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="numSpaces" select="$numSpaces"/>
						<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
						<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
						<xsl:with-param name="includeLimits" select="$includeLimits"/>
						<xsl:with-param name="parentNode" select="$node"/>
						<xsl:with-param name="putAsFlatData" select="$putAsFlatData"/>
					</xsl:apply-templates>
				</xsl:variable>
				<xsl:if test="$dataValue!=''">
					<xsl:if test="$putAsFlatData=false()">
						<tr>
							<td colspan="2" style="background-color:{$labelBgColor}; padding-left:{$numSpaces * $gSingleSpaceValue}px">Attributes:</td>
						</tr>
					</xsl:if>
					<xsl:copy-of select="$dataValue"/>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template name="GetUnit">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/@unit">
				<xsl:value-of select="$node/@unit"/>
			</xsl:when>
			<xsl:when test="$node/@nonStandardUnit">
				<xsl:value-of select="$node/@nonStandardUnit"/>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="PutMeasurements">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="includeAttributes"/>
		<xsl:param name="includeMeasurements"/>
		<xsl:param name="includeLimits"/>
		<xsl:if test="count(tr:TestResult/tr:Outcome)!=0">
			<tr>
				<td colspan="2" style="background-color:{$labelBgColor}">Measurements:</td>
			</tr>
			<xsl:for-each select="tr:TestResult/tr:Outcome">
				<xsl:apply-templates select="parent::node()">
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="skipMeasurement" select="false()"/>
					<xsl:with-param name="measurementIndex" select="position() - 1"/>
					<xsl:with-param name="includeAttributes" select="$includeAttributes"/>
					<xsl:with-param name="includeMeasurements" select="$includeMeasurements"/>
					<xsl:with-param name="includeLimits" select="$includeLimits"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template name="LogNoComparison">
	<xsl:param name="labelBgColor"/>
	<xsl:param name="valueBgColor"/>
	<xsl:param name="numSpaces" select="0"/>
		<xsl:variable name="unit">
			<xsl:call-template name="GetUnit">
				<xsl:with-param name="node" select="tr:TestData/c:Datum"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$unit!=''">
			<tr>
				<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">Units:</td>
				<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">
					<xsl:value-of select="$unit"/>
				</td>
			</tr>
		</xsl:if>
		<tr>
			<td style="background-color:{$labelBgColor};  padding-left:{$numSpaces * $gSingleSpaceValue}px;">Comparison Type:</td>
			<td style="background-color:{$valueBgColor};width:{$gSecondColumnWidth};">LOG</td>
		</tr>
	</xsl:template>
	<xsl:template name="GetTestGroupNameAndPath">
		<xsl:param name="testGroupNameAndPath"/>
		<xsl:param name="displayPath" select="true()"/>
		<xsl:choose>
			<!-- This check is performed to verify if the sequence name is empty or not. 
                  'testGroupNameAndPath' holds the sequence file name and the sequence name as : SequenceFileName#SequenceName -->
			<xsl:when test="contains($testGroupNameAndPath, '#')">
				<xsl:value-of select="substring-after($testGroupNameAndPath, '#')"/>
				<br/>
				<xsl:if test="$displayPath">
				(<xsl:value-of select="substring-before($testGroupNameAndPath, '#')"/>)
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<br/>
				(<xsl:value-of select="$testGroupNameAndPath"/>)
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ReportError">
		<xsl:param name="eventsNode"/>
		<xsl:param name="reportOptions"/>
		<tr>
			<td colspan="2" style="background-color:{$reportOptions/c:Item[@name='Colors']/c:Collection/c:Item[@name='ErrorBg']}">
				<xsl:if test="$eventsNode/tr:Event[@ID='Error Message']">Error Message: <xsl:variable name="errorMsg">
						<xsl:apply-templates select="$eventsNode/tr:Event[@ID='Error Message']/tr:Data/c:Datum">
							<xsl:with-param name="addProperty" select="true()"/>
						</xsl:apply-templates>
					</xsl:variable>
					<xsl:call-template name="ReplaceNewLineWithBreak">
						<xsl:with-param name="inputString" select="$errorMsg"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:if test="$eventsNode/tr:Event[@ID='Error Code']">[Error Code: <xsl:apply-templates select="$eventsNode/tr:Event[@ID='Error Code']/tr:Data/c:Datum"><xsl:with-param name="addProperty" select="true()"/></xsl:apply-templates>]</xsl:if>
			</td>
		</tr>
	</xsl:template>
	<xsl:template name="ReplaceSubString">
		<xsl:param name="inputString"/>
		<xsl:param name="oldSubString"/>
		<xsl:param name="newSubString"/>
		<xsl:variable name="head">
			<xsl:value-of select="substring-before($inputString,$oldSubString)"/>
		</xsl:variable>
		<xsl:variable name="tail">
			<xsl:value-of select="substring-after($inputString,$oldSubString)"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($tail)=0">
				<xsl:value-of select="$inputString"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="ReplaceSubString">
					<xsl:with-param name="inputString" select="concat($head,$newSubString,$tail)"/>
					<xsl:with-param name="oldSubString" select="$oldSubString"/>
					<xsl:with-param name="newSubString" select="$newSubString"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ReplaceNewLineWithBreak">
		<xsl:param name="inputString"/>
		<xsl:choose>
			<xsl:when test="contains($inputString,  '&#xA;')">
				<xsl:value-of select="substring-before($inputString,  '&#xA;')" disable-output-escaping="yes"/>
				<br/>
				<xsl:call-template name="ReplaceNewLineWithBreak">
					<xsl:with-param name="inputString" select="substring-after($inputString,  '&#xA;')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$inputString" disable-output-escaping="yes"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="Substring-before-last">
		<xsl:param name="string1" select="''"/>
		<xsl:param name="string2" select="''"/>
		<xsl:choose>
			<xsl:when test="$string1 != '' and $string2 != ''">
				<xsl:variable name="head" select="substring-before($string1, $string2)"/>
				<xsl:variable name="tail" select="substring-after($string1, $string2)"/>
				<xsl:value-of select="concat($head, $string2)"/>
				<xsl:if test="contains($tail, $string2)">
					<xsl:call-template name="Substring-before-last">
						<xsl:with-param name="string1" select="$tail"/>
						<xsl:with-param name="string2" select="$string2"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ReplaceBackwardSlashInPath">
		<xsl:param name="filepath"/>
		<xsl:choose>
			<xsl:when test="contains($filepath, '\')">
				<xsl:value-of select="translate($filepath, '\', '/')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$filepath"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetUUTTime">
		<xsl:param name="dateTime"/>
		<xsl:variable name="time" select="substring-after($dateTime, 'T')"/>
		<xsl:variable name="hours" select="substring-before($time, ':')"/>
		<xsl:variable name="minutes" select="substring-before(substring-after($time, ':'),':')"/>
		<xsl:variable name="seconds" select="substring-before(substring-after(substring-after($time, ':'),':'),'.')"/>
		<xsl:variable name="milliseconds" select="substring-after($time, '.')"/>
		<xsl:value-of select="user:GetLocalizedTime($hours, $minutes, $seconds, $milliseconds)"/>
	</xsl:template>
	<xsl:template name="GetStatusColor">
		<xsl:param name="colors"/>
		<xsl:param name="status"/>
		<xsl:param name="qualifier"/>
		<xsl:choose>
			<xsl:when test="$status = 'Passed'">
				<xsl:value-of select="$colors/c:Item[@name = 'Passed']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Done'">
				<xsl:value-of select="$colors/c:Item[@name = 'Done']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Failed'">
				<xsl:value-of select="$colors/c:Item[@name = 'Failed']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Aborted'">
				<xsl:choose>
					<xsl:when test="$qualifier = 'Error'">
						<xsl:value-of select="$colors/c:Item[@name = 'Error']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:when test="$qualifier = 'Terminated'">
						<xsl:value-of select="$colors/c:Item[@name = 'Terminated']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$colors/c:Item[@name = 'Done']/c:Datum/c:Value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$status = 'UserDefined'">
				<xsl:choose>
						<xsl:when test="$qualifier = 'Running'">
						<xsl:value-of select="$colors/c:Item[@name = 'Running']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:when test="$qualifier = 'Skipped'">
						<xsl:value-of select="$colors/c:Item[@name = 'Skipped']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$colors/c:Item[@name = 'Done']/c:Datum/c:Value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetStatusBgColor">
		<xsl:param name="colors"/>
		<xsl:param name="status"/>
		<xsl:param name="qualifier"/>
		<xsl:choose>
			<xsl:when test="$status = 'Passed'">
				<xsl:value-of select="$colors/c:Item[@name = 'PassedBg']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Done'">
				<xsl:value-of select="$colors/c:Item[@name = 'DoneBg']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Failed'">
				<xsl:value-of select="$colors/c:Item[@name = 'FailedBg']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$status = 'Aborted'">
				<xsl:choose>
					<xsl:when test="$qualifier = 'Error'">
						<xsl:value-of select="$colors/c:Item[@name = 'ErrorBg']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:when test="$qualifier = 'Terminated'">
						<xsl:value-of select="$colors/c:Item[@name = 'TerminatedBg']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$colors/c:Item[@name = 'DoneBg']/c:Datum/c:Value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$status = 'UserDefined'">
				<xsl:choose>
					<xsl:when test="$qualifier = 'Running'">
						<xsl:value-of select="$colors/c:Item[@name = 'RunningBg']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:when test="$qualifier = 'Skipped'">
						<xsl:value-of select="$colors/c:Item[@name = 'SkippedBg']/c:Datum/c:Value"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$colors/c:Item[@name = 'DoneBg']/c:Datum/c:Value"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetStepGroupBgColor">
		<xsl:param name="stepGroupName"/>
		<xsl:param name="colors"/>
		<xsl:variable name="stepGroup">
			<xsl:choose>
				<xsl:when test="$stepGroupName=''">
					Main
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$stepGroupName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$stepGroup = 'Main'">
				<xsl:value-of select="$colors/c:Item[@name = 'MainBg']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:when test="$stepGroup = 'Setup'">
				<xsl:value-of select="$colors/c:Item[@name = 'SetupBg']/c:Datum/c:Value"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$colors/c:Item[@name = 'CleanupBg']/c:Datum/c:Value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetStepResultImage">
		<xsl:param name="outcome"/>
		<xsl:param name="qualifier"/>
		<xsl:param name="expandCollapseState"/>
		<xsl:variable name="imageSrc">
			<xsl:choose>
				<xsl:when test="$outcome='Passed'">
					<xsl:value-of select="$gPlusPassedImage"/>
				</xsl:when>
				<xsl:when test="$outcome='Done'">
					<xsl:value-of select="$gPlusDoneImage"/>
				</xsl:when>
				<xsl:when test="$outcome='Failed'">
					<xsl:value-of select="$gMinusFailedImage"/>
				</xsl:when>
				<xsl:when test="$outcome='Aborted'">
					<xsl:choose>
						<xsl:when test="$qualifier='Terminated'">
							<xsl:value-of select="$gPlusTerminatedImage"/>
						</xsl:when>
						<xsl:when test="$qualifier='Error'">
							<xsl:value-of select="$gMinusErrorImage"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$gPlusDoneImage"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$outcome='UserDefined'">
					<xsl:choose>
						<xsl:when test="$qualifier='Skipped'">
							<xsl:value-of select="$gPlusSkippedImage"/>
						</xsl:when>
						<xsl:when test="$qualifier='Running'">
							<xsl:value-of select="$gPlusRunningImage"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$gPlusDoneImage"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="user:GetImageHTMLForImageName(string($imageSrc),'expandCollapse')" disable-output-escaping="yes"/>
	</xsl:template>
	<xsl:template name="GetExpandCollapseState">
		<xsl:param name="outcome"/>
		<xsl:param name="qualifier"/>
		<xsl:choose>
			<xsl:when test="$outcome='Failed'">
				<xsl:value-of select="'expanded'"/>
			</xsl:when>
			<xsl:when test="$outcome='Aborted'">
				<xsl:choose>
					<xsl:when test="$qualifier='Error'">
						<xsl:value-of select="'expanded'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'collapsed'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'collapsed'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetIndentationMargin">
		<xsl:variable name="blockLevel">
			<xsl:call-template name="GetBlockLevel"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$gRemoveIndentationFunctionality">
				<xsl:value-of select="20"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$blockLevel *40 + 20"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetUUTDate">
		<xsl:param name="date"/>
		<xsl:variable name="year" select="substring-before($date,'-')"/>
		<xsl:variable name="month" select="substring-before(substring-after($date,'-'),'-')"/>
		<xsl:variable name="day" select="substring-after(substring-after($date,'-'),'-')"/>
		<xsl:value-of select="user:GetLocalizedDate($year,$month,$day)"/>
	</xsl:template>
	<xsl:template name="CheckIfTypeFlow">
		<xsl:variable name="nodeName" select="@name"/>
		<xsl:choose>
			<xsl:when test="tr:Extension/ts:TSStepProperties/ts:StepType">
				<xsl:variable name="stepType"><xsl:value-of select="tr:Extension/ts:TSStepProperties/ts:StepType"/></xsl:variable>
				<xsl:choose>
					<xsl:when test="contains($stepType, 'NI_Flow_') and $stepType!='NI_Flow_Else'  and $stepType!='NI_Flow_Break' and $stepType!='NI_Flow_Continue'">True</xsl:when>
					<xsl:otherwise>False</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>False</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetArraySizeString">
		<xsl:param name="dimensionString"/>
		<xsl:param name="firstElement"/>
		<xsl:param name="lastElement"/>
		<xsl:variable name="arraySizeString">
			<xsl:choose>
				<xsl:when test="$dimensionString=''"/>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="substring-before($dimensionString,',')=0">
						[0..empty]
					</xsl:when>
						<xsl:otherwise>
						[<xsl:value-of select="substring-before($firstElement,',')"/>..<xsl:value-of select="substring-before($lastElement,',')"/>]
						<xsl:call-template name="GetArraySizeString">
								<xsl:with-param name="dimensionString" select="substring-after($dimensionString,',')"/>
								<xsl:with-param name="firstElement" select="substring-after($firstElement,',')"/>
								<xsl:with-param name="lastElement" select="substring-after($lastElement,',')"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$arraySizeString"/>
	</xsl:template>
	<xsl:template name="GetUutResultBgColor">
		<xsl:param name="status"/>
		<xsl:param name="colors"/>
		<xsl:choose>
			<xsl:when test="$status = 'Passed'"><xsl:value-of select="$colors/c:Item[@name='PassedBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:when test="$status = 'Done'"><xsl:value-of select="$colors/c:Item[@name = 'DoneBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:when test="$status = 'Failed'"><xsl:value-of select="$colors/c:Item[@name = 'FailedBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:when test="$status = 'Error'"><xsl:value-of select="$colors/c:Item[@name = 'ErrorBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:when test="$status = 'Terminated'"><xsl:value-of select="$colors/c:Item[@name = 'TerminatedBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:when test="$status = 'Running'"><xsl:value-of select="$colors/c:Item[@name = 'RunningBg']/c:Datum/c:Value"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$colors/c:Item[@name = 'SkippedBg']/c:Datum/c:Value"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="PutBatchUutLink">
		<xsl:if test="tr:Extension/ts:TSResultSetProperties/ts:TestSocketIndex">
			<a name="{concat(tr:Extension/ts:TSResultSetProperties/ts:TestSocketIndex/@value,'-',tr:ResultSet/@startDateTime)}"/>
		</xsl:if>
	</xsl:template>
	<xsl:template name="AddCriticalFailureStack">
		<xsl:param name="criticalFailureStackNode"/>
		<xsl:param name="colors"/>
		<br/>
		<table class="criticalFailureTable" style="border-color:{$colors/c:Item[@name='TableBorder']/c:Datum/c:Value}">
			<tr style="background-color:{$colors/c:Item[@name='FailureStackLabelBg']/c:Datum/c:Value};">
				<td>
					<b>Step</b>
				</td>
				<td>
					<b>Sequence</b>
				</td>
				<td>
					<b>Sequence File</b>
				</td>
			</tr>
			<xsl:for-each select="$criticalFailureStackNode/ts:CriticalFailureStackEntry">
				<xsl:sort select="@resultID" order="descending"/>
				<tr style="background-color:{$colors/c:Item[@name='FailureStackValueBg']/c:Datum/c:Value};">
					<td>
						<a href="#ResultId{@resultID}" onclick="expandTable(event)">
							<xsl:value-of select="@stepName"/>
						</a>
					</td>
					<td>
						<xsl:value-of select="@sequenceName"/>
					</td>
					<td>
						<xsl:choose>
							<xsl:when test="@sequenceFileName != ''">
								<xsl:value-of select="@sequenceFileName"/>
							</xsl:when>
							<xsl:otherwise>
								<span style="visibility:hidden;"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></span>
							</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
			</xsl:for-each>
		</table>
		<br/>
	</xsl:template>
	<xsl:template name="GetBlockLevel">
		<xsl:choose>
			<xsl:when test="tr:Extension/ts:TSStepProperties/ts:BlockLevel/@value">
				<xsl:value-of select="tr:Extension/ts:TSStepProperties/ts:BlockLevel/@value"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="blockLevel">
					<xsl:value-of select="substring-after(@userDefinedType, 'bl = ')"/>
				</xsl:variable>
				<xsl:value-of select="number(substring($blockLevel,2,string-length($blockLevel)-2))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="processing-instruction('xml-stylesheet')" name="GetStylesheetPath">
		<xsl:variable name="PI" select="./processing-instruction('xml-stylesheet')"/>
		<xsl:variable name="fullFilePath">
			<xsl:call-template name="ReplaceBackwardSlashInPath">
				<xsl:with-param name="filepath" select="substring-before(substring-after($PI, 'href=&quot;'), '&quot;')"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($fullFilePath,'/')">
				<xsl:call-template name="Substring-before-last">
					<xsl:with-param name="string1" select="$fullFilePath"/>
					<xsl:with-param name="string2" select="'/'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetNumberInDecimal">
		<xsl:param name="reportOptions"/>
		<xsl:param name="number"/>
		<xsl:variable name="radixAndSuffix">
			<xsl:call-template name="GetRadixAndSuffix">
				<xsl:with-param name="numericFormat" select="$reportOptions/c:Item[@name='NumericFormat']/c:Datum/c:Value/text()"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="radix">
			<xsl:value-of select="substring-before($radixAndSuffix,',')"/>
		</xsl:variable>
		<xsl:variable name="suffix">
			<xsl:value-of select="substring-after($radixAndSuffix,',')"/>
		</xsl:variable>
		<xsl:variable name="num">
			<xsl:choose>
				<xsl:when test="$suffix = ''">
					<xsl:value-of select="$number"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before($number,$suffix)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$radix=2">
				<xsl:call-template name="ConvertBinaryToDecimal">
					<xsl:with-param name="number" select="$num"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$radix=8">
				<xsl:call-template name="ConvertOctalToDecimal">
					<xsl:with-param name="number" select="$num"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$radix=16">
				<xsl:call-template name="ConvertHexadecimalToDecimal">
					<xsl:with-param name="number" select="$num"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$num"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetRadixAndSuffix">
		<xsl:param name="numericFormat"/>
		<xsl:variable name="firstChar">
			<xsl:value-of select="translate(substring($numericFormat,1,1),'GUIFDEXOB','guifdexob')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$firstChar='g' or $firstChar='u' or $firstChar='i' or $firstChar='f' or $firstChar='d' or $firstChar='e' or $firstChar='x' or $firstChar='o' or $firstChar='b'">
				<xsl:choose>
					<xsl:when test="$firstChar='x'">16</xsl:when>
					<xsl:when test="$firstChar='o'">8</xsl:when>
					<xsl:when test="$firstChar='b'">2</xsl:when>
					<xsl:otherwise>10</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="concat(',',substring($numericFormat,2))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="GetRadixAndSuffix">
					<xsl:with-param name="numericFormat" select="substring($numericFormat,2)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ConvertBinaryToDecimal">
		<xsl:param name="number"/>
		<xsl:param name="multiplier" select="1"/>
		<xsl:param name="sum" select="0"/>
		<xsl:choose>
			<xsl:when test="not($number = '')">
				<xsl:variable name="lastDigit">
					<xsl:value-of select="substring($number,string-length($number))"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="not($lastDigit = 'b') and not($lastDigit = ' ')">
						<xsl:call-template name="ConvertBinaryToDecimal">
							<xsl:with-param name="number" select="substring($number,1,string-length($number)-1)"/>
							<xsl:with-param name="multiplier" select="$multiplier * 2"/>
							<xsl:with-param name="sum" select="$sum + number($lastDigit) * $multiplier"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$sum"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ConvertOctalToDecimal">
		<xsl:param name="number"/>
		<xsl:param name="multiplier" select="1"/>
		<xsl:param name="sum" select="0"/>
		<xsl:choose>
			<xsl:when test="not($number = '')">
				<xsl:variable name="lastDigit">
					<xsl:value-of select="substring($number,string-length($number))"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="not($lastDigit = ' ')">
						<xsl:call-template name="ConvertOctalToDecimal">
							<xsl:with-param name="number" select="substring($number,1,string-length($number)-1)"/>
							<xsl:with-param name="multiplier" select="$multiplier * 8"/>
							<xsl:with-param name="sum" select="$sum + number($lastDigit) * $multiplier"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$sum"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="ConvertHexadecimalToDecimal">
		<xsl:param name="number"/>
		<xsl:param name="multiplier" select="1"/>
		<xsl:param name="sum" select="0"/>
		<xsl:choose>
			<xsl:when test="not($number = '')">
				<xsl:variable name="lastDigit">
					<xsl:value-of select="substring($number,string-length($number))"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="not($lastDigit = 'x') and not($lastDigit = ' ')">
						<xsl:variable name="digit">
							<xsl:choose>
								<xsl:when test="$lastDigit = 'a'">10</xsl:when>
								<xsl:when test="$lastDigit = 'b'">11</xsl:when>
								<xsl:when test="$lastDigit = 'c'">12</xsl:when>
								<xsl:when test="$lastDigit = 'd'">13</xsl:when>
								<xsl:when test="$lastDigit = 'e'">14</xsl:when>
								<xsl:when test="$lastDigit = 'f'">15</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$lastDigit"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:call-template name="ConvertHexadecimalToDecimal">
							<xsl:with-param name="number" select="substring($number,1,string-length($number)-1)"/>
							<xsl:with-param name="multiplier" select="$multiplier * 16"/>
							<xsl:with-param name="sum" select="$sum + number($digit) * $multiplier"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$sum"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="GetComparisonTypeText">
		<xsl:param name="compText"/>
		<xsl:choose>
			<xsl:when test="../c:Extension/ts:TSLimitProperties/ts:ThresholdType">
				<xsl:text>EQT(== +/-)</xsl:text>
			</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$compText"/>
        <xsl:choose>
          <xsl:when test="$compText='EQ'">
            <xsl:text>(==)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='NE'">
            <xsl:text>(!=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GT'">
            <xsl:text disable-output-escaping="yes">(&gt;)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GE'">
            <xsl:text disable-output-escaping="yes">(&gt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LT'">
            <xsl:text disable-output-escaping="yes">(&lt;)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LE'">
            <xsl:text disable-output-escaping="yes">(&lt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GTLT'">
            <xsl:text disable-output-escaping="yes">(&gt; &lt;)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GELT'">
            <xsl:text disable-output-escaping="yes">(&gt;= &lt;)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GELE'">
            <xsl:text disable-output-escaping="yes">(&gt;= &lt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='GTLE'">
            <xsl:text disable-output-escaping="yes">(&gt; &lt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LTGT'">
            <xsl:text disable-output-escaping="yes">(&lt; &gt;)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LTGE'">
            <xsl:text disable-output-escaping="yes">(&lt; &gt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LEGE'">
            <xsl:text disable-output-escaping="yes">(&lt;= &gt;=)</xsl:text>
          </xsl:when>
          <xsl:when test="$compText='LEGT'">
            <xsl:text disable-output-escaping="yes">(&lt;= &gt;)</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
