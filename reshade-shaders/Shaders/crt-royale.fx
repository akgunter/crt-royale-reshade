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
	#include "crt-royale/shaders/crt-royale-electron-beams.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-approx.fxh"
	#include "crt-royale/shaders/blur9fast-vertical.fxh"
	#include "crt-royale/shaders/blur9fast-horizontal.fxh"
	#include "crt-royale/shaders/crt-royale-phosphor-mask.fxh"
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
		// crt-royale-electron-beams.fx
		pass linearizeAndBobPass
		{
			VertexShader = linearizeAndBobVS;
			PixelShader = linearizeAndBobPS;

			RenderTarget = texOrigLinearized;
		}
		pass electronBeamPass
		{
			VertexShader = fancyScanWithElectronBeamsVS;
			PixelShader = fancyScanWithElectronBeamsPS;

			RenderTarget = texVerticalScanlines;
		}
		pass beamMisaslignmentPass {
			VertexShader = PostProcessVS;
			PixelShader = beamMisaslignmentPS;

			RenderTarget = texBeamMisalignment;
		}
		// crt-royale-bloom-approx.fxh
		pass bloomApproxPass
		{
			VertexShader = PostProcessVS;
			PixelShader = approximateBloomPS;
			
			RenderTarget = texBloomApprox;
		}
		// blur9fast-vertical.fxh
		pass blurVerticalPass
		{
			VertexShader = blurVerticalVS;
			PixelShader = blurVerticalPS;
			
			RenderTarget = texBlurVertical;
		}
		// blur9fast-horizontal.fxh
		pass blurHorizontalPass
		{
			VertexShader = blurHorizontalVS;
			PixelShader = blurHorizontalPS;
			
			RenderTarget = texBlurHorizontal;
		}
		// crt-royale-blend-frames.fxh
		pass scanlineBlendPass
		{
			VertexShader = lerpScanlinesVS;
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
		// crt-royale-phosphor-mask.fxh
		pass phosphorMaskResizeVerticalPass
		{
			VertexShader = maskResizeVertVS;
			PixelShader = maskResizeVertPS;
			
			RenderTarget = texMaskResizeVertical;
		}
		pass phosphorMaskResizeHorizontalPass
		{
			VertexShader = maskResizeHorizVS;
			PixelShader = maskResizeHorizPS;
			
			RenderTarget = texMaskResizeHorizontal;
		}
		pass phosphorMaskPass
		{
			VertexShader = PostProcessVS;
			PixelShader = applyPhosphorMaskPS;
			
			RenderTarget = texMaskedScanlines;
		}
		// crt-royale-brightpass.fxh
		pass brightpassPass
		{
			VertexShader = brightpassVS;
			PixelShader = brightpassPS;
			
			RenderTarget = texBrightpass;
		}
		// crt-royale-bloom-vertical.fxh
		pass bloomVerticalPass
		{
			VertexShader = bloomVerticalVS;
			PixelShader = bloomVerticalPS;
			
			RenderTarget = texBloomVertical;
		}
		// crt-royale-bloom-horizontal-reconstitute.fxh
		pass bloomHorizontalPass
		{
			VertexShader = bloomHorizontalVS;
			PixelShader = bloomHorizontalPS;
			
			RenderTarget = texBloomHorizontal;
		}
		// crt-royale-geometry-aa-last-pass.fxh
		pass geometryPass
		{
			VertexShader = geometryVS;
			PixelShader = geometryPS;

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