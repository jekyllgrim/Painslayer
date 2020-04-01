pkmdl_import.py :
The model importer. It imports: skeleton data (bone locations+rotations+hierarchy), model geometry, texture UV coordinates, material indices and skeleton deformation data. Texture filenames are imported to a seperate textfile. It currently does not import: information pertaining to filenames and folder structure. (pointless anyway)
Planned: nothing.

pkanim_import.py :
The animation importer. It imports the bone matrices stored in a .ani file and converts them to locations and quaternions that Blender understands. Select the armature created by pkmdl_import before using this script. Each animation is stored in Blender as a seperate action.
Planned: automatic disabling of constraints.

pkanim_export.py :
The animation exporter. It converts Blender's bone locations and rotation quaternions to matrices in an .ani file that Painkiller can read. Select the model's original armature (the one created by pkmdl_import), then select the action you wish to export before using this script.
Note that this script does not work correctly with constraints in place. Before exporting an animation that uses constraints you must "bake" it first. Please see http://blenderartists.org/forum/showthread.php?t=75137 for a working baking script.
Planned: automatic baking.

armature_cleancopy.py :
For some complicated reasons, the armature created by pkmdl_import looks absolutely awful and is pretty much impossible to make animations for. This script turns the ugly armature in a more manageable one with the same bone locations and hierarchy but different bone rotations. Note that this means the cleaned up armature cannot directly play animations imported with pkanim_import, and you cannot directly export animations made for the cleaned armature.
Planned: sensible bone roll values to ease animation.

anim_cleancopy.py :
This script converts animations between an original armature as created by pkmdl_import and a cleaned up armature as created by armature_cleancopy. Note that if any constraints are applied to the cleaned up armature, the animation must be baked before converting it back to the original armature. When converting from the original armature to the cleaned up armature, all constraints must be turned off for the animation to play correctly. You can safely add bones to serve as IK constraint targets to the cleaned up armature, but you must not change the hierarchy (i.e. parenting) of the existing bones.
Planned: automatic baking and automatic disabling of constraints.

pkmdl_export.py :
The model exporter. To use, select the armature of the model. A text object with the same name as the armature object must exist. The text object lists the mesh objects that make the model and the textures to be applied to them in Painkiller. Fill in the filename with a .pkmdl extension and the script should do the rest. Note that it's still quite experimental, as I still don't understand some of the values in pkmdl files and might be mistaken about the ones I think I understand.
The text object must use the following format: each object name is followed by a space, an equals sign and another space (" = " without the quotes), followed by the surface name the surface should have in Painkiller. Each object line should be followed by one or more lines that give the textures to be applied to the model in Painkiller. These lines start with a tab. The first texture is listed first, second second, etc. These correspond with face material indices of the model in Blender. ****For an example of a suitable text object, import a model using pkmdl_import.****
Note that Painkiller saves UV coordinates per vertex, not per corner of each face, so each vertex can be associated with only one UV coordinate; any extras are currently discarded by the export script. If your UV map is discontinuous, you will have to break the vertex at the discontinuity as well. Sadly, this also causes a visible seam because the vertex normals of the resulting vertices will be different. I plan on doing this splitting automatically in a later version of the script and export the vertex normals correctly so you can have discontinuous UV maps without visible seams, but this might be more complicated than I think. :-P
Planned: automatic UV breaking. Fixing any bugs that might pop up.

All of these scripts were written by Boksha. I did not think up any of the formats these scripts import from and export to. I did spend many hours figuring out how the file formats work and many, many hours more writing these scripts so don't claim those as your own. If you use these scripts as a basis for other scripts, some credit would be nice. :-P