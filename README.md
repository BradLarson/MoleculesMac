# Molecules for Mac #

<div style="float: right"><img src="http://sunsetlakesoftware.com/sites/default/files/MoleculesDesktopLogo.png" /></div>

Brad Larson

http://www.sunsetlakesoftware.com

[@bradlarson](http://twitter.com/bradlarson)

contact@sunsetlakesoftware.com

## Overview ##

Molecules is a molecular visualizer for the Mac, and a counterpart to Molecules on iOS. It allows you to view three-dimensional renderings of molecules and manipulate them using a mouse or a [Leap Motion controller](https://www.leapmotion.com). This application is a counterpart to [the iOS Molecules application](http://sunsetlakesoftware.com/molecules), which uses the same rendering engine to present 3-D molecules on touchscreen devices.

The application currently supports molecular structures in the PDB, SDF, and XYZ file formats. These files can be downloaded from a number of sources, including the [RCSB Protein Data Bank](http://www.rcsb.org/pdb) and [NCBI's PubChem](http://pubchem.ncbi.nlm.nih.gov).

Two visualization modes are supported within the application: ball-and-stick, and spacefilling. These can be switched at any time under the View | Visualization Mode submenu. Additionally, molecules can be set to autorotate using the View | Autorotate option.

The molecular structures can be displayed either within a window or in fullscreen by clicking the fullscreen button in the upper right corner of the rendering window.

Molecules is free and its source code is available under the BSD license. I feel that this can be a useful scientific and educational tool, and welcome any feedback you can provide to make it an even better program.

## License ##

BSD-style, with the full license available with the framework in License.txt.

## Controls ##

Once loaded, a molecular structure can be interacted with using either the mouse or a [Leap Motion controller](https://www.leapmotion.com). Both methods of interaction can be used at the same time.

# Mouse controls #
<p>A molecule can be manipulated to rotate, scale, and pan it within the displayed window. Clicking the left mouse button and dragging rotates the structure about the center of the display. Holding the Shift key while dragging up and down zooms the structure in and out. The structure can also be zoomed in on by using the mouse's scroll wheel (or a scrolling gesture on a trackpad). Holding the Command key while dragging pans the molecule around the view.</p>

# Leap Motion controls #

The Leap Motion controller allows you to use your hands in open space to interact with your computer in a unique manner. In Molecules, this is used to provide a direct manipulation of molecules using 3-D hand movement.

To start interacting with a molecule, select a molecule window to make sure it's active and taking input. Move an open hand within the field of view of the Leap controller and the molecule will start responding.

Movements parallel to the screen (left-to-right, top-to-bottom) will rotate the molecule. Movements toward and away from the screen will scale the molecule, as if you were pulling or pushing it. Bringing two open hands into view of the controller will let you pan the molecule by moving both hands parallel to the screen.

Finally, if you wish to stop interacting with a molecule using your hand, close it into a fist and your movements will no longer be registered.

## Technical requirements ##

- Lion or Mountain Lion
- A Leap Motion controller enables gesture-based controls, but is not necessary for operation. Mouse input will be used otherwise.
- To build the application from source, the Leap SDK is required and must be installed at the same directory level as the directory for this project.