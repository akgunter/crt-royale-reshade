#include "../lib/bind-shader-params.fxh"
#include "../lib/gamma-management.fxh"
#include "../lib/scanline-functions.fxh"

#include "shared-objects.fxh"

void vertexShader0(
    in const uint id : SV_VertexID,

    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0,
    out float interlaced : TEXCOORD1,
    out float2 v_step : TEXCOORD2
) {
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    
    const float2 input_video_size = tex2Dsize(samplerColor);
    
    //  Detect interlacing: 1.0 = true, 0.0 = false.
    interlaced = float(is_interlaced(input_video_size.y));
    v_step = float2(0.0, 1.0 / input_video_size.y);
}

void pixelShader0(
    in const float4 pos : SV_Position,
    in const float2 texcoord : TEXCOORD0,
    in const float interlaced : TEXCOORD1,
    in const float2 v_step : TEXCOORD2,

    out float4 color : SV_Target
) {
    //  Linearize the input based on CRT gamma and bob interlaced fields.
    //  Bobbing ensures we can immediately blur without getting artifacts.
    //  Note: TFF/BFF won't matter for sources that double-weave or similar.
    if(bool(interlace_detect))
    {
        //  Sample the current line and an average of the previous/next line;
        //  tex2D_linearize will decode CRT gamma.  Don't bother branching:
        const float3 curr_line = tex2D_linearize(samplerCrop, texcoord, get_input_gamma()).rgb;
        const float3 last_line = tex2D_linearize(samplerCrop, texcoord - v_step, get_input_gamma()).rgb;
        const float3 next_line = tex2D_linearize(samplerCrop, texcoord + v_step, get_input_gamma()).rgb;
        const float3 interpolated_line = 0.5 * (last_line + next_line);
        //  If we're interlacing, determine which field curr_line is in:
        const float modulus = interlaced + 1.0;
        const float field_offset = fmod(frame_count + interlace_bff, modulus);
        const float curr_line_texel = texcoord.y * tex2Dsize(samplerCrop).y;
        //  Use under_half to fix a rounding bug around exact texel locations.
        const float line_num_last = floor(curr_line_texel - under_half);
        const float wrong_field = fmod(line_num_last + field_offset, modulus);
        //  Select the correct color, and output the result:
        const float3 selected_color = lerp(curr_line, interpolated_line, wrong_field);
        // color = encode_output(float4(selected_color, 1.0), 1.0);
        color = encode_output(float4(selected_color, 1.0), get_intermediate_gamma());
    }
    else
    {
        color = encode_output(tex2D_linearize(samplerCrop, texcoord, get_input_gamma()), get_intermediate_gamma());
    }
}