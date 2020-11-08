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


#ifndef WORLDMESHBUILDER_H
#define WORLDMESHBUILDER_H

#include <vector>
#include <list>

#include "geombase.h"
#include "mcblockdesc.h"
#include "mcmap.h"

namespace eihort {

class MCBiome;
class WorldMeshSection;
class WorldMesh;

struct Extents {
	// Describes an axis aligned box

	Extents() { }
	Extents( int minx, int maxx, int miny, int maxy, int minz, int maxz )
		: minx(minx), miny(miny), minz(minz), maxx(maxx), maxy(maxy), maxz(maxz) { }

	union {
#ifdef __GNUC__
    __extension__
#endif
		struct {
			// Array-based access to the minima and maxima
			int minv[3], maxv[3];
		};
#ifdef __GNUC__
    __extension__
#endif
		struct {
			// Minimum X, Y, and Z extents
			int minx, miny, minz;
			// Maximum X, Y, and Z extents
			int maxx, maxy, maxz;
		};
	};

	// Intersection test with another Extents
	inline bool intersects( const Extents &o ) const {
		return minx <= o.maxx && maxx >= o.minx
			&& miny <= o.maxy && maxy >= o.miny
			&& minz <= o.maxz && maxz >= o.minz;
	}

	// Test whether a given block is within the extents
	inline bool contains( int x, int y, int z ) const {
		return x >= minx && x <= maxx && y >= miny && y <= maxy && z >= minz && z <= maxz;
	}
};

struct WorldMeshSectionData {
	// Metadata stream
	geom::GeometryStream metaStream;
	// Vertex stream
	geom::GeometryStream vtxStream;
	// Index stream
	geom::GeometryStream idxStream;
	
	// The biome coordinates
	unsigned short *biomeCoords;
	// The biome texture source
	const MCBiome *biomeSrc;
	// The big 3D lighting texture handle
	std::vector<uint8_t> lightingTex;
	// Size of the lighting texture
	int ltSzX, ltSzY, ltSzZ;
	// The scaling for the lighting texture to line up with the
	// world geometry
	double lightTexScale[3];

	// The index of the end of the opaque and transparent
	// geometries in the metadata
	unsigned opaqueEnd, transpEnd;
	// Center of the WorldMesh
	double origin[3];
};

class WorldMeshBuilder {
	// WorldMeshSection construction class

public:
	// Create a new mesh builder
	WorldMeshBuilder( MCMap *map, const MCBlockDesc *blocks );
	~WorldMeshBuilder();

	// Generate geometry for the section of the world within hull
	// pow2Ext must encompass hullExt and have power-of-two sizes in all
	// dimensions (though they can be different)
	void generate( const Extents &hull, const Extents &ltext, WorldMeshSectionData &into );
	// Generate geometry for the section of the world within extents
	// Outputs multiple WorldMeshSectionData's which should weight
	// less than a single WorldMeshSectionData for the whole area
	void generateOptimal( Extents &extents, std::list<WorldMeshSectionData> &into );

private:
	class IslandHole {
		// Helper class to store and manipulate the boundaries of holes in islands

	public:
		IslandHole( bool firstPointVisible )
			: firstBlockIsNonVisible(!firstPointVisible)
		{ }
		~IslandHole() { }

		// Get a point inside the hole
		const geom::Point &insidePoint() const { return inside; }
		// Get a point inside the hole
		geom::Point &insidePoint() { return inside; }
		// Get the vector of blocks which form the corners of the hole
		std::vector< geom::Point > &blocks() { return contourBlocks; }
		// Get the vector of contour points, i.e. the vertices around the hole
		std::vector< geom::Point > &points() { return contourPoints; }
		// Get the vector of blocks which form the corners of the hole
		const std::vector< geom::Point > &blocks() const { return contourBlocks; }
		// Get the vector of contour points, i.e. the vertices around the hole
		const std::vector< geom::Point > &points() const { return contourPoints; }

		// Can the hole be removed?
		// I.e. if the island geometry is extended into the hole, will this matter?
		bool isRemovable() const;

