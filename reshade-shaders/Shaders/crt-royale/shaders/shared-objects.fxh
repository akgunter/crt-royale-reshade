#ifndef _SHARED_OBJECTS_H
#define _SHARED_OBJECTS_H

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale-reshade: A port of TroggleMonkey's crt-royale from libretro to ReShade.
//  Copyright (C) 2020 Alex Gunter <akg7634@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


#include "../lib/helper-functions-and-macros.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/texture-settings.fxh"


#if __RENDERER__ != 0x9000
    #define TEXCOORD_OFFSET 0.0
#else
    #define TEXCOORD_OFFSET 0.5
#endif

// The width of the game's content
#ifndef CONTENT_WIDTH
	#define CONTENT_WIDTH BUFFER_WIDTH
#endif
// The height of the game's content
#ifndef CONTENT_HEIGHT
	#define CONTENT_HEIGHT BUFFER_HEIGHT
#endif

// Wrap the content size in parenthesis for internal use, so the
// user doesn't have to
#define CONTENT_WIDTH_INTERNAL int(CONTENT_WIDTH)
#define CONTENT_HEIGHT_INTERNAL int(CONTENT_HEIGHT)

// Offset the center of the game's content (horizontal)
#ifndef CONTENT_CENTER_X
	#define CONTENT_CENTER_X 0
#endif
// Offset the center of the game's content (vertical)
#ifndef CONTENT_CENTER_Y
	#define CONTENT_CENTER_Y 0
#endif

static const float2 buffer_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
static const float2 content_size = float2(CONTENT_WIDTH_INTERNAL, CONTENT_HEIGHT_INTERNAL);

uniform int frame_count < source = "framecount"; >;


// Yes, the WIDTH/HEIGHT/SIZE defines are kinda weird.
// Yes, we have to have them or something similar. This is for D3D11 which
// returns (0, 0) when you call tex2Dsize() on the pass's render target.


