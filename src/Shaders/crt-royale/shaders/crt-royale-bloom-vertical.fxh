
#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management-new.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/bloom-functions.fxh"

void vertexShader9(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 bloom_dxdy : TEXCOORD1,
    out float bloom_sigma_runtime : TEXCOORD2
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
   
    float2 input_size = tex2Dsize(samplerOutput8);
    float2 output_size =  tex2Dsize(samplerOutput9);

	//  Get the uv sample distance between output pixels.  Calculate dxdy like
    //  blurs/vertex-shader-blur-fast-vertical.h.
    const float2 dxdy = 1 / output_size;
    //  This blur is vertical-only, so zero out the vertical offset:
    bloom_dxdy = float2(0.0, dxdy.y);

    //  Calculate a runtime bloom_sigma in case it's needed:
    const float2 estimated_viewport_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    const float2 estimated_mask_resize_output_size = tex2Dsize(samplerOutput6);
    const float mask_tile_size_x = get_resized_mask_tile_size(estimated_viewport_size, estimated_mask_resize_output_size, true).x;

    bloom_sigma_runtime = get_min_sigma_to_blur_triad(
        mask_tile_size_x / mask_triads_per_tile, bloom_diff_thresh_);
}


void pixelShader9(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 bloom_dxdy : TEXCOORD1,
    in const float bloom_sigma_runtime : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Blur the brightpass horizontally with a 9/17/25/43x blur:
    const float bloom_sigma = get_final_bloom_sigma(bloom_sigma_runtime);
    const float3 color3 = tex2DblurNfast(samplerOutput8, texcoord,
        bloom_dxdy, bloom_sigma, 1.0);

    //  Encode and output the blurred image:
    color = float4(color3, 1.0);
}