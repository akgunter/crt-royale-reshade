#include "shared-objects.fxh"


static const float2 offset = (buffer_size - content_size) / (2.0 * buffer_size);

static const float content_left = content_center_x - content_radius_y;
static const float content_right = content_center_x + content_radius_y;
static const float content_upper = content_center_y - content_radius_y;
static const float content_lower = content_center_y + content_radius_y;

void cropContentPixelShader(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 texcoord_cropped = texcoord * content_size / buffer_size + offset;
    color = tex2D(samplerColor, texcoord_cropped);
}

void uncropContentPixelShader(
    in float4 pos : SV_Position,
    in float2 texcoord : TEXCOORD0,

    out float4 color : SV_Target
) {
    const float2 texcoord_uncropped = (texcoord - offset) * buffer_size / content_size;
    const bool is_in_boundary = (
        texcoord_uncropped.x >= content_left && texcoord_uncropped.x <= content_right &&
        texcoord_uncropped.y >= content_upper && texcoord_uncropped.y <= content_lower
    );

    if (is_in_boundary) color = tex2D(samplerOutput11, texcoord_uncropped);
    else color = float4(0, 0, 0, 1);
}