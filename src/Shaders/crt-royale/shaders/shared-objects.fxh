#ifndef _SHARED_OBJECTS_H
#define _SHARED_OBJECTS_H

#include "../lib/root-level-functions.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/texture-settings.fxh"

// The width of the game's content
#ifndef CONTENT_WIDTH
	#define CONTENT_WIDTH BUFFER_WIDTH
#endif
// The height of the game's content
#ifndef CONTENT_HEIGHT
	#define CONTENT_HEIGHT BUFFER_HEIGHT
#endif

// Offset the center of the game's content (horizontal)
#ifndef CONTENT_CENTER_X
	#define CONTENT_CENTER_X 0
#endif
// Offset the center of the game's content (vertical)
#ifndef CONTENT_CENTER_Y
	#define CONTENT_CENTER_Y 0
#endif

static const float2 buffer_size = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
static const float2 content_size = float2(CONTENT_WIDTH, CONTENT_HEIGHT);
static const float pixel_dx = 1.0 / BUFFER_WIDTH;
static const float pixel_dy = 1.0 / BUFFER_HEIGHT;
static const float content_center_x = CONTENT_CENTER_X * pixel_dx + 0.5;
static const float content_center_y = CONTENT_CENTER_Y * pixel_dy + 0.5;
static const float content_radius_x = CONTENT_WIDTH * pixel_dx / 2.0;
static const float content_radius_y = CONTENT_HEIGHT * pixel_dy / 2.0;


// Initial Color Buffer
texture2D texColorBuffer : COLOR;
sampler2D samplerColor {
	Texture = texColorBuffer;

	MagFilter = NONE;
	MinFilter = NONE;
	MipFilter = NONE;
};

// Crop pass
texture2D texCrop {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
};
sampler2D samplerCrop { Texture = texCrop; };

// Pass 0 Buffer (ORIG_LINEARIZED)
texture2D texOutput0 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGB10A2;
};
sampler2D samplerOutput0 { Texture = texOutput0; };

// Pass 1 Buffer  (VERTICAL_SCANLINES)
texture2D texOutput1 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGB10A2;
};
sampler2D samplerOutput1 { Texture = texOutput1; };

static const int intermediate_buffer_x = 320;
static const int intermediate_buffer_y = 240;


// Pass 2 Buffer (BLOOM_APPROX)
texture2D texOutput2 {
	Width = intermediate_buffer_x;
	Height = intermediate_buffer_y;

	Format = RGB10A2;
};
sampler2D samplerOutput2 { Texture = texOutput2; };

// Pass 3 Buffer
texture2D texOutput3 {
	Width = intermediate_buffer_x;
	Height = intermediate_buffer_y;

	Format = RGB10A2;
};
sampler2D samplerOutput3 { Texture = texOutput3; };

// Pass 4 Buffer (HALATION_BLUR)
texture2D texOutput4 {
	Width = intermediate_buffer_x;
	Height = intermediate_buffer_y;

	Format = RGB10A2;
};
sampler2D samplerOutput4 { Texture = texOutput4; };

// Pass 5 Mask Texture
texture2D texOutput5 {
	Width = 64;
	Height = CONTENT_HEIGHT * mask_resize_viewport_scale.y;
};
sampler2D samplerOutput5 { Texture = texOutput5; };

// Pass 6 Mask Texture (MASK_RESIZE)
texture2D texOutput6 {
	Width = CONTENT_WIDTH * mask_resize_viewport_scale.x;
	Height = CONTENT_HEIGHT * mask_resize_viewport_scale.y;
};
sampler2D samplerOutput6 { Texture = texOutput6; };

// Pass 7 Buffer (MASKED_SCANLINES)
texture2D texOutput7 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput7 { Texture = texOutput7; };

// Pass 8 Buffer (BRIGHTPASS)
texture2D texOutput8 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput8 { Texture = texOutput8; };

// Pass 9 Buffer
texture2D texOutput9 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput9 { Texture = texOutput9; };

// Pass 10 Buffer
texture2D texOutput10 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput10 { Texture = texOutput10; };

// Pass 11 Buffer
texture2D texOutput11 {
	Width = CONTENT_WIDTH;
	Height = CONTENT_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput11 { Texture = texOutput11; };

uniform int frame_count < source = "framecount"; >;

#endif  // _SHARED_OBJECTS_H