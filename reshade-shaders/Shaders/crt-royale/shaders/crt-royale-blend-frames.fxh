#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/scanline-functions.fxh"


void lerpScanlinesVS(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float2 v_step : TEXCOORD1
) {
    PostProcessVS(id, position, texcoord);

    v_step = float2(0.0, scanline_num_pixels / TEX_FREEZEFRAME_HEIGHT);
}


void lerpScanlinesPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float2 v_step : TEXCOORD1,
    
    out float4 color : SV_Target
) {
    if (enable_interlacing && scanline_deinterlacing_mode == 1) {
        const float cur_scanline_idx = get_curr_scanline_idx(texcoord.y, CONTENT_HEIGHT_INTERNAL);
        const float wrong_field = curr_line_is_wrong_field(cur_scanline_idx);
        
        const float4 cur_line_color = tex2D(samplerBloomHorizontal, texcoord);
        const float4 cur_line_prev_color = tex2D(samplerFreezeFrame, texcoord);

        const float4 avg_color = (cur_line_color + cur_line_prev_color) / 2.0;
        
        const float use_blend_params = float(
            scanline_deinterlacing_mode > 0 && scanline_deinterlacing_mode < 4
        );
        const float blend_strength = scanline_blend_strength * use_blend_params;
        const float base_blend_gamma = lerp(1.0, scanline_blend_gamma, use_blend_params);

        const float4 raw_out_color = lerp(cur_line_color, avg_color, blend_strength);
        color = encode_output(raw_out_color, lerp(1.0, base_blend_gamma, scanline_blend_strength));
    }
    else if (enable_interlacing && scanline_deinterlacing_mode == 2) {
        const float cur_scanline_idx = get_curr_scanline_idx(texcoord.y, CONTENT_HEIGHT_INTERNAL);
        const float2 frame_and_line_field_idx = get_frame_and_line_field_idx(cur_scanline_idx);
        const float wrong_field = curr_line_is_wrong_field(frame_and_line_field_idx);
        const float field_is_odd = fmod(cur_scanline_idx, 2);

        const float use_negative_offset = field_is_odd;
        const float2 raw_offset = lerp(1, -1, use_negative_offset) * v_step;
        const float2 curr_offset = lerp(0, raw_offset, wrong_field);
        const float2 prev_offset = lerp(raw_offset, 0, wrong_field);

        const float4 cur_line_color = tex2D(samplerBloomHorizontal, texcoord + curr_offset);
        const float4 cur_line_prev_color = tex2D(samplerFreezeFrame, texcoord + prev_offset);

        const float4 avg_color = (cur_line_color + cur_line_prev_color) / 2.0;
        const float4 raw_out_color = lerp(cur_line_color, avg_color, wrong_field);
        color = encode_output(raw_out_color, scanline_blend_gamma);
    }
    else {
        color = tex2D(samplerBloomHorizontal, texcoord);
    }
}

void freezeFramePS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    color = tex2D(samplerBloomHorizontal, texcoord);
}