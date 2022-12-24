This is a port of the crt-royale shader by TroggleMonkey from RetroArch/libretro to ReShade 4.9+.


#### CREDIT
The vast majority of the code here is taken from the current libretro shader repositories, so the most of the credit goes to those authors.

[libretro/glsl-shaders](https://github.com/libretro/glsl-shaders)<br>
[libretro/slang-shaders](https://github.com/libretro/slang-shaders)

Special thanks goes to Matsilagi for his time, suggestions, testing, debugging, and enthusiasm. It's been tremendously helpful, especially in figuring out some of the nastier bugs.
Lord of Lunacy and Marty McFly helped me with some optimizations that were really cool.
Thank you Crosire and co. for all their work on ReShade.
Thanks to andersstorhaug for the idea to let the user rotate the screen.


#### API SUPPORT
This shader should work with DX9, DX10/11/12, OpenGL, and Vulkan. It'll probably spit out a bunch of yellow error messages in DX9, but that's okay.


#### SUGGESTED REPOSITORIES
[Matsilagi/RSRetroArch](https://github.com/Matsilagi/RSRetroArch) - Matsilagi has a chunk of other RetroArch shaders ported over here already. The PAL and NTSC shaders are particularly useful (load them before crt-royale).


#### SETUP
The shader's UI includes tips and descriptions for setting it up well. Prioritize the Phosphor Mask and Scanlines sections.

You can go to [the wiki](https://github.com/akgunter/crt-royale-reshade/wiki) for more detailed info on the different options.