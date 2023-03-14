// Process_WFolder_macro_v1.ijm
//	V 1.0
//  update: 10.03.2023
//	by: Martin Schätz

/*
# IJ Macro Protocol
*/
/*
This protocol documents an image data flow inspired by CLIJx-Assistant.

We start our image data flow with image_1, a DAPI channel with nuclei.

Following, we applied "Copy" on image_1 and got a new image out, image_2.

As the next step, we applied "Otsu" auto threshold on image_2 and got a new image mask out, image_3. The threshold values are saved and used on all DAPI images from the same well.

Afterward, we applied "Analyze Particles" on image_3, and got out a region fo nuclei as a Region of Interest (ROI) set. All ROIs touching edges are skipped.

In the next step, we open image_4, which is the Cy3 channel. We applied "Copy" on image_4, and got a new image out, image_5.

We applied background subtraction with rolling ball of size 50 on image_5 to subtract local background value from intensity measurements, and got image_6 out. 

Afterward, image_6 is selected for measuring features under ROIs from the previous step.

The process Log and measured features from Cy3 channel for the whole well and summary are saved in "Results" subfolder in CSV table. A flattened image_4 with ROIs outlines is saved as JPEG for later inspection.

Used images
 * image_1: DAPI_exp_20221214_B2-1_01.tif
 * image_2: Copy of DAPI_exp_20221214_B2-1_01.tif
 * image_3: Thresholded Image of DAPI_exp_20221214_B2-1_01.tif
 * image_4: Cy3_exp_20221214_B2-1_01.tif
 * image_5: Copy of Cy3_exp_20221214_B2-1_01.tif
 * image_6: Copy of Cy3_exp_20221214_B2-1_01.tif with background substraction
 */

print("\\Clear");
run("Close All");
run("Clear Results");


ver = "1.0-StarDist"
print("Version: " + ver + ", last edit 10.03.2023");

print("ImageJ version: " + IJ.getFullVersion);
run("Bio-Formats Macro Extensions");
Ext.getVersionNumber(version)
print("Bio-formats version: " + version);

if (IJ.getFullVersion!="1.53t99") {
	print("!!Alert!!");
	print("Tested ImageJ version: 1.53t99, current:" + IJ.getFullVersion);
}

print("------------------");

/*
 ## Input info
 */

#@ File (label = "Input directory", style = "directory") inputD
#@ String (label = "Well names (div=',')", value = "B2,C2,D2,B3,C3,D3,B4,C4,D4,B6,C6,D6,B8,C8,D8,B7,C7,D7") we
#@ String (label = "File suffix", value = ".tif") suffix
wells = split(we,",");
// clean log
print("\\Clear");

for (i = 0; i < lengthOf(wells); i++) {
	print("ImageJ version: " + IJ.getFullVersion);
	run("Bio-Formats Macro Extensions");
	Ext.getVersionNumber(version)
	print("Bio-formats version: " + version);
	
	if (IJ.getFullVersion!="1.53t99") {
		print("!!Alert!!");
		print("Tested ImageJ version: 1.53t99, current:" + IJ.getFullVersion);
	}
	
	print("------------------");
	
	input=inputD + File.separator()+wells[i];

	folders = split(input,File.separator());
	n=lengthOf(folders);
	w_name=folders[n-1];
	
	resDir=input+File.separator+"Results";
	if (!File.isDirectory(resDir)) File.makeDirectory(resDir); //create folder if not exist
	
	print("Input directory: " + input);
	print("File suffix: " + suffix);
	
	// add folders to result and flatten image
	
	/*
	 ## Process files
	 */
	setBatchMode(true);
	processFolder(input, suffix);
	setBatchMode(false);
	
	selectWindow("Log");
	saveAs("Text", resDir + File.separator + w_name + "_Log"+".txt");
	
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	saveAs("Results", input + File.separator + "Results" + File.separator + w_name + "_AllResults_"+year+"-"+month+1+"-"+dayOfMonth+"_Results.csv");
		
	//close all
	close("*");
	// clear all
	if (roiManager("count")>0) {
		roiManager("Delete");
	}
	num_results = nResults();
		
	//Remove everything on top of the summary
	Table.deleteRows(0, num_results-1);
	//clear Log
	print("\\Clear");
}
// function to scan folders/files to find files with correct suffix
function processFolder(input, suffix) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			if (indexOf(list[i], "DAPI") >= 0) {
				///// check image /////
				// open DAPI image
				print("_________________");
				print("Processing: " + input + File.separator + list[i]);
				open(input + File.separator + list[i]);
				run("Duplicate...", " ");
				title=getTitle();
				getDimensions(dwidth, dheight, channels, slices, frames);
				print("DAPI Size: " + dwidth + "x"+dheight);
					// set measurements
					run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=5");
				close(title);
				processFile(input, list[i], suffix);
			}
	}
}

function processFile(input, file, suffix) {
	// Clean up
	run("Close All");
	if (roiManager("count")>0) {
		roiManager("Delete");
	}


///// DAPI image /////

	open(input + File.separator + list[i]);
	run("Duplicate...", " ");
	title=getTitle();
	selectWindow(title);
	print(title);

	// StarDist 
	if (IJ.getFullVersion=="1.53t99") {
		//run StarDist 
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=["+title+", 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'20', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'true', 'showProbAndDist':'false'], process=[false]");
		}

	
	name=replace(file, "DAPI", ""); //old //name = split(file,"DAPI");

	Cy3title="Cy3"+name;

///// Cy3 image /////

	// open Cy3 image
	open(input + File.separator + Cy3title);
	run("Duplicate...", " ");
	print(Cy3title);
	getDimensions(cwidth, cheight, channels, slices, frames);
	
	// substract background
	run("Subtract Background...", "rolling=50 sliding");

	// check size of image
	print("Cy3 Size: " + cwidth + "x"+cheight);	
	if (cwidth!=dwidth || cheight!=dheight) {
		print("!!! Chanels have different pixel count !!!");
	}

	//measure
	roiManager("Show All without labels");
	roiManager("Measure");
	Cy3title=replace(Cy3title, suffix, "");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	//// possible sumarization
	//saveAs("Results", input + File.separator + "Results" + File.separator + Cy3title+"_"+year+"-"+month+1+"-"+dayOfMonth+"_Results.csv");

	//num_results = nResults();
	//run("Summarize");
	
	// Remove everything on top of the summary
	//Table.deleteRows(0, num_results-1);

///// Flatten Cy3 image with objects /////

	run("Flatten");
	saveAs("Jpeg", input + File.separator + "Results" +  File.separator + Cy3title+"_"+year+"-"+month+1+"-"+dayOfMonth+"-flatten.jpg");
	
	print("Found objects: " + roiManager("count"));
	
	// save ROIs
	if (roiManager("count")>0) {
		roiManager("Save", input + File.separator + "Results" +  File.separator + Cy3title+"_"+year+"-"+month+1+"-"+dayOfMonth+"-RoiSet.zip");
	}
}
