
#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/phosphor-mask-resizing.fxh"
#include "../lib/scanline-functions.fxh"
#include "../lib/bloom-functions.fxh"

void vertexShader10(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 bloom_dxdy : TEXCOORD1,
    out float bloom_sigma_runtime : TEXCOORD2
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    const float2 input_size = tex2Dsize(samplerOutput9);

    //  We're horizontally blurring the bloom input (vertically blurred
    //  brightpass).  Get the uv distance between output pixels / input texels
    //  in the horizontal direction (this pass must NOT resize):
    bloom_dxdy = float2(1.0/input_size.x, 0.0);

    //  Calculate a runtime bloom_sigma in case it's needed:
    const float2 estimated_viewport_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    const float2 estimated_mask_resize_output_size = tex2Dsize(samplerOutput6);
    const float mask_tile_size_x = get_resized_mask_tile_size(
        estimated_viewport_size, estimated_mask_resize_output_size, true).x;

    bloom_sigma_runtime = get_min_sigma_to_blur_triad(
        mask_tile_size_x / mask_triads_per_tile, bloom_diff_thresh_);
}

void pixelShader10(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 bloom_dxdy : TEXCOORD1,
    in const float bloom_sigma_runtime : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Blur the vertically blurred brightpass horizontally by 9/17/25/43x:
    const float bloom_sigma = get_final_bloom_sigma(bloom_sigma_runtime);
    const float3 blurred_brightpass = tex2DblurNfast(samplerOutput9,
        texcoord, bloom_dxdy, bloom_sigma, get_intermediate_gamma());

    //  Sample the masked scanlines.  Alpha contains the auto-dim factor:
    const float3 intensity_dim = tex2D_linearize(samplerOutput7, texcoord, get_intermediate_gamma()).rgb;
    const float auto_dim_factor = levels_autodim_temp;
    const float undim_factor = 1.0/auto_dim_factor;

    //  Calculate the mask dimpass, add it to the blurred brightpass, and
    //  undim (from scanline auto-dim) and amplify (from mask dim) the result:
    const float mask_amplify = get_mask_amplify();
    const float3 brightpass = tex2D_linearize(samplerOutput8, texcoord, get_intermediate_gamma()).rgb;
    const float3 dimpass = intensity_dim - brightpass;
    const float3 phosphor_bloom = (dimpass + blurred_brightpass) *
        mask_amplify * undim_factor * levels_contrast;

    //  Sample the halation texture, and let some light bleed into refractive
    //  diffusion.  Conceptually this occurs before the phosphor bloom, but
    //  adding it in earlier passes causes black crush in the diffusion colors.
    const float3 diffusion_color = levels_contrast * tex2D_linearize(samplerOutput4, texcoord, get_intermediate_gamma()).rgb;
    const float3 final_bloom = lerp(phosphor_bloom, diffusion_color, diffusion_weight);

    //  Encode and output the bloomed image:
    color = encode_output(float4(final_bloom, 1.0), get_intermediate_gamma());
}