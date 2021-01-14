#include "../lib/user-settings.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/scanline-functions.fxh"

void lerpScanlinesPS(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    if (enable_interlacing) {
        /*
        if (texcoord.x < 0.5) {
            color = tex2D(samplerBloomHorizontal, texcoord);
        }
        else {
            color = tex2D(samplerFreezeFrame, texcoord);
        }
        */
        const float cur_scanline_idx = get_cur_scanline_idx(texcoord.y, CONTENT_HEIGHT_INTERNAL);
        const float wrong_field = cur_line_is_wrong_field(cur_scanline_idx);

        // const float4 cur_line_color = tex2D_linearize(samplerBloomHorizontal, texcoord, get_intermediate_gamma());
        // const float4 cur_line_prev_color = tex2D_linearize(samplerFreezeFrame, texcoord, get_intermediate_gamma());
        const float4 cur_line_color = tex2D(samplerBloomHorizontal, texcoord);
        const float4 cur_line_prev_color = tex2D(samplerFreezeFrame, texcoord);

        // const float4 prev_weight = cur_line_prev_color;
        const float4 avg_color = (cur_line_color + cur_line_prev_color) / 2.0;
        const float s = wrong_field ? 1 : -1;
        const float4 color_dev = abs(cur_line_color - avg_color);
        const float4 delta_c = s * (1 - scanline_blend_strength) * color_dev;
        // color = encode_output(avg_color + delta_c, get_intermediate_gamma());
        color = avg_color + delta_c;

        /*
        const float field_offset = cur_scanline_idx % 2 == 0 ? 1 : -1;
        const float dy = field_offset * float(scanline_num_pixels) / float(CONTENT_HEIGHT_INTERNAL);
        const float2 sibling_line_coord = float2(texcoord.x, texcoord.y + dy);
        const float4 sibling_line_color = tex2D_linearize(samplerMaskedScanlines, sibling_line_coord, get_intermediate_gamma());

        const float4 avg_color = (cur_line_color + sibling_line_color) / 2.0;

        const float s = wrong_field == 1 ? 1 : -1;
        const float4 color_dev = abs(cur_line_color - avg_color);
        const float4 delta_c = s * scanline_blend_strength * color_dev;

        color = encode_output(cur_line_color + delta_c, get_intermediate_gamma());
        */
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