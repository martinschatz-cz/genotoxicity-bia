run("Enhance Contrast", "saturated=0.35");
waitForUser("Adjust Contrast");
getMinAndMax(min, max);
imgs = getList("image.titles");
for (i = 0; i < imgs.length; i++) {
	print(imgs[i]);
	selectImage(imgs[i]);
   	setMinAndMax(min, max);
   	//run("Green");
   	run("gem");
   	saveAs("PNG", "H:/Bia/FPBT/Jablonska/mykotoxiny/time_comp/export/vis_"+ replace(imgs[i], ".tif", ".png"));
}

