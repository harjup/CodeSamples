--Automated Imagery and Rendering Script
--Goes into an input directory specified by the user, loads in all the .FBX files present in the folder along with an excel doc with the same name,
--and produces renders at all the camera angles specified in the Excel Doc at specified sizes, in an output directory specified by the user. Also produces a lineart version of each render.
--Dependancy : _excelCRUD.ms
--Needs to be run from within the "renderSetup.max" scene.
--Written by Paul Harju, 2013.

fileIn (getFilenamePath (getSourceFileName()) +  "_excelCRUD.ms")

global fileInputPath = ""
global fileOutputPath = ""


	
	--Size Folders and imageSizes are two arrays to be used in parallel.
	--SizeFolders determines what the folder where all the renders of a particular size should be stored
	--imgSizes is the numberical value of what that size should be. At the moment, only square resolutions are supported.
	global SizeFolders = #("88x88\\", "126x126\\", "240x240\\")
	global imgSizes = #(88, 126, 240)

macroScript renderScript category:"_Custom Bits"
(
	
	--Create a rollout that has...
	--An input directory for geometry files
	--An output directory for image files
	--A confirmation button
	
	
	--The path for the file that stores the last specified directories for the input and output paths
	--The path file exists in the same directory as this script
	ioFile = (getFilenamePath (getSourceFileName()) +  "renderSettings.xml")
	
	--If the file does not exist, then create a fresh renderSettings file with default values
	if (doesFileExist ioFile == false) then
	(
		WriteRenderSettings "Please choose an input path" "Please choose an output path"
	)

	--Open up the now-definately-exists renderSettings file and read in all the relevant data
	xReader = dotNetClass "System.Xml.XmlReader"
	r = xReader.Create((getFilenamePath (getSourceFileName()) +  "renderSettings.xml"))
	
	while r.Read() do
	(
		if r.IsStartElement() then
		(
			case r.Name of 
			(
				"InputPath":
				(
					r.Read()
					fileInputPath = r.Value
				)
				
				"OutputPath": 
				(
					r.Read()
					fileOutputPath = r.Value
				)
				default:()
			)
		)
		
	)
	
	r.Close()
	
	
	--User interface for modifying render settings and initiating the rendering process
	--Right now the user can only modify input and output paths through the interface
	rollout RenderSettings "Render Settings"  width:500 height:200
	(
		edittext text_inputPath "Input Folder            " text: fileInputPath fieldWidth:270  align:#right pos:[15,50] readOnly:true
		button btn_getInputPath "Browse" align:#left width:60 height:20 pos:[400,50]
		
		edittext text_outputPath "Output Folder         " text: fileOutputPath fieldWidth:270  align:#right pos:[15,70] readOnly:true
		button btn_getOutputPath "Browse" align:#left width:60 height:20 pos:[400,70]
		
		button btn_startRender "StartRender" width:60 height:20 pos:[100,100]
		
		on btn_getInputPath pressed do 
		(
			savePath = getSavePath caption:"Select an input folder" initialDir:"C:\\"
			
			if (savePath != undefined) do
			(				
				fileInputPath = savePath + "\\"
				text_inputPath.text = fileInputPath
				
				--Update the render settings xml file with the newly selected path
				WriteRenderSettings text_inputPath.text text_outputPath.text
			)	
		)
		
		on btn_getOutputPath pressed do 
		(
			savePath = getSavePath caption:"Select an input folder" initialDir:"C:\\"
			
			if (savePath != undefined) do
			(
				fileOutputPath = savePath + "\\"
				text_outputPath.text = fileOutputPath
				
				--Update the render settings xml file with the newly selected path
				WriteRenderSettings text_inputPath.text text_outputPath.text
			)	
		)
		
		on btn_startRender pressed do
		(
			--Make sure the user hasn't left any path settings on default
			if (text_inputPath.text == "Please choose an input path" or text_outputPath.text == "Please choose an output path") then
			(
				messagebox "Please specify input and output paths!"
			)
			--If the user has specified valid input and output paths, 
			else
			(
				DestroyDialog RenderSettings
				
				--Find all .FBX files in the supplied input path
				inputFilter = fileInputPath + "*.FBX"
				files = getFiles inputFilter
				
				--Iterate through all the .FBX files in the folder specified above,
				--Producing renders of each
				for f in files do
				(
					renderObject f
				)
				
				print "Done"
		)
		)
		
	)
	
	createDialog RenderSettings
)

fn WriteRenderSettings inPath outPath =
(
	xWriter = dotNetClass "System.Xml.XmlWriter"
	
	settings = dotNetObject "System.Xml.XmlWriterSettings"
	settings.Indent = true
	
	w = xWriter.Create(getFilenamePath (getSourceFileName()) +  "renderSettings.xml") settings
	w.WriteStartDocument();
	w.WriteStartElement("renderSettings")
	w.WriteElementString "InputPath"  inPath
	w.WriteElementString "OutputPath" outPath
	w.WriteEndElement()
	w.Close()


	
)

fn DirectoryChecker =
(
	--The globals SizeFolders and imageSizes are used here
	
	directory = fileOutputPath + "\\"
	
	for i = 1 to imgSizes.count do
	(
		if (doesFileExist (directory + SizeFolders[i] + "png\\") == false) then
		(
			makeDir (directory + SizeFolders[i] + "png\\") all:true
		)
		
		if (doesFileExist (directory + SizeFolders[i] + "jpeg\\") == false) then
		(
			makeDir (directory + SizeFolders[i] + "jpeg\\") all:true
		)
		
		
	)
	
	if (doesFileExist (directory + "PS_1024\\") == false) then
		(
			makeDir (directory + "PS_1024\\") all:true
		)
	
)

