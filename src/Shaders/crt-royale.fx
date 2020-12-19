#include "ReShade.fxh"


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
	#include "crt-royale/shaders/crt-royale-mask-resize-vertical.fxh"
	#include "crt-royale/shaders/crt-royale-mask-resize-horizontal.fxh"
	#include "crt-royale/shaders/crt-royale-scanlines-horizontal-apply-mask.fxh"
	#include "crt-royale/shaders/crt-royale-brightpass.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-vertical.fxh"
	#include "crt-royale/shaders/crt-royale-bloom-horizontal-reconstitute.fxh"
	#include "crt-royale/shaders/crt-royale-geometry-aa-last-pass.fxh"
#else
	#include "crt-royale/shaders/content-box.fxh"
#endif

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

			RenderTarget = texOutput0;
		}
		// crt-royale-scanlines-vertical-interlacing.fxh
		pass p1
		{
			VertexShader = vertexShader1;
			PixelShader = pixelShader1;

			RenderTarget = texOutput1;
		}
		// crt-royale-bloom-approx.fxh
		pass p2
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader2;
			
			RenderTarget = texOutput2;
		}
		// blur9fast-vertical.fxh
		pass p3
		{
			VertexShader = vertexShader3;
			PixelShader = pixelShader3;
			
			RenderTarget = texOutput3;
		}
		// blur9fast-horizontal.fxh
		pass p4
		{
			VertexShader = vertexShader4;
			PixelShader = pixelShader4;
			
			RenderTarget = texOutput4;
		}
		// crt-royale-mask-resize-vertical.fxh
		pass p5
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader5;
			
			RenderTarget = texOutput5;
		}
		// crt-royale-mask-resize-horizontal.fxh
		pass p6
		{
			VertexShader = PostProcessVS;
			PixelShader = pixelShader6;
			
			RenderTarget = texOutput6;
		}
		// crt-royale-scanlines-horizontal-apply-mask.fxh
		pass p7
		{
			VertexShader = vertexShader7;
			PixelShader = pixelShader7;
			
			RenderTarget = texOutput7;
		}
		// crt-royale-brightpass.fxh
		pass p8
		{
			VertexShader = vertexShader8;
			PixelShader = pixelShader8;
			
			RenderTarget = texOutput8;
		}
		// crt-royale-bloom-vertical.fxh
		pass p9
		{
			VertexShader = vertexShader9;
			PixelShader = pixelShader9;
			
			RenderTarget = texOutput9;
		}
		// crt-royale-bloom-horizontal-reconstitute.fxh
		pass p10
		{
			VertexShader = vertexShader10;
			PixelShader = pixelShader10;
			
			RenderTarget = texOutput10;
		}
		// crt-royale-geometry-aa-last-pass.fxh
		pass p11
		{
			VertexShader = vertexShader11;
			PixelShader = pixelShader11;

			RenderTarget = texOutput11;
		}
		// content-crop.fxh
		pass uncrop
		{
			VertexShader = PostProcessVS;
			PixelShader = uncropContentPixelShader;
		}
	#endif
}