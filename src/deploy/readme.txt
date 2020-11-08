Eihort v0.4.1
by Lloigor with contributions from exp, rebio and erich666

This readme-file will be replaced by the dynamic html readme soon. Don't expect this readme to be up-to-date with the latest changes.
If you miss any information search the new html readme or contact the developers on https://bitbucket.org/lloigor/eihort.

A long view-distance OpenGL Minecraft world viewer


 :: Disclaimer ::

This program is distributed as is without ANY warranty whatsoever.
This is unfinished, experimental software - there will be bugs.


 :: Installation ::

  -) Windows, Mac and Linux (tgz):
Unzip and run the exe/app.

  -) Linux (package):
Install the package with:
	sudo dpkg -i eihort_<version>.deb

	
 :: Running ::

  -) Windows and Mac:
Drag and drop the world folder onto eihort.exe (the file you downloaded,
not the running program).

  -) All platforms:
You can run Eihort from the command line with the path to the world folder
as the first argument. If your path contains spaces, make sure you put quotes
around it. E.g.:

eihort "C:\Users\???\AppData\Roaming\.minecraft\saves\World1"

If no path is given, Eihort will try to find some worlds to load and
let you choose between them. Eihort will search for worlds in
the Minecraft saves folder and in ./ . More paths can be added in
eihort.config.

Eihort will merge eihort.config files in $USERPROFILE (e.g. C:\Users\???\
on Windows 7), and $XSD_CONFIG_HOME or $HOME/.config with the main config
file with the Eihort executable. User-defined settings can be placed here
if you do not have easy access to the eihort.config with the Eihort
executable.

Laptops running nVidia Optimus will not automatically switch to the
high-performance GPU automatically unless a profile is created for Eihort
in the nVidia control panel. If you have a discrete GPU, yet get the
message warning that your GPU memory could not be detected, then this is
likely the cause.

Enjoy!


 :: Texture Packs ::

For texture/resource pack information see readme.html -> .documentation -> config file -> resource pack


 :: Biomes ::

 Minecraft worlds stored in the Anvil format (introduced with Minecraft 
version 1.2.1) will have biomes automatically enabled. To have Eihort 
draw biomes correctly for maps stored in the MCRegion format, you will 
need Donkey Kong's Minecraft Biome Extractor from
http://www.minecraftforum.net/viewtopic.php?f=1022&t=80902 .
Run MBE on your world and Eihort will automatically use the extracted
biome information.


 :: Controls ::

Controls can be modified in eihort.config. The default controls are:

For keybindings see readme.html -> .documentation -> key layout


 :: Bugs ::

If you find a bug in Eihort, please report it to the issues section of
https://bitbucket.org/lloigor/eihort/, or in the Eihort thread on the
Minecraft forums.
For rendering bugs, please include a screenshot. For crashes, please
describe how you got it to crash, along with your system specs (platform,
CPU, GPU). Crash dumps are welcome from those able to produce them.


 :: Acknowledgements ::

This program would not be possible without:
    Minecraft (of course)
	zlib (http://zlib.net/)
    SDL and SDL_image (http://www.libsdl.org/)
	libpng (http://www.libpng.org/pub/png/libpng.html)
    GLEW (http://glew.sourceforge.net/)
    Triangle (http://www.cs.cmu.edu/~quake/triangle.html)
    Lua (http://www.lua.org/)


