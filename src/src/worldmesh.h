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


#ifndef WORLDMESH_H
#define WORLDMESH_H

#include <vector>
#include "geombase.h"
#include "mcbiome.h"

namespace eihort {

struct WorldMeshSectionData;

class WorldMeshSection {
	// Generates, manages, and renders the geometry belonging to an axis
	// aligned section of the world

	friend class WorldMesh;

public:
	WorldMeshSection() = delete;
	WorldMeshSection( const WorldMeshSection& ) = delete;
	WorldMeshSection( WorldMeshSection&& ) = delete;
	explicit WorldMeshSection( const WorldMeshSectionData &data );
	~WorldMeshSection();

	// Complete the loading of the mesh (uploads VBOs and textures)
	void finalizeLoad();
	// Is there any geometry in this mesh?
	inline bool isEmpty() const { return meta == NULL; }
	// Get an estimate of the cost of this geometry
	// Used to throttle the re-upload of off-screen geometry when the
	// camera moves quickly so as to minimize chopping
	inline int getCost() { return cost; }
	// Get the video memory used by this geometry
	inline int getGpuMemUse() { return vtxMem+idxMem+texMem; }

	// Render the opaque geometry in this mesh
	void renderOpaque( eihort::geom::RenderContext *ctx );
	// Render the transparent geometry in this mesh
	void renderTransparent( eihort::geom::RenderContext *ctx );

private:
	// Set up the mesh-specific GL state (e.g. lighting textures,
	// vertex transforms)
	void beginRender( eihort::geom::RenderContext *ctx );
	// Undo the damage from beginRender
	void endRender();

	struct MeshMeta {
		// Per-object metadata expected in the metadata stream
		// This is output by the geometry clusters upon finalization
		geom::BlockGeometry *geom;
	};

	// The source of biome textures
	const MCBiome *biomeSrc;
	// The biome texture handles
	unsigned biomeTex[MCBiome::MAX_BIOME_CHANNELS];
	// The big 3D lighting texture handle
	unsigned lightTex;
	// The scaling for the lighting texture to line up with the
	// world geometry
	double lightTexScale[3];

	// The geometry's metadata
	void *meta;

	// The index of the end of the opaque and transparent
	// geometries in the metadata
	unsigned opaqueEnd, transpEnd;
	// The vertex and index buffers
	unsigned vtx_vbo, idx_vbo;
	// Center of the section
	double origin[3];

	// Size in bytes of the vertex buffer, index buffer, and textures
	unsigned vtxMem, idxMem, texMem;
	// Cost of the geometry (see WorldQTree::newMeshAllowance)
	int cost;
};

class WorldMesh {
	// Creates multiple sub-MCWorldMesh objects to completely cover the
	// geometry within an axis-aligned section of the world
	// The mesh object extents are chosen to try to minimize the amount of
	// space taken by the immense lighting textures

public:
	WorldMesh() = delete;
	WorldMesh( const WorldMesh& ) = delete;
	WorldMesh( WorldMesh&& ) = delete;
	explicit WorldMesh( const std::list<WorldMeshSectionData> &data );
	~WorldMesh();

	// Is there any geometry here?
	bool isEmpty() const;
	// Get the cost of this mesh group
	inline int getCost() const { return cost; }
	// Get the amount of video memory used by this mesh group
	inline int getGpuMemUse() const { return vtxMem+idxMem+texMem; }

	// Render the opaque geometry in this mesh group
	void renderOpaque( geom::RenderContext *ctx );
	// Render the opaque geometry in this mesh group
	void renderTransparent( geom::RenderContext *ctx );

private:
	// The sections of the mesh
	WorldMeshSection *sections;
	// Number of sections in this mesh
	size_t nSections;

	// Size in bytes of the vertex buffer, index buffer, and textures
	unsigned vtxMem, idxMem, texMem;
	// Cost of the geometry
	int cost;
};

} // namespace eihort

#endif // MCWORLDMESH_H
