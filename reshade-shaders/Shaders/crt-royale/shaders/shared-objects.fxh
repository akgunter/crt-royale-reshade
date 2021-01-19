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


// Initial Color Buffer
texture2D texColorBuffer : COLOR;
sampler2D samplerColor {
	Texture = texColorBuffer;

	MagFilter = NONE;
	MinFilter = NONE;
	MipFilter = NONE;
};

// Yes, the WIDTH/HEIGHT/SIZE defines are kinda weird.
// Yes, we have to have them or something similar. This is for D3D11 which
// returns (0, 0) when you call tex2Dsize() on the pass's output texture.


// Crop pass
#define TEX_CROP_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_CROP_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_CROP_SIZE int2(TEX_CROP_WIDTH, TEX_CROP_HEIGHT)
texture2D texCrop {
	Width = TEX_CROP_WIDTH;
	Height = TEX_CROP_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerCrop { Texture = texCrop; };

// Pass 0 Buffer (ORIG_LINEARIZED)
#define TEX_ORIGLINEARIZED_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_ORIGLINEARIZED_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_ORIGLINEARIZED_SIZE int2(TEX_ORIGLINEARIZED_WIDTH, TEX_ORIGLINEARIZED_HEIGHT)
texture2D texOrigLinearized {
	Width = TEX_ORIGLINEARIZED_WIDTH;
	Height = TEX_ORIGLINEARIZED_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOrigLinearized { Texture = texOrigLinearized; };

// Pass 1 Buffer (VERTICAL_SCANLINES)
#define TEX_VERTICALSCANLINES_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_VERTICALSCANLINES_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_VERTICALSCANLINES_SIZE int2(TEX_VERTICALSCANLINES_WIDTH, TEX_VERTICALSCANLINES_HEIGHT)
texture2D texVerticalScanlines {
	Width = TEX_VERTICALSCANLINES_WIDTH;
	Height = TEX_VERTICALSCANLINES_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerVerticalScanlines { Texture = texVerticalScanlines; };


// Pass 2 Buffer (BLOOM_APPROX)
#define TEX_BLOOMAPPROX_WIDTH 320
#define TEX_BLOOMAPPROX_HEIGHT 240
#define TEX_BLOOMAPPROX_SIZE int2(TEX_BLOOMAPPROX_WIDTH, TEX_BLOOMAPPROX_HEIGHT)
texture2D texBloomApprox {
	Width = TEX_BLOOMAPPROX_WIDTH;
	Height = TEX_BLOOMAPPROX_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomApprox { Texture = texBloomApprox; };


// Pass 3 Buffer
#define TEX_BLURVERTICAL_WIDTH TEX_BLOOMAPPROX_WIDTH
#define TEX_BLURVERTICAL_HEIGHT TEX_BLOOMAPPROX_HEIGHT
#define TEX_BLURVERTICAL_SIZE int2(TEX_BLURVERTICAL_WIDTH, TEX_BLURVERTICAL_HEIGHT)
texture2D texBlurVertical {
	Width = TEX_BLURVERTICAL_WIDTH;
	Height = TEX_BLURVERTICAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBlurVertical { Texture = texBlurVertical; };


// Pass 4 Buffer (HALATION_BLUR)
#define TEX_BLURHORIZONTAL_WIDTH TEX_BLOOMAPPROX_WIDTH
#define TEX_BLURHORIZONTAL_HEIGHT TEX_BLOOMAPPROX_HEIGHT
#define TEX_BLURHORIZONTAL_SIZE int2(TEX_BLURHORIZONTAL_WIDTH, TEX_BLURHORIZONTAL_HEIGHT)
texture2D texBlurHorizontal {
	Width = TEX_BLURHORIZONTAL_WIDTH;
	Height = TEX_BLURHORIZONTAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBlurHorizontal { Texture = texBlurHorizontal; };


// Pass 5 Mask Texture
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


// Pass 6 Mask Texture (MASK_RESIZE)
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


// Pass 7 Buffer (MASKED_SCANLINES)
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
	#define texMaskedScanlines texCrop
	#define samplerMaskedScanlines samplerCrop
#endif





// Pass 8 Buffer (BRIGHTPASS)
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
	#define texBrightpass texOrigLinearized
	#define samplerBrightpass samplerOrigLinearized
#endif





// Pass 9 Buffer
#define TEX_BLOOMVERTICAL_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLOOMVERTICAL_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BLOOMVERTICAL_SIZE int2(TEX_BLOOMVERTICAL_WIDTH, TEX_BLOOMVERTICAL_HEIGHT)

texture2D texBloomVertical {
	Width = TEX_BLOOMVERTICAL_WIDTH;
	Height = TEX_BLOOMVERTICAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomVertical { Texture = texBloomVertical; };


// Pass 10 Buffer
#define TEX_BLOOMHORIZONTAL_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLOOMHORIZONTAL_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BLOOMHORIZONTAL_SIZE int2(TEX_BLOOMHORIZONTAL_WIDTH, TEX_BLOOMHORIZONTAL_HEIGHT)
texture2D texBloomHorizontal {
	Width = TEX_BLOOMHORIZONTAL_WIDTH;
	Height = TEX_BLOOMHORIZONTAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomHorizontal { Texture = texBloomHorizontal; };


// Pass 11 Buffer
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


// Scanline Blend Buffer
#define TEX_BLENDSCANLINE_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_BLENDSCANLINE_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_BLENDSCANLINE_SIZE int2(TEX_BLENDSCANLINE_WIDTH, TEX_BLENDSCANLINE_HEIGHT)
texture2D texBlendScanline {
	Width = TEX_BLENDSCANLINE_WIDTH;
	Height = TEX_BLENDSCANLINE_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBlendScanline { Texture = texBlendScanline; };

// Frame Merge Buffer
#define TEX_FREEZEFRAME_WIDTH CONTENT_WIDTH_INTERNAL
#define TEX_FREEZEFRAME_HEIGHT CONTENT_HEIGHT_INTERNAL
#define TEX_FREEZEFRAME_SIZE int2(TEX_FREEZEFRAME_WIDTH, TEX_FREEZEFRAME_HEIGHT
texture2D texFreezeFrame {
	Width = TEX_FREEZEFRAME_WIDTH;
	Height = TEX_FREEZEFRAME_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerFreezeFrame { Texture = texFreezeFrame; };


uniform int frame_count < source = "framecount"; >;

#endif  // _SHARED_OBJECTS_H