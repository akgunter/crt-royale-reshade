#include "ReShade.fxh"

static const float bloom_approx_scale_x = 4.0 / 3.0;
static const float max_viewport_size_x = 1080.0*1024.0*(4.0/3.0);
static const float bloom_diff_thresh_ = 1.0/256.0;

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


void identityPS0(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerColor, texcoord);
}
void identityPS1(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput0, texcoord);
}
void identityPS2(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput1, texcoord);
}
void identityPS3(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput2, texcoord);
}
void identityPS4(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput3, texcoord);
}
void identityPS5(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput4, texcoord);
}
void identityPS6(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput5, texcoord);
}
void identityPS7(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput6, texcoord);
}
void identityPS8(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput7, texcoord);
}
void identityPS9(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput8, texcoord);
}

void identityPS10(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput9, texcoord);
}
void identityPS11(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	color = tex2D(samplerOutput10, texcoord);
}

#ifndef CRT_DEBUG_USE_MASK
	#define CRT_DEBUG_USE_MASK true
#endif

void whitePS6(
    float4 pos : SV_Position,
    float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
	if (CRT_DEBUG_USE_MASK) {
		pixelShader6(pos, texcoord, color);
	}
	else {
		static const float c = 1.0 / get_mask_amplify();
		color = float4(c, c, c, 1.0);
	}
}


technique CRT_Royale
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
		
		// RenderTarget = texOutput9;
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