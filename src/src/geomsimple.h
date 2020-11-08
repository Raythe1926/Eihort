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

#ifndef GEOMSIMPLE_H
#define GEOMSIMPLE_H

#include <cstdlib>
#include <vector>
#include "jmath.h"
#include "geombase.h"

namespace eihort {
namespace geom {


class SimpleGeometry : public BlockGeometry {
	// Parent BlockGeometry for geometry which follows a more normal
	// render pipeline - vertices are specified with float positions
	// and carry texture uv.

public:
	virtual ~SimpleGeometry();

	virtual void render( void *&meta, RenderContext *ctx );
	virtual GeometryCluster *newCluster();

protected:
	explicit SimpleGeometry();

	// Helper to emit a quad
	static void emitSimpleQuad( GeometryStream *target, const jMatrix *loc, const jMatrix *tex = NULL );
	// Render the geometry
	// To be called by subclasses after setting up the material
	void rawRender( void *&meta, RenderContext *ctx );

	struct Vertex {
		// "Simple" geometry vertex format
		jVec3 pos;
		float u, v;
	};
};

class RailGeometry : public SimpleGeometry {
	// Geometry generator for rail tracks
	// TODO: Optimize this by making it a SolidBlockGeometry

public:
	explicit RailGeometry( unsigned txStraight, unsigned txTurn );
	virtual ~RailGeometry();

	virtual GeometryCluster *newCluster();

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );
	virtual void render( void *&meta, RenderContext *ctx );

private:
	// Texture for straight pieces
	unsigned texStraight;
	// Texture for turning pieces
	unsigned texTurn;
};

class TorchGeometry : public SimpleGeometry {
	// Geometry generator for torches

public:
	explicit TorchGeometry( unsigned tx );
	virtual ~TorchGeometry();

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );
	virtual void render( void *&meta, RenderContext *ctx );

private:
	// Torch texture
	unsigned tex;
};

class XShapedBlockGeometry : public SimpleGeometry {
	// Geometry generator for flowers, saplings, etc.
	// I.e. two quads in an X pattern
	// TODO: Optimize this by making it a SolidBlockGeometry

public:
	explicit XShapedBlockGeometry( unsigned tx );
	virtual ~XShapedBlockGeometry();

	virtual void render( void *&meta, RenderContext *ctx );

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );
	virtual IslandMode beginIsland( IslandDesc *ctx );
	virtual void emitIsland( GeometryCluster *out, const IslandDesc *ctx );

protected:
	// XShapedBlock texture
	unsigned tex;
};

class BiomeXShapedBlockGeometry : public XShapedBlockGeometry {
	// XShapedBlockGeometry that uses the biome shader

public:
	BiomeXShapedBlockGeometry( unsigned tx, unsigned biomeTex );
	virtual ~BiomeXShapedBlockGeometry();

	virtual void render( void *&meta, RenderContext *ctx );

protected:
	// Biome channel to use
	unsigned biomeTex;
};


} // namespace geom
} // namespace eihort

#endif