fn changeMat b_lineart =
(
	selset = getCurrentSelection()
	
	if (b_lineart) then
	(
		--Applies a material that only draws lineart to the current object
		for obj in selset do (obj.material = meditMaterials[5])
	)
	else
	(
		--Switches the current material back to something colored
		for obj in selset do 
		(
			if (obj.name == "Back_mesh") then
			(
				obj.material = meditMaterials[8]
			)
			else
			(
				obj.material = meditMaterials[9]	
			)
			
			--Sets the material to justs a regular standard grey instead of the 
			--Multi-sub object stuff above
			--obj.material = meditMaterials[12]	
		)
		
		
	)
	
)

--Takes the passed in FBX file, finds its associated Excel doc, and produces renders with the data from both
fn renderObject fbxFile =
(
	--Import the input FBX file
	importFile fbxFile #noPrompt
	
	--Applies a filter to only select geometry
	setSelectFilter 2
	
	--Selects all objects under the selection filter, so just geometry
	max select all
	
	-- get selected block
	selset = getCurrentSelection()
	
	--Changes the current material to a non-lineart material specified in changeMat
	changeMat false
	
	
	--Modifies the file directory of the fbxfile in order to find the Excel doc paired with the given mesh
	--Did you know that substituteString is case sensitive? It's true!
	--If FBX were in all lovercase letters, it would not successfully replace the .FBX with .xlsx
	
	--The current workaround will be to convert the fbxFile path to all uppercase letters, and then run substitute string against that.
	--That way it will always successfully find the .fbx filetype even if the case is different. 
	--Everything else is case-insensitive so it doesn't matter if it's suudenly all caps for the rest of the script
	
	excelFile =  substituteString (toUpper (fbxFile as string)) ".FBX" ".xlsx"
	
	--Reads in the camera data from the Excel doc and produces all the specified cameras for rendering.
	--include "C:\Users\pharju\Dropbox\Steelcase Unity\ThumbnailRendering\Scripts\excelCRUD.ms"
	
	--ReadCameraData("C:\Users\pharju\Dropbox\Steelcase Unity\ThumbnailRendering\imageRenders\DefaultCams.xlsx")
	ReadCameraData(fileInputPath + "DefaultCams.xlsx")
	
	if (doesFileExist excelFile) do
		ReadCameraData(excelFile)
	
	--Once file is imported, move it to (0,0,0)
	--May ignore this right now, since the gesture file is several pieces
	
	--for each camera in the scene...
	--render out an image
	--OutputPath = "C:\Users\pharju\Dropbox\Steelcase Unity\ThumbnailRendering\imageRenders\\"
	OutputPath = fileOutputPath
	
	for c in cameras do
	(

		--The base directory where all the render images will be thrown
		--Should contain folders for each image size, with folders for each format within those
		--OutputPath = "C:\Users\pharju\Dropbox\Steelcase Unity\ThumbnailRendering\imageRenders\\"
		OutputPath = fileOutputPath
		
		print c.Name
		
		--Sets the viewport to the current camera to be rendered from
		viewport.setCamera c

		--The globals SizeFolders and imageSizes are used here
		
		DirectoryChecker()
		
		--May or may no be nessesary, turns on contour rendering for the current renderer, which must be mental ray
		--Or an error will be thrown
		renderers.current.EnableContours = false;
		
		
		--Produces .png and .jpg images at the sizes specified in imgSizes, saved in the folders specified in SizeFolders
		for i = 1 to imgSizes.count do
		(
			OutputFilePNG = OutputPath + SizeFolders[i] +  "png\\" + (getFilenameFile fbxfile) + "_" + (c.Name as string) + ".png"
			
			--Renders the image at the specified resolution as a png
			render rendertype:#view outputwidth:imgSizes[i] outputheight:imgSizes[i] force2sided:true outputfile:OutputFilePNG vfb:false
			
			--Modifies the path to point to the folder for jpgs, with a .jpg filetype
			OutputFileJPEG = substituteString OutputFilePNG ".png" ".jpeg"
			OutputFileJPEG = substituteString OutputFileJPEG "png\\" "jpeg\\"
			
			--Renders the image at the specified resolution as a jpeg
			render rendertype:#view outputwidth:imgSizes[i] outputheight:imgSizes[i] force2sided:true outputfile:OutputFileJPEG vfb:false
		)
		
		--Enables postscript image output
		renderers.current.EnableContours = true;	
		
		renderers.current.Contour_Output_Shader = meditMaterials[1]
		
		--Applies a material that only draws lineart to the current object
		--for obj in selset do (obj.material = meditMaterials[5])
		changeMat true
		
		--Renders out a higher resolution image specifically for the postscript lineart, because it doesn't render well at lower resolutions
		--The lineart can be converted to a lower resolution thumbnail later if it needs to be a raster image
		PSPath = fileOutputPath + "PS_1024\\" +  (getFilenameFile fbxfile as string) + "_" + (c.Name as string)
		meditMaterials[1].file_name = PSPath + ".ps"
		OutputFilePS = PSPath + ".ps"
		
		render rendertype:#view outputwidth:1024 outputheight:1024 force2sided:true vfb:false
		
		--Render out a version of the lineart in an image format
		renderers.current.Contour_Output_Shader = meditMaterials[4]
		OutputFilePS_Raster = PSPath + ".png"
		render rendertype:#view outputwidth:1024 outputheight:1024 force2sided:true outputfile:OutputFilePS_Raster vfb:false
		
		--Turns the current material back to a nice ArchDesign material
		--for obj in selset do (obj.material = meditMaterials[2])
		changeMat false
		
		
		renderers.current.Contour_Output_Shader = meditMaterials[1]
		--Deletes the camera after rendering form that view is finished
		--delete c

		
	)
	delete cameras
	
	--Cleans up the object being rendered
	delete selset
	--close file
)
