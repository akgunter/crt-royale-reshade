#include "ReShade.fxh"

static const float bloom_approx_scale_x = 4.0 / 3.0;
static const float max_viewport_size_x = 1080.0*1024.0*(4.0/3.0);
static const float bloom_diff_thresh_ = 1.0/256.0;

#include "shaders/crt-royale-first-pass-linearize-crt-gamma-bob-fields.fxh"
#include "shaders/crt-royale-scanlines-vertical-interlacing.fxh"
#include "shaders/crt-royale-bloom-approx.fxh"
#include "shaders/blur9fast-vertical.fxh"
#include "shaders/blur9fast-horizontal.fxh"
#include "shaders/crt-royale-mask-resize-vertical.fxh"
#include "shaders/crt-royale-mask-resize-horizontal.fxh"
#include "shaders/crt-royale-scanlines-horizontal-apply-mask.fxh"
#include "shaders/crt-royale-brightpass.fxh"
#include "shaders/crt-royale-bloom-vertical.fxh"
#include "shaders/crt-royale-bloom-horizontal-reconstitute.fxh"
#include "shaders/crt-royale-geometry-aa-last-pass.fxh"


#ifndef BANDS
	#define BANDS 20
#endif
#ifndef A_SRGB_WRITE_ENABLE
	#define A_SRGB_WRITE_ENABLE false
#endif
#ifndef A_DO_GAMMA_ENCODE
	#define A_DO_GAMMA_ENCODE true
#endif

void ExampleVS(
	uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}

void identityPS4(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput3, texcoord);
}

technique DemoMulBug
{
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
	}
}