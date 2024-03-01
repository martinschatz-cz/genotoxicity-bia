/*
 * Macro template to sort multiple images in a folder based on its name properties.
 */

print("\\Clear");
run("Close All");
run("Clear Results");


ver = "1.1"
print("Version: " + ver + ", last edit 01.03.2024");

print("ImageJ version: " + IJ.getFullVersion);
run("Bio-Formats Macro Extensions");
Ext.getVersionNumber(version)
print("Bio-formats version: " + version);

if (IJ.getFullVersion!="1.53t99") {
	print("!!Alert!!");
	print("Tested ImageJ version: 1.53t99, current:" + IJ.getFullVersion);
}

print("------------------");


#@ File (label = "Input directory", style = "directory") input
//#@ String (label = "Well names (div=',')", value = "B2,C2,D2,B3,C3,D3,B4,C4,D4,B6,C6,D6,B8,C8,D8,B7,C7,D7") we
#@ String (label = "Well names (div=',')", value = "B2,C2,D2,B3,C3,D3,B4,C4,D4,B6,C6,D6,B8,C8,D8,B7,C7,D7") we
#@ String (label = "File suffix", value = ".tif") suffix

wells = split(we,",");

setBatchMode(true);
processFolder(input,wells);
setBatchMode(false);
// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input,wells) {
	list = getFileList(input);
	list = Array.sort(list);
	start = true;
	progbar="[Progress]";
	run("Text Window...", "name="+ progbar +" width=25 height=2 monospaced");
	for (i = 0; i < list.length; i++) {
		print(progbar, "\\Update:"+i+"/"+list.length+" ("+(i*100)/list.length+"%)\n"+getBar(i, list.length));
		if(endsWith(list[i], suffix)){
			if (start) {
				open(input + File.separator + list[i]);
				getDimensions(width, height, channels, slices, frames);
				close();
				if (channels>1) {
					print("!!WARNING!! This is multichannel image.");
				}
				start = false;
			}
		
			processFile(input, wells, list[i]);
		}
	}
}

function processFile(input, wells, file) {
	// Do the thing
	
	print("Processing: " + input + File.separator + file);
	n=lengthOf(wells);
	// go through image names
	for (i = 0; i < n; i++) {
		// if well name is in file name
		if (indexOf(file,wells[i])>0) {
			// save to subfolder
			open(input + File.separator + file);
			print(input + File.separator + file);
			title=getTitle();
			resDir=input+File.separator+ wells[i];
			if (!File.isDirectory(resDir)) File.makeDirectory(resDir); //create folder if not exist
			saveAs("tiff",resDir+File.separator+title);
			print(resDir+File.separator+title);
			print("-----");
			close(title);
		}
	}	
	
}

function getBar(p1, p2) {
        n = 20;
        bar1 = "--------------------";
        bar2 = "********************";
        index = round(n*(p1/p2));
        if (index<1) index = 1;
        if (index>n-1) index = n-1;
        return substring(bar2, 0, index) + substring(bar1, index+1, n);
  }