	private:
		// Is the first block of the hole not visible?
		bool firstBlockIsNonVisible;
		// A point inside the hole
		geom::Point inside;
		// The blocks at the corners of the hole
		std::vector< geom::Point > contourBlocks;
		// The vertices of the hole
		std::vector< geom::Point > contourPoints;
	};

	struct GeomAndCluster {
		// The geometry generator
		geom::BlockGeometry *geom;
		// The BlockGeometry's geometry cluster
		geom::GeometryCluster *cluster;

		// For sorting by rendergroup
		inline bool operator<( const GeomAndCluster &other ) const {
			return geom->getRenderGroup() < other.geom->getRenderGroup(); }
	};

	// Redirect area that the internal data structures of this
	// class represents
	void reorient( const Extents &hull, const Extents &ltext );

	// Mark a block face as finished
	// Islands will not be generated from this face
	inline void markDone( const geom::Point &pt, unsigned dir ) {
		markDone( pt.x, pt.y, pt.z, dir ); }
	// Mark a block face as finished
	// Islands will not be generated from this face
	inline void markDone( int x, int y, int z, unsigned dir ) {
		blockInfo[toLinCoord(x,y,z)] |= (unsigned char)(1<<dir); }
	// Is this block face marked as finished?
	inline bool isDone( const geom::Point &pt, unsigned dir ) {
		return isDone( pt.x, pt.y, pt.z, dir ); }
	// Is this block face marked as finished?
	inline bool isDone( int x, int y, int z, unsigned dir ) {
		return 0 != (blockInfo[toLinCoord(x,y,z)] & (1<<dir)); }
	
	// Mark the block face as the edge of an island
	inline void flagEdge( const geom::Point &pt, unsigned dir ) {
		flagEdge( pt.x, pt.y, pt.z, dir ); }
	// Mark the block face as the edge of an island
	inline void flagEdge( int x, int y, int z, unsigned dir ) {
		blockInfo[toLinCoord(x,y,z)] |= 1u << (dir+8); }
	// Is the block face marked as the edge of an island?
	inline unsigned isEdgeFlagged( const geom::Point &pt, unsigned dir ) {
		return isEdgeFlagged( pt.x, pt.y, pt.z, dir ); }
	// Is the block face marked as the edge of an island?
	inline unsigned isEdgeFlagged( int x, int y, int z, unsigned dir ) {
		return blockInfo[toLinCoord(x,y,z)] & (1u << (dir+8)); }

	// Remove the edge flag from all faces of this block
	inline void unflagEdge( const geom::Point &pt ) {
		unflagEdge( pt.x, pt.y, pt.z ); }
	// Remove the edge flag from all faces of this block
	inline void unflagEdge( int x, int y, int z ) {
		blockInfo[toLinCoord(x,y,z)] &= 0xffu; }
	// Is this block face flagged as an island edge or done?
	inline bool isEdgeOrDone( const geom::Point &pt, unsigned islDir, unsigned mvDir ) {
		return isEdgeOrDone( pt.x, pt.y, pt.z, islDir, mvDir ); }
	// Is this block face flagged as an island edge or done?
	inline bool isEdgeOrDone( int x, int y, int z, unsigned islDir, unsigned mvDir ) {
		return 0 != (blockInfo[toLinCoord(x,y,z)] & ((1u<<(mvDir+8)) | (1u<<islDir))); }

	// Create a new hole in the current island
	inline IslandHole *newHole( bool visible ) {
		holes.push_back( IslandHole(visible) );
		return &holes.back(); }
	// Remove all stored holes
	inline void clearHoles() {
		holes.clear(); }
	// Get the current list of holes
	inline std::list< IslandHole > &getHoles() {
		return holes; }

	// Get the geometry cluster for the given block ID
	geom::GeometryCluster *getGeometryCluster( unsigned id );

	// Finds the smallest j such that (1<<j) >= i
	unsigned getPow2( unsigned i );

	// Transforms a point from world space into mesh-local space
	inline void toLocalSpace( geom::Point &pt ) {
		pt.x -= origin[0];
		pt.y -= origin[1];
		pt.z -= origin[2]; }
	// Transforms a vector of points from world space into mesh-local space
	void toLocalSpace( std::vector< geom::Point > &points );
	// Transforms all holes from world space to mesh-local space
	void transformHolesToLocalSpace();
	// Consolidates the contour points of holes into lists of points
	// Resturns the number of holes
	// NOTE: These arrays must be delete[]ed
	unsigned gatherHoleContourPoints( unsigned *&ends, geom::Point *&points, geom::Point *&inside );

