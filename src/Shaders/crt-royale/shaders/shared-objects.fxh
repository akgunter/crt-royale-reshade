#ifndef _SHARED_OBJECTS_H
#define _SHARED_OBJECTS_H

#include "../lib/root-level-functions.fxh"
#include "../lib/derived-settings-and-constants.fxh"
#include "../lib/texture-settings.fxh"

#ifndef CONTENT_ASPECT_RATIO_X
	#define CONTENT_ASPECT_RATIO_X 4.0
#endif
#ifndef CONTENT_ASPECT_RATIO_Y
	#define CONTENT_ASPECT_RATIO_Y 3.0
#endif

#ifndef INTERNAL_BUFFER_FORMAT
	// The libretro version uses R8G8B8A8_SRGB.
	// The closest thing ReShade has to this is RGB10A2, but that format has
	// issues with Passes 7 and 8 crushing blacks. RGBA16 is the smallest
	// nonlinear format available that does not have crushing issues.
	// TODO: Figure out which passes can safely use RGB10A2
	#define INTERNAL_BUFFER_FORMAT RGBA16
#endif

static const float CONTENT_WIDTH = root_ceil(BUFFER_HEIGHT * CONTENT_ASPECT_RATIO_X / CONTENT_ASPECT_RATIO_Y);
static const float CONTENT_OFFSET_X = root_clamp((BUFFER_WIDTH - CONTENT_WIDTH) / 2.0 / BUFFER_WIDTH, 0, 0.5);


// Initial Color Buffer
texture2D texColorBuffer : COLOR;
sampler2D samplerColor {
	Texture = texColorBuffer;

	MagFilter = NONE;
	MinFilter = NONE;
	MipFilter = NONE;
};

// Pass 0 Buffer (ORIG_LINEARIZED)
texture2D texOutput0 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = RGB10A2;
};
sampler2D samplerOutput0 { Texture = texOutput0; };

// Pass 1 Buffer  (VERTICAL_SCANLINES)
texture2D texOutput1 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

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
	Height = BUFFER_HEIGHT * mask_resize_viewport_scale.y;
};
sampler2D samplerOutput5 { Texture = texOutput5; };

// Pass 6 Mask Texture (MASK_RESIZE)
texture2D texOutput6 {
	Width = BUFFER_WIDTH * mask_resize_viewport_scale.x;
	Height = BUFFER_HEIGHT * mask_resize_viewport_scale.y;

	// Width = BUFFER_WIDTH;
	// Height = BUFFER_HEIGHT;
};
sampler2D samplerOutput6 { Texture = texOutput6; };

// Pass 7 Buffer (MASKED_SCANLINES)
texture2D texOutput7 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput7 { Texture = texOutput7; };

// Pass 8 Buffer (BRIGHTPASS)
texture2D texOutput8 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput8 { Texture = texOutput8; };

// Pass 9 Buffer
texture2D texOutput9 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput9 { Texture = texOutput9; };

// Pass 10 Buffer
texture2D texOutput10 {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = RGBA16;
};
sampler2D samplerOutput10 { Texture = texOutput10; };


uniform int frame_count < source = "framecount"; >;

#endif  // _SHARED_OBJECTS_H