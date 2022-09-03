#ifndef _TEXTURE_SETTINGS
#define _TEXTURE_SETTINGS

/////////////////////////////////  MIT LICENSE  ////////////////////////////////
//  Copyright (C) 2020 Alex Gunter
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#include "bind-shader-params.fxh"


#define mask_texture_wrap_mode REPEAT
#define mask_texture_magmin_filter_type LINEAR

#if USE_LARGE_PHOSPHOR_MASK == 1
	#define mask_grille_texture_path "crt-royale/TileableLinearApertureGrille15Wide8And5d5Spacing.png"
	#define mask_slot_texture_path "crt-royale/TileableLinearSlotMaskTall15Wide9And4d5Horizontal9d14VerticalSpacing.png"
	#define mask_shadow_texture_path "crt-royale/TileableLinearShadowMaskEDP.png"
	#define mask_size_xy 512
	#define mask_texture_mip_filter_type LINEAR
#else
	#define mask_grille_texture_path "crt-royale/TileableLinearApertureGrille15Wide8And5d5SpacingResizeTo64.png"
	#define mask_slot_texture_path "crt-royale/TileableLinearSlotMaskTall15Wide9And4d5Horizontal9d14VerticalSpacingResizeTo64.png"
	#define mask_shadow_texture_path "crt-royale/TileableLinearShadowMaskEDPResizeTo64.png"
	#define mask_size_xy 64
	#define mask_texture_mip_filter_type NONE
#endif

static const float2 mask_size = float2(mask_size_xy, mask_size_xy);

#if __RENDERER__ != 0x9000 && USE_PHOSPHOR_TEXTURES == 1
	texture2D texMaskGrille < source = mask_grille_texture_path; > {
		Width = mask_size.x;
		Height = mask_size.y;
	};
	sampler2D samplerMaskGrille {
		Texture = texMaskGrille;

		AddressU = mask_texture_wrap_mode;
		AddressV = mask_texture_wrap_mode;
		AddressW = mask_texture_wrap_mode;
		
		MagFilter = mask_texture_magmin_filter_type;
		MinFilter = mask_texture_magmin_filter_type;
		MipFilter = mask_texture_mip_filter_type;
	};

	texture2D texMaskSlot < source = mask_slot_texture_path; > {
		Width = mask_size.x;
		Height = mask_size.y;
	};
	sampler2D samplerMaskSlot {
		Texture = texMaskSlot;

		AddressU = mask_texture_wrap_mode;
		AddressV = mask_texture_wrap_mode;
		AddressW = mask_texture_wrap_mode;
		
		MagFilter = mask_texture_magmin_filter_type;
		MinFilter = mask_texture_magmin_filter_type;
		MipFilter = mask_texture_mip_filter_type;
	};

	texture2D texMaskShadow < source = mask_shadow_texture_path; > {
		Width = mask_size.x;
		Height = mask_size.y;
	};
	sampler2D samplerMaskShadow {
		Texture = texMaskShadow;

		AddressU = mask_texture_wrap_mode;
		AddressV = mask_texture_wrap_mode;
		AddressW = mask_texture_wrap_mode;
		
		MagFilter = mask_texture_magmin_filter_type;
		MinFilter = mask_texture_magmin_filter_type;
		MipFilter = mask_texture_mip_filter_type;
	};
#elif USE_PHOSPHOR_TEXTURES == 1
	// Use preprocessor sorcery to drop all three textures to one
	//   without having to refactor the entire phosphor codebase
	#if phosphor_mask_type == 0
		#define source_path mask_grille_texture_path
	#elif phosphor_mask_type == 1
		#define source_path mask_slot_texture_path
	#else
		#define source_path mask_shadow_texture_path
	#endif

	texture2D texPhosphorMask < source = source_path; > {
		Width = mask_size.x;
		Height = mask_size.y;
	};
	sampler2D samplerPhosphorMask {
		Texture = texPhosphorMask;

		AddressU = mask_texture_wrap_mode;
		AddressV = mask_texture_wrap_mode;
		AddressW = mask_texture_wrap_mode;
		
		MagFilter = mask_texture_magmin_filter_type;
		MinFilter = mask_texture_magmin_filter_type;
		MipFilter = mask_texture_mip_filter_type;
	};

	#define texMaskGrille texPhosphorMask
	#define samplerMaskGrille samplerPhosphorMask
	#define texMaskSlot texPhosphorMask
	#define samplerMaskSlot samplerPhosphorMask
	#define texMaskShadow texPhosphorMask
	#define samplerMaskShadow samplerPhosphorMask
#endif

#endif  // _TEXTURE_SETTINGS