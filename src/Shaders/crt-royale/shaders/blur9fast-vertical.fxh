#include "../lib/gamma-management-new.fxh"
#include "../lib/blur-functions.fxh"

#include "shared-objects.fxh"

void vertexShader3(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 blur_dxdy : TEXCOORD1
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    //  Get the uv sample distance between output pixels.  Blurs are not generic
    //  Gaussian resizers, and correct blurs require:
    //  1.) OutputSize == InputSize * 2^m, where m is an integer <= 0.
    //  2.) mipmap_inputN = "true" for this pass in the preset if m != 0
    //  3.) filter_linearN = "true" except for 1x scale nearest neighbor blurs
    //  Gaussian resizers would upsize using the distance between input texels
    //  (not output pixels), but we avoid this and consistently blur at the
    //  destination size.  Otherwise, combining statically calculated weights
    //  with bilinear sample exploitation would result in terrible artifacts.
    static const float2 output_size = tex2Dsize(samplerOutput3);
    static const float2 dxdy = 1.0 / output_size;
    //  This blur is vertical-only, so zero out the horizontal offset:
    blur_dxdy = float2(0.0, dxdy.y);
}

void pixelShader3(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 blur_dxdy : TEXCOORD1,

    out float4 color : SV_Target
) {
    static const float3 blur_color = tex2Dblur9fast(samplerOutput2, texcoord, blur_dxdy, 1.0);
    //  Encode and output the blurred image:
    // color = encode_output(float4(blur_color, 1.0), 1.0);
    color = float4(blur_color, 1.0);
}