// Pass 0 Buffer (cropPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is in interlacingPass
//     electronBeamPass -> beamConvergencePass
//     deinterlacePass -> phosphorMaskPass
//     brightpassPass -> bloomHorizontalPass
#define TEX_CROP_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_CROP_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_CROP_SIZE int2(TEX_CROP_WIDTH, TEX_CROP_HEIGHT)
texture2D texCrop {
	Width = TEX_CROP_WIDTH;
	Height = TEX_CROP_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerCrop { Texture = texCrop; };


// Pass 1 Buffer (interlacingPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is in electronBeamPass
//     beamConvergencPass -> freezeFramePass
//     phosphorMaskPass -> bloomHorizontalPass
#define TEX_INTERLACED_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_INTERLACED_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_INTERLACED_SIZE int2(TEX_INTERLACED_WIDTH, TEX_INTERLACED_HEIGHT)
texture2D texInterlaced {
	Width = TEX_INTERLACED_WIDTH;
	Height = TEX_INTERLACED_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerInterlaced { Texture = texInterlaced; };


// Pass 2 Buffer (electronBeamPass)
//   Last usage is in beamConvergencePass
#define TEX_ELECTRONBEAMS_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_ELECTRONBEAMS_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_ELECTRONBEAMS_SIZE int2(TEX_ELECTRONBEAMS_WIDTH, TEX_ELECTRONBEAMS_HEIGHT)
#if __RENDERER__ != 0x9000
	texture2D texElectronBeams {
		Width = TEX_ELECTRONBEAMS_WIDTH;
		Height = TEX_ELECTRONBEAMS_HEIGHT;

		Format = RGBA16;
	};
	sampler2D samplerElectronBeams { Texture = texElectronBeams; };
#else
	#define texElectronBeams texCrop
	#define samplerElectronBeams samplerCrop
#endif


// Pass 3 Buffer (beamConvergencPass)
//   Last usage is freezeFramePass
#define TEX_BEAMCONVERGENCE_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BEAMCONVERGENCE_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BEAMCONVERGENCE_SIZE int2(TEX_BEAMCONVERGENCE_WIDTH, TEX_BEAMCONVERGENCE_HEIGHT)
#if __RENDERER__ != 0x9000
	texture2D texBeamConvergence {
		Width = TEX_BEAMCONVERGENCE_WIDTH;
		Height = TEX_BEAMCONVERGENCE_HEIGHT;
		
		Format = RGBA16;
	};
	sampler2D samplerBeamConvergence { Texture = texBeamConvergence; };
#else
	#define texBeamConvergence texInterlaced
	#define samplerBeamConvergence samplerInterlaced
#endif


/*
// Pass 4 Buffer (bloomApproxPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is in brightpassPass
#define TEX_BLOOMAPPROX_WIDTH 320
#define TEX_BLOOMAPPROX_HEIGHT 240
#define TEX_BLOOMAPPROX_SIZE int2(TEX_BLOOMAPPROX_WIDTH, TEX_BLOOMAPPROX_HEIGHT)
texture2D texBloomApprox {
	Width = TEX_BLOOMAPPROX_WIDTH;
	Height = TEX_BLOOMAPPROX_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomApprox { Texture = texBloomApprox; };
*/

// Pass 4a Buffer (bloomApproxVerticalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is in brightpassPass
#define TEX_BLOOMAPPROXVERT_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLOOMAPPROXVERT_HEIGHT 240
#define TEX_BLOOMAPPROXVERT_SIZE int2(TEX_BLOOMAPPROXVERT_WIDTH, TEX_BLOOMAPPROXVERT_HEIGHT)
texture2D texBloomApproxVert {
	Width = TEX_BLOOMAPPROXVERT_WIDTH;
	Height = TEX_BLOOMAPPROXVERT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomApproxVert { Texture = texBloomApproxVert; };

// Pass 4b Buffer (bloomApproxHorizontalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is in brightpassPass
#define TEX_BLOOMAPPROXHORIZ_WIDTH 320
#define TEX_BLOOMAPPROXHORIZ_HEIGHT 240
#define TEX_BLOOMAPPROXHORIZ_SIZE int2(TEX_BLOOMAPPROXHORIZ_WIDTH, TEX_BLOOMAPPROXHORIZ_HEIGHT)
texture2D texBloomApproxHoriz {
	Width = TEX_BLOOMAPPROXHORIZ_WIDTH;
	Height = TEX_BLOOMAPPROXHORIZ_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomApproxHoriz { Texture = texBloomApproxHoriz; };

// Pass 5 Buffer (blurVerticalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is blurHorizontalPass
#define TEX_BLURVERTICAL_WIDTH TEX_BLOOMAPPROXHORIZ_WIDTH
#define TEX_BLURVERTICAL_HEIGHT TEX_BLOOMAPPROXHORIZ_HEIGHT
#define TEX_BLURVERTICAL_SIZE int2(TEX_BLURVERTICAL_WIDTH, TEX_BLURVERTICAL_HEIGHT)
texture2D texBlurVertical {
	Width = TEX_BLURVERTICAL_WIDTH;
	Height = TEX_BLURVERTICAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBlurVertical { Texture = texBlurVertical; };


// Pass 6 Buffer (blurHorizontalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is bloomHorizontalPass
#define TEX_BLURHORIZONTAL_WIDTH TEX_BLOOMAPPROXHORIZ_WIDTH
#define TEX_BLURHORIZONTAL_HEIGHT TEX_BLOOMAPPROXHORIZ_HEIGHT
#define TEX_BLURHORIZONTAL_SIZE int2(TEX_BLURHORIZONTAL_WIDTH, TEX_BLURHORIZONTAL_HEIGHT)
texture2D texBlurHorizontal {
	Width = TEX_BLURHORIZONTAL_WIDTH;
	Height = TEX_BLURHORIZONTAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBlurHorizontal { Texture = texBlurHorizontal; };


// Pass 7 (deinterlacePass)
//   Last usage is phosphorMaskPass
#define TEX_DEINTERLACE_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_DEINTERLACE_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_DEINTERLACE_SIZE int2(TEX_DEINTERLACE_WIDTH, TEX_DEINTERLACE_HEIGHT)
#if __RENDERER__ != 0x9000
	texture2D texDeinterlace {
		Width = TEX_DEINTERLACE_WIDTH;
		Height = TEX_DEINTERLACE_HEIGHT;

		Format = RGBA16;
	};
	sampler2D samplerDeinterlace { Texture = texDeinterlace; };
#else
	#define texDeinterlace texCrop
	#define samplerDeinterlace samplerCrop
#endif

// Pass 8 (freezeFramePass)
// Do not condition this on __RENDERER__. It will not work if another
//   pass corrupts it.
#define TEX_FREEZEFRAME_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_FREEZEFRAME_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_FREEZEFRAME_SIZE int2(TEX_FREEZEFRAME_WIDTH, TEX_FREEZEFRAME_HEIGHT
texture2D texFreezeFrame {
	Width = TEX_FREEZEFRAME_WIDTH;
	Height = TEX_FREEZEFRAME_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerFreezeFrame { Texture = texFreezeFrame; };

// Pass 9 Mask Texture (phosphorMaskResizeVerticalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
// TODO: Figure out how to set these to 144 insead of 512
//       without losing data during downsampling
#define TEX_MASKVERTICAL_WIDTH mask_size_xy
#define TEX_MASKVERTICAL_HEIGHT mask_size_xy
#define TEX_MASKVERTICAL_SIZE int2(TEX_MASKVERTICAL_WIDTH, TEX_MASKVERTICAL_HEIGHT)
texture2D texMaskResizeVertical {
	Width = TEX_MASKVERTICAL_WIDTH;
	Height = TEX_MASKVERTICAL_HEIGHT;
};
sampler2D samplerMaskResizeVertical {
	Texture = texMaskResizeVertical;

    AddressU = mask_texture_wrap_mode;
    AddressV = mask_texture_wrap_mode;
    AddressW = mask_texture_wrap_mode;
};


// Pass 10 Mask Texture (phosphorMaskResizeHorizontalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
// TODO: Figure out how to set these to 144 insead of 512
//       without losing data during downsampling
#define TEX_MASKHORIZONTAL_WIDTH mask_size_xy
#define TEX_MASKHORIZONTAL_HEIGHT mask_size_xy
#define TEX_MASKHORIZONTAL_SIZE int2(TEX_MASKHORIZONTAL_WIDTH, TEX_MASKHORIZONTAL_HEIGHT)
texture2D texMaskResizeHorizontal {
	Width = TEX_MASKHORIZONTAL_WIDTH;
	Height = TEX_MASKHORIZONTAL_HEIGHT;
};
sampler2D samplerMaskResizeHorizontal {
	Texture = texMaskResizeHorizontal;
    
    AddressU = mask_texture_wrap_mode;
    AddressV = mask_texture_wrap_mode;
    AddressW = mask_texture_wrap_mode;
};


// Pass 11 Buffer (phosphorMaskPass)
//   Last usage is bloomHorizontalPass
#define TEX_MASKEDSCANLINES_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_MASKEDSCANLINES_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_MASKEDSCANLINES_SIZE int2(TEX_MASKEDSCANLINES_WIDTH, TEX_MASKEDSCANLINES_HEIGHT)

#if __RENDERER__ != 0x9000
	texture2D texMaskedScanlines {
		Width = TEX_MASKEDSCANLINES_WIDTH;
		Height = TEX_MASKEDSCANLINES_HEIGHT;

		Format = RGBA16;
	};
	sampler2D samplerMaskedScanlines { Texture = texMaskedScanlines; };
#else
	#define texMaskedScanlines texInterlaced
	#define samplerMaskedScanlines samplerInterlaced
#endif


// Pass 12 Buffer (brightpassPass)
//   Last usage is bloomHorizontalPass
#define TEX_BRIGHTPASS_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BRIGHTPASS_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BRIGHTPASS_SIZE int2(TEX_BRIGHTPASS_WIDTH, TEX_BRIGHTPASS_HEIGHT)

#if __RENDERER__ != 0x9000
	texture2D texBrightpass {
		Width = TEX_BRIGHTPASS_WIDTH;
		Height = TEX_BRIGHTPASS_HEIGHT;

		Format = RGBA16;
	};
	sampler2D samplerBrightpass { Texture = texBrightpass; };
#else
	#define texBrightpass texCrop
	#define samplerBrightpass samplerCrop
#endif


// Pass 13 Buffer (bloomVerticalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is bloomHorizontalPass
#define TEX_BLOOMVERTICAL_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLOOMVERTICAL_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BLOOMVERTICAL_SIZE int2(TEX_BLOOMVERTICAL_WIDTH, TEX_BLOOMVERTICAL_HEIGHT)
texture2D texBloomVertical {
	Width = TEX_BLOOMVERTICAL_WIDTH;
	Height = TEX_BLOOMVERTICAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomVertical { Texture = texBloomVertical; };


// Pass 14 Buffer (bloomHorizontalPass)
//   Cannot be conditioned on __RENDERER__ b/c there are no
//     available buffers of the same size
//   Last usage is geometryPass
#define TEX_BLOOMHORIZONTAL_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLOOMHORIZONTAL_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BLOOMHORIZONTAL_SIZE int2(TEX_BLOOMHORIZONTAL_WIDTH, TEX_BLOOMHORIZONTAL_HEIGHT)
texture2D texBloomHorizontal {
	Width = TEX_BLOOMHORIZONTAL_WIDTH;
	Height = TEX_BLOOMHORIZONTAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomHorizontal { Texture = texBloomHorizontal; };


// Pass 15 Buffer (geometryPass)
//   Last usage is uncropPass
#define TEX_GEOMETRY_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_GEOMETRY_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_GEOMETRY_SIZE int2(TEX_GEOMETRY_WIDTH, TEX_GEOMETRY_HEIGHT)

#if __RENDERER__ != 0x9000
	texture2D texGeometry {
		Width = TEX_GEOMETRY_WIDTH;
		Height = TEX_GEOMETRY_HEIGHT;

		Format = RGBA16;
	};
	sampler2D samplerGeometry { Texture = texGeometry; };
#else
	#define texGeometry texCrop
	#define samplerGeometry samplerCrop
#endif

#endif  // _SHARED_OBJECTS_H