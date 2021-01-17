#include "../lib/bind-shader-params.fxh"
#include "../lib/scanline-functions.fxh"

#include "shared-objects.fxh"


void vertexShader1(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 il_step_multiple : TEXCOORD1,
    out float2 uv_step : TEXCOORD2,
    out float pixel_height_in_scanlines : TEXCOORD3
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

    //  Detect interlacing: il_step_multiple indicates the step multiple between
    //  lines: 1 is for progressive sources, and 2 is for interlaced sources.
    const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
    const float y_step = enable_interlacing == 1 ? 2 * scanline_num_pixels : 1.0;

    il_step_multiple = float2(1.0, y_step);
    //  Get the uv tex coords step between one texel (x) and scanline (y):
    uv_step = il_step_multiple / orig_linearized_size;
    
    //  We need the pixel height in scanlines for antialiased/integral sampling:
    const float m = enable_interlacing == 1 ? il_step_multiple.y * scanline_num_pixels : 1.0;
    pixel_height_in_scanlines = (orig_linearized_size.y / TEX_VERTICALSCANLINES_SIZE.y) / m;
    // pixel_height_in_scanlines = 1.0 / il_step_multiple.y;
}


void pixelShader1(
    in const float4 position : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 il_step_multiple : TEXCOORD1,
    in const float2 uv_step : TEXCOORD2,
    in const float pixel_height_in_scanlines : TEXCOORD3,
    
    out float4 color : SV_Target
) {
    //  This pass: Sample multiple (misconverged?) scanlines to the final
    //  vertical resolution.  Temporarily auto-dim the output to avoid clipping.

    //  Read some attributes into local variables:
    const float2 orig_linearized_size = tex2Dsize(samplerOrigLinearized);
    const float2 orig_linearized_size_inv = 1.0/orig_linearized_size;

    // rename for ease of use
    const float ph = pixel_height_in_scanlines;
    
    //  Calculate {sigma, shape}_range outside of scanline_contrib so it's only
    //  done once per pixel (not 6 times) with runtime params.  Don't reuse the
    //  vertex shader calculations, so static versions can be constant-folded.
    const float sigma_range = max(beam_max_sigma, beam_min_sigma) - beam_min_sigma;
    const float shape_range = max(beam_max_shape, beam_min_shape) - beam_min_shape;

    const float3 convergence_offsets_y = beam_misconvergence ? get_convergence_offsets_y_vector() : float3(0, 0, 0);
    const float2 curr_texel = get_curr_texel(texcoord, orig_linearized_size, 0);

    float2 frame_and_line_field_idx;
    float wrong_field;
    float sample_dist;
    float3 beam_dist;
    float2 scanline_uv;
    get_scanline_base_params(texcoord.y, orig_linearized_size.y,
        frame_and_line_field_idx, wrong_field
    );
    get_scanline_sample_params(texcoord, orig_linearized_size,
        frame_and_line_field_idx, wrong_field, convergence_offsets_y,
        sample_dist, beam_dist, scanline_uv
    );

    //  Consider 2, 3, 4, or 6 scanlines numbered 0-5: The previous and next
    //  scanlines are numbered 2 and 3.  Get scanline colors colors (ignore
    //  horizontal sampling, since since output_size.x = video_size.x).
    //  NOTE: Anisotropic filtering creates interlacing artifacts, which is why
    //  ORIG_LINEARIZED bobbed any interlaced input before this pass.
    const float2 v_step = float2(0.0, scanline_num_pixels * orig_linearized_size_inv.y);
    const float correct_field = 1 - wrong_field;

    // const float3 scanline_n3_color = tex2D_linearize(samplerOrigLinearized, texcoord - 3*v_step, get_intermediate_gamma()).rgb * wrong_field;
    const float3 scanline_n2_color = tex2D_linearize(samplerOrigLinearized, texcoord - 2*v_step, get_intermediate_gamma()).rgb * correct_field;
    // const float3 scanline_n1_color = tex2D_linearize(samplerOrigLinearized, texcoord - v_step, get_intermediate_gamma()).rgb * wrong_field;
    const float3 scanline_0_color = tex2D_linearize(samplerOrigLinearized, texcoord, get_intermediate_gamma()).rgb * correct_field;
    // const float3 scanline_p1_color = tex2D_linearize(samplerOrigLinearized, texcoord + v_step, get_intermediate_gamma()).rgb * wrong_field;
    const float3 scanline_p2_color = tex2D_linearize(samplerOrigLinearized, texcoord + 2*v_step, get_intermediate_gamma()).rgb * correct_field;
    // const float3 scanline_p3_color = tex2D_linearize(samplerOrigLinearized, texcoord + 3*v_step, get_intermediate_gamma()).rgb * wrong_field;


    // const float dist_round = round(sample_dist - 0.25);
    const float2 texel_0 = get_curr_texel(texcoord, orig_linearized_size, 0);

    const float scanline_0_idx = get_curr_scanline_idx(texcoord.y, orig_linearized_size.y);
    const float3 beam_center = get_beam_center(scanline_0_idx, frame_and_line_field_idx.x) - convergence_offsets_y * scanline_num_pixels;

    const float3 beam_dist_n2 = get_dist_from_beam(texel_0.y - 2*scanline_num_pixels, beam_center);
    // const float3 beam_dist_n1 = get_dist_from_beam(texel_0.y - scanline_num_pixels, beam_center);
    const float3 beam_dist_0 = get_dist_from_beam(texel_0.y, beam_center);
    // const float3 beam_dist_p1 = get_dist_from_beam(texel_0.y + scanline_num_pixels, beam_center);
    const float3 beam_dist_p2 = get_dist_from_beam(texel_0.y + 2*scanline_num_pixels, beam_center);

    const float3 scanline_n2_contrib = get_beam_strength(
        beam_dist_n2,
        scanline_n2_color, sigma_range, shape_range
    );
    // const float3 scanline_n1_contrib = get_beam_strength(
    //     beam_dist_n1,
    //     scanline_n1_color, sigma_range, shape_range
    // );
    const float3 scanline_0_contrib = get_beam_strength(
        beam_dist_0,
        scanline_0_color, sigma_range, shape_range
    );
    // const float3 scanline_p1_contrib = get_beam_strength(
    //     beam_dist_p1,
    //     scanline_p1_color, sigma_range, shape_range
    // );
    const float3 scanline_p2_contrib = get_beam_strength(
        beam_dist_p2,
        scanline_p2_color, sigma_range, shape_range
    );

    float3 scanline_intensity = scanline_0_color;
    scanline_intensity += scanline_n2_contrib;
    scanline_intensity += scanline_p2_contrib;

    color = encode_output(float4(scanline_intensity, 1.0), get_intermediate_gamma());
}