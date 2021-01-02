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

// The width of the game's content
#ifndef CONTENT_WIDTH
	#define CONTENT_WIDTH BUFFER_WIDTH
#endif
// The height of the game's content
#ifndef CONTENT_HEIGHT
	#define CONTENT_HEIGHT BUFFER_HEIGHT
#endif

// Offset the center of the game's content (horizontal)
#ifndef CONTENT_CENTER_X
	#define CONTENT_CENTER_X 0
#endif
// Offset the center of the game's content (vertical)
#ifndef CONTENT_CENTER_Y
	#define CONTENT_CENTER_Y 0
#endif

static const float2 buffer_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
static const float2 content_size = float2(CONTENT_WIDTH, CONTENT_HEIGHT);
static const float orig_pixel_dx = 1.0 / BUFFER_WIDTH;
static const float orig_pixel_dy = 1.0 / BUFFER_HEIGHT;
static const float content_center_x = CONTENT_CENTER_X * orig_pixel_dx + 0.5;
static const float content_center_y = CONTENT_CENTER_Y * orig_pixel_dy + 0.5;
static const float content_radius_x = (CONTENT_WIDTH) * orig_pixel_dx / 2.0;
static const float content_radius_y = (CONTENT_HEIGHT) * orig_pixel_dy / 2.0;


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
#define TEX_CROP_WIDTH BUFFER_WIDTH
#define TEX_CROP_HEIGHT BUFFER_HEIGHT
#define TEX_CROP_SIZE int2(TEX_CROP_WIDTH, TEX_CROP_HEIGHT)
texture2D texCrop {
	Width = TEX_CROP_WIDTH;
	Height = TEX_CROP_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerCrop { Texture = texCrop; };

// Pass 0 Buffer (ORIG_LINEARIZED)
#define TEX_ORIGLINEARIZED_WIDTH CONTENT_WIDTH
#define TEX_ORIGLINEARIZED_HEIGHT CONTENT_HEIGHT
#define TEX_ORIGLINEARIZED_SIZE int2(TEX_ORIGLINEARIZED_WIDTH, TEX_ORIGLINEARIZED_HEIGHT)
texture2D texOrigLinearized {
	Width = TEX_ORIGLINEARIZED_WIDTH;
	Height = TEX_ORIGLINEARIZED_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOrigLinearized { Texture = texOrigLinearized; };

// Pass 1 Buffer (VERTICAL_SCANLINES)
#define TEX_VERTICALSCANLINES_WIDTH CONTENT_WIDTH
#define TEX_VERTICALSCANLINES_HEIGHT CONTENT_HEIGHT
#define TEX_VERTICALSCANLINES_SIZE int2(TEX_VERTICALSCANLINES_WIDTH, TEX_VERTICALSCANLINES_HEIGHT)
texture2D texVerticalScanlines {
	Width = TEX_VERTICALSCANLINES_WIDTH;
	Height = TEX_VERTICALSCANLINES_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerVerticalScanlines { Texture = texVerticalScanlines; };

static const int intermediate_buffer_x = 320;
static const int intermediate_buffer_y = 240;


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
#define TEX_MASKVERTICAL_WIDTH 64
#define TEX_MASKVERTICAL_HEIGHT int(CONTENT_HEIGHT * mask_resize_viewport_scale.y)
#define TEX_MASKVERTICAL_SIZE int2(TEX_MASKVERTICAL_WIDTH, TEX_MASKVERTICAL_HEIGHT)
texture2D texMaskResizeVertical {
	Width = TEX_MASKVERTICAL_WIDTH;
	Height = TEX_MASKVERTICAL_HEIGHT;
};
sampler2D samplerMaskResizeVertical { Texture = texMaskResizeVertical; };

// Pass 6 Mask Texture (MASK_RESIZE)
#define TEX_MASKHORIZONTAL_WIDTH int(CONTENT_WIDTH * mask_resize_viewport_scale.x)
#define TEX_MASKHORIZONTAL_HEIGHT int(CONTENT_HEIGHT * mask_resize_viewport_scale.y)
#define TEX_MASKHORIZONTAL_SIZE int2(TEX_MASKHORIZONTAL_WIDTH, TEX_MASKHORIZONTAL_HEIGHT)
texture2D texMaskResizeHorizontal {
	Width = TEX_MASKHORIZONTAL_WIDTH;
	Height = TEX_MASKHORIZONTAL_HEIGHT;
};
sampler2D samplerMaskResizeHorizontal { Texture = texMaskResizeHorizontal; };

// Pass 7 Buffer (MASKED_SCANLINES)
#define TEX_MASKEDSCANLINES_WIDTH CONTENT_WIDTH
#define TEX_MASKEDSCANLINES_HEIGHT CONTENT_HEIGHT
#define TEX_MASKEDSCANLINES_SIZE int2(TEX_MASKEDSCANLINES_WIDTH, TEX_MASKEDSCANLINES_HEIGHT)
texture2D texMaskedScanlines {
	Width = TEX_MASKEDSCANLINES_WIDTH;
	Height = TEX_MASKEDSCANLINES_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerMaskedScanlines { Texture = texMaskedScanlines; };

// Pass 8 Buffer (BRIGHTPASS)
#define TEX_BRIGHTPASS_WIDTH CONTENT_WIDTH
#define TEX_BRIGHTPASS_HEIGHT CONTENT_HEIGHT
#define TEX_BRIGHTPASS_SIZE int2(TEX_BRIGHTPASS_WIDTH, TEX_BRIGHTPASS_HEIGHT)
texture2D texBrightpass {
	Width = TEX_BRIGHTPASS_WIDTH;
	Height = TEX_BRIGHTPASS_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBrightpass { Texture = texBrightpass; };

// Pass 9 Buffer
#define TEX_BLOOMVERTICAL_WIDTH CONTENT_WIDTH
#define TEX_BLOOMVERTICAL_HEIGHT CONTENT_HEIGHT
#define TEX_BLOOMVERTICAL_SIZE int2(TEX_BLOOMVERTICAL_WIDTH, TEX_BLOOMVERTICAL_HEIGHT)
texture2D texBloomVertical {
	Width = TEX_BLOOMVERTICAL_WIDTH;
	Height = TEX_BLOOMVERTICAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomVertical { Texture = texBloomVertical; };

// Pass 10 Buffer
#define TEX_BLOOMHORIZONTAL_WIDTH CONTENT_WIDTH
#define TEX_BLOOMHORIZONTAL_HEIGHT CONTENT_HEIGHT
#define TEX_BLOOMHORIZONTAL_SIZE int2(TEX_BLOOMHORIZONTAL_WIDTH, TEX_BLOOMHORIZONTAL_HEIGHT)
texture2D texBloomHorizontal {
	Width = TEX_BLOOMHORIZONTAL_WIDTH;
	Height = TEX_BLOOMHORIZONTAL_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerBloomHorizontal { Texture = texBloomHorizontal; };

// Pass 11 Buffer
#define TEX_GEOMETRY_WIDTH CONTENT_WIDTH
#define TEX_GEOMETRY_HEIGHT CONTENT_HEIGHT
#define TEX_GEOMETRY_SIZE int2(TEX_GEOMETRY_WIDTH, TEX_GEOMETRY_HEIGHT)
texture2D texGeometry {
	Width = TEX_GEOMETRY_WIDTH;
	Height = TEX_GEOMETRY_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerGeometry { Texture = texGeometry; };

uniform int frame_count < source = "framecount"; >;

#endif  // _SHARED_OBJECTS_H