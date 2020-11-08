/* Copyright (c) 2012, Jason Lloyd-Price
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

#ifndef MCBIOME_H
#define MCBIOME_H

#include <string>

struct SDL_Surface;

namespace eihort {

class MCMap;

class MCBiome {
	// Manages biome textures
	// Textures are organized into biome "channels", which can be referenced by the
	// Biome* geometries.

public:
	MCBiome();
	~MCBiome();

	enum{ MAX_BIOME_CHANNELS = 8 };

	// Set the root path in which to search for MCRegion-style biome information
	inline void setBiomeRootPath( const char *s ) { biomePath = s; }
	// Get the biome root path
	inline const char *getBiomeRootPath() const { return biomePath.c_str(); }

	// Disable the biome channel
	void disableBiomeChannel( unsigned channel, unsigned color );
	// Enable the biome channel, using surf as the color mapping
	void enableBiomeChannel( unsigned channel, SDL_Surface *surf, bool upperTriangle );
	// Set the position in the biome texture to use if the true position is unknown
	inline void setDefaultPos( unsigned short pos ) { defPos = pos; }

	// Create GL textures for a given region of the world
	// Returns the size in bytes of the textures
	// textures must be large enough to hold textures for all enabled biome channels
	unsigned finalizeBiomeTextures( unsigned short *coords, unsigned w, unsigned h, unsigned *textures ) const;
	// Free GL textures created with finalizeBiomeTextures
	void freeBiomeTextures( unsigned *textures ) const;

	// Reads biome coordinates for a region of the world
	// Returns NULL if no coordinates are available
	// Otherwise, returns a pointer which should be passed to finalizeBiomeTextures
	unsigned short *readBiomeCoords( MCMap *map, int minx, int maxx, int miny, int maxy ) const;

private:
	// Clears any resources associated with a channel
	void emptyChannel( unsigned channel );
	// MCRegion biome coordinate reader
	bool readBiomeCoords_extracted( int minx, int maxx, int miny, int maxy, unsigned short *dest ) const;
	// Anvil biome coordinate reader
	bool readBiomeCoords_anvil( MCMap *map, int minx, int maxx, int miny, int maxy, unsigned short *dest ) const;
	// Translate biome coordinates to a color texture
	unsigned coordsToTexture( unsigned w, unsigned h, unsigned len, unsigned *colours, unsigned short *coords ) const;

	struct BiomeChannel {
		// Textures will only be generated for enabled channels
		bool enabled;
		// Marks that this channel uses the upper right triangle of the biome texture
		bool upperTriangle;
		// GL texture with just the default colour
		unsigned defTex;
		// Colour mapping
		SDL_Surface *colours;
	};
	// Default texture coordinate
	unsigned short defPos;
	// Number of enabled biome channels
	unsigned enabled;
	// The biome channels
	BiomeChannel channels[MAX_BIOME_CHANNELS];
	// Root path to search for biome information in (MCRegion only)
	std::string biomePath;
};

} // namespace eihort

#endif // MCBIOME_H
