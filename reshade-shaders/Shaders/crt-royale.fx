#include "ReShade.fxh"

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

// Enable or disable the shader
#ifndef CONTENT_BOX_VISIBLE
	#define CONTENT_BOX_VISIBLE 0
#endif

#if !CONTENT_BOX_VISIBLE
	#include "crt-royale/shaders/content-crop.fxh"
	#include "crt-royale/shaders/crt-royale-first-pass-linearize-crt-gamma-bob-fields.fxh"
	#include "crt-royale/shaders/crt-royale-scanlines-vertical-interlacing.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-approx.fxh"
	#include "crt-royale/shaders/blur9fast-vertical.fxh"
	#include "crt-royale/shaders/blur9fast-horizontal.fxh"
	// #include "crt-royale/shaders/crt-royale-mask-resize-vertical.fxh"
	// #include "crt-royale/shaders/crt-royale-mask-resize-horizontal.fxh"
	#include "crt-royale/shaders/crt-royale-mask-resize.fxh"
	#include "crt-royale/shaders/crt-royale-scanlines-horizontal-apply-mask.fxh"
	#include "crt-royale/shaders/crt-royale-brightpass.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-vertical.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-horizontal-reconstitute.fxh"
	#include "crt-royale/shaders/crt-royale-geometry-aa-last-pass.fxh"
	#include "crt-royale/shaders/crt-royale-blend-frames.fxh"
#else
	#include "crt-royale/shaders/content-box.fxh"
#endif

texture2D texOut {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
};
sampler2D samplerOut {
	Texture = texOut;

	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};

#ifndef box_width
	#define box_width 100
#endif
#ifndef box_height
	#define box_height int(box_width * float(BUFFER_HEIGHT) / BUFFER_WIDTH)
#endif
#ifndef box_center_x
	#define box_center_x 0
#endif
// Offset the center of the game's content (vertical)
#ifndef box_center_y
	#define box_center_y 0
#endif

static const float2 box_size = float2(box_width, box_height);

static const float2 box_center = float2(box_center_x, box_center_y) / buffer_size + 0.5;
static const float2 box_radius = box_size / (2.0 * buffer_size);

static const float box_left = box_center.x - box_radius.x;
static const float box_right = box_center.x + box_radius.x;
static const float box_upper = box_center.y - box_radius.y;
static const float box_lower = box_center.y + box_radius.y;
static const float2 box_offset = float2(box_left, box_upper);


texture2D texBox {
	Width = box_width;
	Height = box_height;
};
sampler2D samplerBox {
	Texture = texBox;

	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};

void getBoxPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 texcoord_cropped = texcoord * box_size / buffer_size + box_offset;
    color = tex2D(samplerOut, texcoord_cropped);
}
void unboxPixelShader(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerBox, texcoord);
}


technique CRT_Royale
{
	// Toggle the content box to help users configure it
	#if CONTENT_BOX_VISIBLE
		// content-box.fxh
		pass contentBox
		{
			VertexShader = PostProcessVS;
			PixelShader = contentBoxPixelShader;
		}
	#else
		// content-crop.fxh
		pass crop
		{
			VertexShader = PostProcessVS;
			PixelShader = cropContentPixelShader;

			RenderTarget = texCrop;
		}
		// crt-royale-first-pass-linearize-crt-gamma-bob-fields.fx
		pass p0
		{
			VertexShader = vertexShader0;
			PixelShader = pixelShader0;

			RenderTarget = texOrigLinearized;
		}
		// crt-royale-scanlines-vertical-interlacing.fxh
		pass p1
		{
			VertexShader = vertexShader1;
			PixelShader = pixelShader1;

			RenderTarget = texVerticalScanlines;
		}
		// crt-royale-bloom-approx.fxh
		pass p2
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader2;
			
			RenderTarget = texBloomApprox;
			// RenderTarget = texGeometry;
		}
		// blur9fast-vertical.fxh
		pass p3
		{
			VertexShader = vertexShader3;
			PixelShader = pixelShader3;
			
			RenderTarget = texBlurVertical;
		}
		// blur9fast-horizontal.fxh
		pass p4
		{
			VertexShader = vertexShader4;
			PixelShader = pixelShader4;
			
			RenderTarget = texBlurHorizontal;
		}
		// crt-royale-mask-resize.fxh
		pass p5
		{
			VertexShader = maskResizeVertVS;
			PixelShader = maskResizeVertPS;
			
			RenderTarget = texMaskResizeVertical;
		}
		// crt-royale-mask-resize.fxh
		pass p6
		{
			VertexShader = maskResizeHorizVS;
			PixelShader = maskResizeHorizPS;
			
			RenderTarget = texMaskResizeHorizontal;
		}
		// crt-royale-scanlines-horizontal-apply-mask-new.fxh
		pass p7
		{
			VertexShader = PostProcessVS;
			PixelShader = newPixelShader7;
			
			RenderTarget = texMaskedScanlines;
		}
		// crt-royale-brightpass.fxh
		pass p8
		{
			VertexShader = vertexShader8;
			PixelShader = pixelShader8;
			
			RenderTarget = texBrightpass;
		}
		// crt-royale-bloom-vertical.fxh
		pass p9
		{
			VertexShader = vertexShader9;
			PixelShader = pixelShader9;
			
			RenderTarget = texBloomVertical;
		}
		// crt-royale-bloom-horizontal-reconstitute.fxh
		pass p10
		{
			VertexShader = vertexShader10;
			PixelShader = pixelShader10;
			
			RenderTarget = texBloomHorizontal;
		}
		// crt-royale-blend-frames.fxh
		pass scanlineBlendPass
		{
			VertexShader = PostProcessVS;
			PixelShader = lerpScanlinesPS;
			
			RenderTarget = texBlendScanline;
		}
		// crt-royale-blend-frames.fxh
		pass freezeFramePass
		{
			VertexShader = PostProcessVS;
			PixelShader = freezeFramePS;

			RenderTarget = texFreezeFrame;
			ClearRenderTargets = false;
		}
		// crt-royale-geometry-aa-last-pass.fxh
		pass p11
		{
			VertexShader = vertexShader11;
			PixelShader = pixelShader11;

			RenderTarget = texGeometry;
		}
		// content-crop.fxh
		pass uncrop
		{
			VertexShader = PostProcessVS;
			PixelShader = uncropContentPixelShader;

			// RenderTarget = texOut;
		}
		// pass box
		// {
		// 	VertexShader = PostProcessVS;
		// 	PixelShader = getBoxPixelShader;

		// 	RenderTarget = texBox;
		// }
		// pass unbox
		// {
		// 	VertexShader = PostProcessVS;
		// 	PixelShader = unboxPixelShader;
		// }
	#endif
}