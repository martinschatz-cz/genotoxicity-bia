// Process_Folder.ijm
//	V 0.5
//  update: 09.02.2023
//	by: Martin Schätz

// Log, jpeg, results saved in input folder
// name of channel at the beginning of file name (DAPI_****.tif or Cy3_****.tif)
// create results as subfolder for input folder
// replace split with rename for getting rid of DAPI in file name
// 10 size limit added
// Cy3 byckground substraction 

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

image_5 --> background substract --> image_6

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


ver = "0.5"
print("Version: " + ver + ", last edit 09.02.2023");

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
//#@ String (label = "Well names (div=',')", value = "B2,C2,D2,B3,C3,D3,B4,C4,D4,B6,C6,D6,B8,C8,D8,B7,C7,D7") we
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
	//#@ String (label = folders[n-1], value = ".tif") w_name
	
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
	
	
	num_results = nResults();
	run("Summarize");
		
	//Remove everything on top of the summary
	Table.deleteRows(0, num_results-1);
	saveAs("Results", input + File.separator + "Results" + File.separator + w_name + "_SumOfResults_"+year+"-"+month+1+"-"+dayOfMonth+"_Results.csv");
	
		
	
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
	start=true; // get otsu th values for this folder
	for (i = 0; i < list.length; i++) {
//		if(File.isDirectory(input + File.separator + list[i]))
//			processFolder(input + File.separator + list[i]);
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

				if (start) {
					// get otsu threshold
					if (IJ.getFullVersion=="1.53t99") {
						setAutoThreshold("Otsu dark");
						getThreshold(lower, upper);
						print("Otsu lower th: " + lower);
						print("Otsu upper th: " + upper);
					}
						else {
								if (IJ.getFullVersion=="1.52v99") {
										setAutoThreshold("Otsu");
										getThreshold(lower, upper);
										print("Otsu lower th: " + lower);
										print("Otsu upper th: " + upper);
			
									} else {
										print("!!!Alert!!! Tested version is 1.53t99");
										setAutoThreshold("Otsu dark");
										getThreshold(lower, upper);
										print("Otsu lower th: " + lower);
										print("Otsu upper th: " + upper);
									}
						}

					// set measurements
					run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack display redirect=None decimal=5");
					start=false;
				}
					
				
				close(title);
				processFile(input, list[i], suffix, lower, upper);
			}
	}
}

function processFile(input, file, suffix, lower, upper) {
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

	// Otsu based threshold for all tiles
	// based on setAutoThreshold("Otsu"); applied for whole well
	
	
	
	setThreshold(lower, upper);
	if (IJ.getFullVersion=="1.53t99") {
		setOption("BlackBackground", true);
		run("Convert to Mask");
					if (IJ.getFullVersion=="1.52v99") {
							run("Convert to Mask");
							run("Invert LUT");;

						} else {
							setOption("BlackBackground", true);
							run("Convert to Mask");
						}}
	/////Cy3 image 512x512////
		run("Scale...", "x=0.25 y=0.25 width=512 height=512 interpolation=None average create");
		setOption("BlackBackground", false);
		//run("Threshold...");
		//setThreshold(122, 255);
		run("Convert to Mask");
	/////Cy3 image 512x512////
	run("Analyze Particles...", "size=0.001-10.00 exclude add");

	
	name=replace(file, "DAPI", ""); //old //name = split(file,"DAPI");

	Cy3title="Cy3"+name;

///// Cy3 image /////

	// open Cy3 image
	if (File.exists(input + File.separator + Cy3title)) {
		open(input + File.separator + Cy3title);
		run("Duplicate...", " ");
		print(Cy3title);
		getDimensions(cwidth, cheight, channels, slices, frames);
		
		// substract background
		run("Subtract Background...", "rolling=12 sliding"); //special
	
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
	} else {
		print("File: "+input + File.separator + Cy3title + " does not exists. Skiping it.");
		continue;
	}
}
