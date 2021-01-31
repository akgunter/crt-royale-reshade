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
	// #include "crt-royale/shaders/crt-royale-scanlines-vertical-interlacing-new.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-approx.fxh"
	#include "crt-royale/shaders/blur9fast-vertical.fxh"
	#include "crt-royale/shaders/blur9fast-horizontal.fxh"
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


technique CRT_Royale
{
	// Toggle the content box to help users configure it
	#if CONTENT_BOX_VISIBLE
		// content-box.fxh
		pass contentBoxPass
		{
			VertexShader = PostProcessVS;
			PixelShader = contentBoxPixelShader;
		}
	#else
		// content-crop.fxh
		pass cropPass
		{
			VertexShader = PostProcessVS;
			PixelShader = cropContentPixelShader;

			RenderTarget = texCrop;
		}
		// crt-royale-first-pass-linearize-crt-gamma-bob-fields.fx
		pass linearizeAndBobPass
		{
			VertexShader = vertexShader0;
			PixelShader = pixelShader0;

			RenderTarget = texOrigLinearized;
		}
		// crt-royale-scanlines-vertical-interlacing.fxh
		pass verticalBeamPass
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader1;

			RenderTarget = texVerticalScanlines;
		}
		pass verticalOffsetPass {
			VertexShader = PostProcessVS;
			PixelShader = verticalOffsetPS;

			RenderTarget = texVerticalOffset;
		}
		// crt-royale-bloom-approx.fxh
		pass bloomApproxPass
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader2;
			
			RenderTarget = texBloomApprox;
		}
		// blur9fast-vertical.fxh
		pass blurVerticalPass
		{
			VertexShader = vertexShader3;
			PixelShader = pixelShader3;
			
			RenderTarget = texBlurVertical;
		}
		// blur9fast-horizontal.fxh
		pass blurHorizontalPass
		{
			VertexShader = vertexShader4;
			PixelShader = pixelShader4;
			
			RenderTarget = texBlurHorizontal;
		}
		// crt-royale-mask-resize.fxh
		pass phosphorMaskResizeVerticalPass
		{
			VertexShader = maskResizeVertVS;
			PixelShader = maskResizeVertPS;
			
			RenderTarget = texMaskResizeVertical;
		}
		// crt-royale-mask-resize.fxh
		pass phosphorMaskResizeHorizontalPass
		{
			VertexShader = maskResizeHorizVS;
			PixelShader = maskResizeHorizPS;
			
			RenderTarget = texMaskResizeHorizontal;
		}
		// crt-royale-scanlines-horizontal-apply-mask-new.fxh
		pass phosphorMaskPass
		{
			VertexShader = PostProcessVS;
			PixelShader = newPixelShader7;
			
			RenderTarget = texMaskedScanlines;
		}
		// crt-royale-brightpass.fxh
		pass brightpassPass
		{
			VertexShader = vertexShader8;
			PixelShader = pixelShader8;
			
			RenderTarget = texBrightpass;
		}
		// crt-royale-bloom-vertical.fxh
		pass bloomVerticalPass
		{
			VertexShader = vertexShader9;
			PixelShader = pixelShader9;
			
			RenderTarget = texBloomVertical;
		}
		// crt-royale-bloom-horizontal-reconstitute.fxh
		pass bloomHorizontalPass
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

			// Explicitly disable clearing render targets
			//   scanlineBlendPass will not work properly if this ever defaults to true
			ClearRenderTargets = false;
		}
		// crt-royale-geometry-aa-last-pass.fxh
		pass geometryPass
		{
			VertexShader = vertexShader11;
			PixelShader = pixelShader11;

			RenderTarget = texGeometry;
		}
		// content-crop.fxh
		pass uncropPass
		{
			VertexShader = PostProcessVS;
			PixelShader = uncropContentPixelShader;
		}
	#endif
}