	// Set the light value at a particular block
	inline void setLightingAt( int x, int y, int z, unsigned block, unsigned sky ) {
		unsigned i = toLLinCoord(x,y,z) << 1;
		lightingTex[i] = std::max( lightingTex[i], (unsigned char)(block<<4) );
		lightingTex[i+1] = std::max( lightingTex[i+1], (unsigned char)(sky<<4) );
	}

	// Tansform a world-space coordinate into an index into our local data array
	inline unsigned toLinCoord( int x, int y, int z ) {
		return (unsigned)(z-pow2Ext.minz) + ((unsigned)(x-pow2Ext.minx)<<shiftz) + ((unsigned)(y-pow2Ext.miny)<<(shiftz+shiftx)); }
	// Tansform a world-space coordinate into an index into our local lighing array
	inline unsigned toLLinCoord( int x, int y, int z ) {
		// Ordered as we want GL to order the texture
		return (unsigned)(x-pow2Ext.minx) + ((unsigned)(y-pow2Ext.miny)<<shiftx) + ((unsigned)(z-pow2Ext.minz)<<(shifty+shiftx));
	}

	// Move the coordinates in the given direction within the island's plane
	void moveCoordsInDir( int *coords, unsigned dir );
	// Move the coordinates one block in the given direction within the island's plane
	// This version is guaranteed to move one block, whereas moveCoordsInDir can
	// be affected by, e.g. ISLAND_LOCK_*
	void moveCoordsInDir1( int *coords, unsigned dir );
	// Trace the contour of an island
	bool scanContourAndFlag( const geom::Point &start, unsigned startDir, std::vector< geom::Point > &contourBlocks, std::vector< geom::Point > &contourPoints );
	// Searches for holes in an island starting from the given
	// point, and proceeding in the given direction
	void holeScan( const geom::Point &start, unsigned dir );
	// Search for holes in an island
	void searchForHoles( const std::vector< geom::Point > &contourBlocks );
	// Removes the edge flag from all contour blocks
	void unflagContour( const std::vector< geom::Point > &contourBlocks, bool mark = true );
	// Generate islands around the block specified in island
	void generateIslands( geom::BlockGeometry *geom );
	// Highlight a block with light
	void glowAreaAround( int x, int y, int z );
	// Generate the lighting texture for a column of the world
	void lightMapColumn( int x, int y, const MCMap::Column &col, const MCMap::Column *sides );
	// Generate the lighting texture for a column of the world
	void lightMapColumn( int x, int y );
	// Generate the lighting texture for the columns at the edges of this
	// section's lighting extents
	void lightMapEdges();
	// Find and output all sign text in the given extents
	void outputSignsFromMap( int minx, int maxx, int miny, int maxy );

	// The geometry clusters into which to dump all the geometry
	geom::GeometryCluster *geomStreams[BLOCK_ID_COUNT];
	// blockInfo:
	// Bits 0-5: Done flags for each block in each direction
	// Bits 8-11: Edge flags for use during island construction
	unsigned short *blockInfo;
	// Size of the area to generate geometry for
	unsigned sizex, sizey, sizez;
	// Total size, in blocks, of the area to generate geometry for
	unsigned totalSize;
	// Shifts for the power of two above the size in each dimension
	unsigned shiftx, shifty, shiftz;
	// Origin of the area to generate geometry for
	int origin[3];
	// A vector of all ones, used as a substitute for other arrays in
	// several functions
	unsigned short *allOne;

	// The lighting texture to fill in
	unsigned char *lightingTex;
	// Extents of the lighting texture
	Extents pow2Ext;
	// Extents of the are to generate geometry for
	Extents hullExt;

	// The currently-generated island
	geom::IslandDesc island;
	// List of holes in the currently-generated island
	std::list< IslandHole > holes;

	// Geometry generators
	const MCBlockDesc *blockDesc;
	// Source map
	MCMap *map;
};

} // namespace eihort

#endif // MCWORLDMESH_H
