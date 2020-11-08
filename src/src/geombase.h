/* Copyright (c) 2015, Jason Lloyd-Price
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

#ifndef GEOMBASE_H
#define GEOMBASE_H

#include <cfloat>
#include <cstdlib>
#include <vector>
#include "jmath.h"
#include "luaobject.h"

struct triangulateio;
namespace eihort {
class EihortShader;
class LightModel;
}

// Lua metatable name
#define BLOCKGEOMETRY_META "BlockGeometry"

/*
The main geometry processing pipeline is in mcworldmesh. However, at several
points in the pipeline, there are opportunities for per-block-type code to
execute. This code is contained in the many subclasses of BlockGeometry,
which can be found here.
*/

namespace eihort {
namespace geom {

class BlockGeometry;

// ===========================================================================
// Main intermediate map structures used during geometry generation
// These structures are generally constructed in mcworldmesh, and then
// passed to the specific BlockGeometry.

struct Point {
	// An integer-addressed point in space
	union {
#ifdef __GNUC__
    __extension__
#endif
		struct {
			int x, y, z;
		};
		int v[3];
	};

	inline bool operator==( const Point& other ) const {
		return x==other.x && y==other.y && z==other.z;
	}
	inline bool operator!=( const Point& other ) const {
		return !(*this == other);
	}
};

struct BlockData {
	// Information about a specific block in space
	
	// The block's position
	Point pos;
	// The block's ID
	unsigned short id;
	// The block's associated data
	unsigned short data;
};

struct SideContext {
	// Information about a block adjacent to a given block

	// The id of the adjacent block
	unsigned short id;
	// Is the adjacent block solid?
	bool solid;
	// true iff the space is outside the current island-starting area
	bool outside;
};

struct InstanceContext {
	// Local information about a block

	// Info about the block itself
	BlockData block;
	// What is beside the block?
	SideContext sides[6];
	// HACK to pass information in this structure. Used by:
	//  - ForwardingMultiGeometryAdapter
	unsigned cookie;
};

struct RenderContext {
	// Global information when rendering

	// Current view position
	jVec3 viewPos;
	// Currently rendered triangle count
	unsigned renderedTriCount;
	// Current number of bytes used in render calls this frame
	unsigned vertexSize, indexSize, texSize;
	// Global shader object
	EihortShader *shader;
	// Biome textures of the current qtree chunk
	unsigned *biomeTextures;
	// Global lighting model object
	LightModel *lightModels;
	// Is block lighting enabled?
	bool enableBlockLighting;
};

class GeometryCluster;
struct IslandDesc {
	// Intermediate structure used in island generation

	// Point where island generation originated
	InstanceContext origin;
	// Positions of contour blocks describing the island's extrema
	// Contour blocks mark the corners of the island
	Point *contourBlocks;
	// Number of contour blocks describing the island's extrema
	unsigned nContourBlocks;
	// Points describing the contour of the island
	// These points correspond to the vertices describing the island's outer contour
	Point *contourPoints;
	// Number of points describing the contour of the island
	unsigned nContourPoints;
	// Number of holes in the island
	unsigned nHoles;
	// A block for each hole, which is inside that hole
	Point *holeInsidePoint;
	// Points describing the inner contour of each hole
	// The i'th hole uses points holeContourEnd[i-1] until holeContourEnd[i]
	// (with holeContourEnd[-1] == 0)
	Point *holeContourPoints;
	// Endpoints for the stretches of holeContourPoints which belong to each hole
	unsigned *holeContourEnd;

	// The axis of the island's normal
	// Ordered as X-, X+, Y-, Y+, Z-, Z+ (in Eihort's coordinate scheme)
	unsigned islandAxis;
	// Island index
	// Used for ISLAND_REPEATed islands
	unsigned islandIndex;
	// Axis mapping into 'island space', where the x and y axes form the
	// island plane, and z is perpendicular
	unsigned xax, yax, zax;
	// Axis directions: deltas when searching for islands
	int xd, yd, zd;
	// The z delta when moving in the x or y directions
	// Used for 'sloped islands' such as sloped railroads, tall grass, reeds, etc..
	int xslope, yslope; 
	// Axis direction: 1 or -1
	int xd1, yd1;


	// Filled by the particular BlockGeometry's beginIsland:

	// Faces must be visible to continue island generation
	// This should be disabled, e.g. for slabs
	bool checkVisibility;
	// Even if the facing block is not opaque, island generation should be
	// stopped if the facing block has the same id as the current one
	// E.g. for water
	bool checkFacingSameId;
	// Callback function for more complex island continuation criteria
	// Return true to continue island generation
	typedef bool (*ComplexContinueIsland)( IslandDesc *island, const InstanceContext *nextBlock );
	ComplexContinueIsland continueIsland;
	// HACK to pass extra data through this structure. Used by:
	//  - ForwardingMultiGeometryAdapter
	unsigned cookie;
	// HACK to pass extra data through this structure. Used by:
	//  - ForwardingMultiGeometryAdapter
	void *pcookie;
	// Current geometry cluster to output the geometry to
	GeometryCluster *curCluster;
};

// ===========================================================================
// Geometry containers.
// These classes contain the intermediate geometry at all stages of the
// generation pipeline.

class GeometryStream {
	// Output stream for geometry (e.g. vertex data, index data)
	// This class has also been coopted as a general data stream

public:
	GeometryStream()
		: verts(NULL), vertSize(0), vertCapacity(0), vertCount(0)
	{ }
	~GeometryStream() {
		free( verts );
	}
	GeometryStream(const GeometryStream&) = delete;
	GeometryStream(GeometryStream &&other) {
		std::swap( verts, other.verts );
		std::swap( vertSize, other.vertSize );
		std::swap( vertCapacity, other.vertCapacity );
		std::swap( vertCount, other.vertCount );
		std::swap( indices, other.indices );
	}

	// Access to the vertex buffer
	const void *getVertices() const { return verts; }
	// Access to the vertex buffer
	void *getVertices() { return verts; }
	// Size in bytes of the vertex buffer
	unsigned getVertSize() const { return vertSize; }
	// Number of vertices in the vertex buffer
	unsigned getVertCount() const { return vertCount; }

	// Emit a vertex in arbitrary format
	template< typename T >
	inline void emitVertex( const T &src ) { emitVertex( &src, sizeof(T) ); }
	// Emit a vertex in arbitrary format
	void emitVertex( const void *src, unsigned size );

	// Pad the vertex buffer to ensure the given alignment for the next vertex
	// Assumes that getVertCount will not be called on this buffer, as the
	// vertices are no longer contiguous
	// This function is here since ATI cards seem to have problems with
	// unaligned vertex buffers
	inline void alignVertices( unsigned alignment = 4 ) {
		const unsigned char PADDING[] = { 0xad, 0xad, 0xad, 0xad, 0xad, 0xad, 0xad, 0xad };
		unsigned remainder = vertSize & (alignment-1);
		if( remainder )
			emitVertex( &PADDING[0], alignment - remainder );
	}

	// Access to the index buffer
	const unsigned *getIndices() const { return &indices[0]; }
	// Access to the index buffer
	unsigned *getIndices() { return &indices[0]; }
	// The the starting index of any new geometry to be put in this stream
	unsigned getIndexBase() const { return getVertCount(); }
	// Number of triangles
	unsigned getTriCount() const { return (unsigned)indices.size()/3; }

	// Emit indices for a single triangle
	inline void emitTriangle( unsigned i, unsigned j, unsigned k ) {
		indices.push_back( (unsigned)i );
		indices.push_back( (unsigned)j );
		indices.push_back( (unsigned)k );
	}
	// Emit indices for a quad
	inline void emitQuad( unsigned i, unsigned j, unsigned k, unsigned l ) {
		emitTriangle( i, j, k );
		emitTriangle( i, k, l );
	}

private:
	// Ensures that there is enough space in the vertex buffer for a new vertex
	void ensureVertCap( unsigned cap );

	// The vertex buffer
	void *verts;
	// Size in bytes of the vertex buffer
	unsigned vertSize;
	// Capacity in bytes of the vertex buffer
	unsigned vertCapacity;
	// Number of vertices emitted into the vertex buffer
	unsigned vertCount;
	// The index buffer
	std::vector<unsigned> indices;
};

class GeometryCluster {
	// GeometryClusters contain the geometry which is finally emitted by the
	// generation pipeline. There is one GeometryCluster per material
	// (currently for each block ID). Generally, the geometry is grouped into
	// several bins, which may be drawn differently depending on the
	// corresponding BlockGeometry.

public:
	// Deletes itself if empty. Returns true on suicide.
	virtual bool destroyIfEmpty() = 0;
	// Flatten all geometry contained in this cluster into the given data streams
	virtual void finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx ) = 0;

protected:
	GeometryCluster();
	virtual ~GeometryCluster();

	// Helper to determine the smallest index size to index nVerts different vertices
	static unsigned getSmallestIndexSize( unsigned nVerts );
	// In-place compression of an index buffer into the smallest possible representation
	// Returns the new index size
	static unsigned compressIndexBuffer( unsigned *indices, unsigned nVerts, unsigned nIndices );
	// Converts an index size to the corresponding GL type, e.g. GL_UNSIGNED_SHORT
	static unsigned indexSizeToGLType( unsigned size );
};

class MetaGeometryCluster : public GeometryCluster {
	// GeometryCluster which contains no geometry itself, but outputs metadata
	// into the metadata stream.
	// This is used in situations where the geometry is generated at render time,
	// such as the text on signs.

public:
	explicit MetaGeometryCluster( BlockGeometry *geom );

	virtual bool destroyIfEmpty();
	virtual void finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx  );

	// Access to the underlying data stream
	inline GeometryStream *getStream() { return &str; }
	// Count the number of entries in the cluster
	inline void incEntry() { n++; }

protected:
	~MetaGeometryCluster();

	// GeometryStream containing the metadata to store in the final meta stream
	GeometryStream str;
	// BlockGeometry for which render will be called on the metadata in the stream
	BlockGeometry *geom;
	// Number of metadata entries in the stream
	unsigned n;
};

template< typename Extra >
class SingleStreamGeometryClusterEx : public GeometryCluster {
	// GeometryCluster that dumps all geometry into a single GeometryStream
	// Useful for geometry for which no special optimizations have been
	// implemented, and so all geometry must always be processed. E.g. torches.
	// The Extra parameter allows additional peices of information to be
	// included in the metadata stream for use by the BlockGeometry.

public:
	explicit SingleStreamGeometryClusterEx( BlockGeometry *geom );
	SingleStreamGeometryClusterEx( BlockGeometry *geom, Extra ex );

	virtual bool destroyIfEmpty();
	virtual void finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx  );

	// Access to the underlying geometry stream
	inline GeometryStream *getStream() { return &str; }

	struct Meta {
		// Metadata layout

		// Offset into the grand vertex buffer of this cluster's vertices
		unsigned vtx_offset;
		// Offset into the grand index buffer of this cluster's indices
		unsigned idx_offset;
		// Number of triangles in this cluster
		unsigned nTris;
		// Number of vertices in this cluster
		unsigned nVerts;
		// The index format used by the geometry in this cluster
		unsigned idxType;
	};

protected:
	~SingleStreamGeometryClusterEx();

	// Helper to emit the BlockGeometry-specific peice of information 
	void emitExtra( GeometryStream *meta );

	// The BlockGeometry-specific peice of information
	Extra extra;
	// The actual geometry in the cluster
	GeometryStream str;
	// The BlockGeometry responsible for rendering this geometry
	BlockGeometry *geom;
};

struct EmptyStruct { };
// Basic SingleStreamGeometryClusterEx with no extra information
typedef SingleStreamGeometryClusterEx<EmptyStruct> SingleStreamGeometryCluster;

template< unsigned N >
class MultiStreamGeometryCluster : public GeometryCluster {
	// Most geometry in Minecraft is axis-aligned. We take advantage of that
	// by grouping all axis-aligned geometry in each qtree chunk, and only
	// sending it to the GPU if it is facing the camera. This GeometryCluster
	// stores geometry in one of several different streams for this purpose.
	// Most of the "normal" solid blocks end up emitting to this cluster type.

public:
	explicit MultiStreamGeometryCluster( BlockGeometry *geom );

	virtual bool destroyIfEmpty();
	virtual void finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx  );

	// Access to a given underlying geometry stream
	inline GeometryStream *getStream( unsigned i ) { return &str[i]; }
	void setCutoutVector( unsigned i, const jVec3 *cutout ) {
		jVec3Copy( &cutoutVectors[i], cutout );
	}

	struct Meta1 {
		// First piece of metadata output to the metadata stream

		// The number of non-empty geometry streams output
		unsigned n;
	};

	struct Meta2 {
		// One of these will exist per non-empty geometry stream

		// Offset into the grand vertex buffer of this cluster's vertices
		unsigned vtx_offset;
		// Offset into the grand index buffer of this cluster's indices
		unsigned idx_offset;
		// Number of triangles in this cluster
		unsigned nTris;
		// Number of vertices in this cluster
		unsigned nVerts;
		// The index format used by the geometry in this cluster
		unsigned idxType;
		// Direction of the geometry in this cluster
		// Ordered as X-, X+, Y-, Y+, Z-, Z+ (in Eihort's coordinate scheme)
		unsigned dir;
		// Plane behind which the camera definitely cannot see this geometry
		jPlane cutoutPlane;
	};

protected:
	~MultiStreamGeometryCluster();

	// The underlying geometry streams
	GeometryStream str[N];
	// The planes behind which the camera definitely cannot see the
	// geometry in the given stream
	jVec3 cutoutVectors[N];
	// The BlockGeometry responsible for rendering this geometry
	BlockGeometry *geom;
};

// A GeometryCluster supporting geometry in all 6 directions
typedef MultiStreamGeometryCluster<6> SixSidedGeometryCluster;

class MultiGeometryCluster : public GeometryCluster {
	// Sometimes the different classes that geometry can fall into cannot
	// easily be described by the above simple classes. In this case,
	// multiple geometry clusters may be used together. This is generally
	// used when one block ID can create many different types of
	// geometry/materials, such as the different wood types by the many
	// wood blocks/slabs, the changing of the texture on grass blocks
	// when a snow block is on top, etc...

public:
	MultiGeometryCluster();

	virtual bool destroyIfEmpty();
	virtual void finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx  );

	// Access to the underlying geometry clusters
	GeometryCluster *getCluster( unsigned i );
	// Create a new geometry cluster
	void newCluster( unsigned i, GeometryCluster *cluster );

	// Remembers the continueIsland callback from the given island description
	void storeContinueIsland( const IslandDesc *island );
	// Calls the remembered continueIsland callback
	bool callContinueIsland( IslandDesc *island, const InstanceContext *nextBlock );

private:
	~MultiGeometryCluster();

	// Underlying geometry clusters
	std::vector< GeometryCluster* > clusters;

	// Remembered continueIsland callback function
	IslandDesc::ComplexContinueIsland ciFn;
	// Remembered IslandDesc::cookie when chaining calls to continueIsland
	unsigned ciCookie;
	// Remembered IslandDesc::pcookie when chaining calls to continueIsland
	void *cipCookie;
	// Remembered IslandDesc::curCluster when chaining calls to continueIsland
	GeometryCluster *subCluster;
};

// ===========================================================================
// Block Geometries. BlockGeometry and its subclasses describe all the
// different geometry types, as well as material types that Eihort is
// capable of generating.

namespace RenderGroup {
	// BlockGeometry's are drawn in order of increasing render group
	// RenderGroups that are >= RenderGroup::TRANSPARENT is also treated
	// slightly differently - they are drawn sorted roughly back-to-front,
	// while lower rendergroups are rendered front-to-back.
	const unsigned FIRST = 500;
	const unsigned OPAQUE = 1000;
	const unsigned TRANSPARENT = 2000;
	const unsigned LAST = 3000;
}

class BlockGeometry : public LuaObject {
public:
	virtual ~BlockGeometry();

	enum IslandMode {
		// Island generation mode
		
		// "Normal" islands, which have arbitrary shape
		ISLAND_NORMAL = 0,
		// Islands which cannot extend in the island's X direction
		ISLAND_LOCK_X = 0x1,
		// Islands which cannot extend in the island's Y direction
		ISLAND_LOCK_Y = 0x2,
		// Islands constrained in both X and Y (i.e. single blocks)
		ISLAND_SINGLE = 0x3,

		// Bypasses the "done" flagging and repeatedly calls beginIsland
		// until ISLAND_CANCEL is returned.
		// Cannot be used with un-ISLAND_LOCK_*'d islands
		// Designed primarily to allow rectangular islands in different dimensions (fences)
		ISLAND_REPEAT = 0x4000,
		// Ends an ISLAND_REPEAT sequence
		ISLAND_CANCEL = 0x8000
	};

	// Get the geometry's render group
	inline unsigned getRenderGroup() const { return rg; }
	// Set the geometry's render group
	inline void setRenderGroup( unsigned group ) { rg = group; }

	// Render some geometry
	virtual void render( void *&meta, RenderContext *ctx );
	// Create a new geometry cluster to hold geometry to be generated through this BlockGeometry
	virtual GeometryCluster *newCluster() = 0;

	// Called when starting to emit geometry from a new block
	// Should return true if islands should be emitted from the block
	// May also emit geometry itself (e.g. for blocks without connecting
	// geometry), and then return false.
	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx ) = 0;
	// Begins island emission. Any special island generation settings
	// should be set here.
	virtual IslandMode beginIsland( IslandDesc *ctx );
	// A new island has been extracted from the world.
	// Geometry representing the island should be emitted here.
	virtual void emitIsland( GeometryCluster *out, const IslandDesc *ctx );

	// Lua functions

	// Helper to set the texture scale if the BlockGeometry supports that
	static int lua_setTexScale( lua_State *L );
	// Helper to modify the render group of the BlockGeometry to
	// fine-tune the render order
	static int lua_renderGroupAdd( lua_State *L );

	// Lua functions to generate BlockGeometry objects

	static int createDataAdapter( lua_State *L );
	static int createRotatingAdapter( lua_State *L );
	static int createFaceBitAdapter( lua_State *L );
	static int createFacingAdapter( lua_State *L );
	static int createTopDifferentAdapter( lua_State *L );
	static int createOpaqueBlockGeometry( lua_State *L );
	static int createBrightOpaqueBlockGeometry( lua_State *L );
	static int createTransparentBlockGeometry( lua_State *L );
	static int createSquashedBlockGeometry( lua_State *L );
	static int createCompactedGeometry( lua_State *L );
	static int createMultiCompactedBlock( lua_State *L );
	static int createMultiCompactedConnectedGeometry( lua_State *L );
	static int createBiomeOpaqueGeometry( lua_State *L );
	static int createBiomeAlphaOpaqueGeometry( lua_State *L );
	static int createPortalGeometry( lua_State *L );
	static int createHashShapedBlockGeometry( lua_State *L );
	static int createBiomeHashShapedBlockGeometry( lua_State *L );
	static int createRailGeometry( lua_State *L );
	static int createDoorGeometry( lua_State *L );
	static int createStairsGeometry( lua_State *L );
	static int createRedstoneWireGeometry( lua_State *L );
	static int createTorchGeometry( lua_State *L );
	static int createXShapedBlockGeometry( lua_State *L );
	static int createXShapedBlockBiomeGeometry( lua_State *L );

	// Delete a BlockGeometry
	static int lua_destroy( lua_State *L );
	// Set up this class's metatable and creation functions in Lua
	static void setupLua( lua_State *L );

protected:
	explicit BlockGeometry();

	// The BlockGeometry's render group, determining its render order
	unsigned rg;
};

class SignTextGeometry : public BlockGeometry {
	// Pseudo-geometry generator for sign text
	// This generator is treated as a special case in mcworldmesh,
	// since it takes data from the TileEntities part of the map
	// in addition to the block IDs.
	// Note: This does not draw sign geometry itself - that is
	// handled by the other geometry generators.

public:
	SignTextGeometry();
	virtual ~SignTextGeometry();

	virtual GeometryCluster *newCluster();
	virtual void render( void *&meta, RenderContext *ctx );

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );

	// Creates sign text at the given position
	void emitSign( GeometryCluster *out, const jMatrix *pos, const char *text );
};


// ===========================================================================
// Template class implementations

template< typename Extra >
SingleStreamGeometryClusterEx<Extra>::SingleStreamGeometryClusterEx( BlockGeometry *geom )
: geom(geom)
{
}

// -----------------------------------------------------------------
template< typename Extra >
SingleStreamGeometryClusterEx<Extra>::SingleStreamGeometryClusterEx( BlockGeometry *geom, Extra ex )
: extra(ex), geom(geom)
{
}

// -----------------------------------------------------------------
template< typename Extra >
SingleStreamGeometryClusterEx<Extra>::~SingleStreamGeometryClusterEx() {
}

// -----------------------------------------------------------------
template< typename Extra >
bool SingleStreamGeometryClusterEx<Extra>::destroyIfEmpty() {
	if( str.getTriCount() == 0 ) {
		delete this;
		return true;
	}
	return false;
}

// -----------------------------------------------------------------
template< typename Extra >
void SingleStreamGeometryClusterEx<Extra>::finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx ) {
	Meta mdata;

	vtx->alignVertices();
	mdata.vtx_offset = vtx->getVertSize();
	vtx->emitVertex( str.getVertices(), str.getVertSize() );
	mdata.nVerts = str.getVertCount();

	unsigned idxSize = compressIndexBuffer( str.getIndices(), str.getVertCount(), str.getTriCount()*3 );

	idx->alignVertices( idxSize );
	mdata.idx_offset = idx->getVertSize();
	idx->emitVertex( str.getIndices(), str.getTriCount()*3*idxSize );
	mdata.nTris = str.getTriCount();
	mdata.idxType = indexSizeToGLType( idxSize );

	meta->emitVertex( geom );
	emitExtra( meta );
	meta->emitVertex( mdata );

	delete this;
}

// -----------------------------------------------------------------
template< typename Extra >
void SingleStreamGeometryClusterEx<Extra>::emitExtra( GeometryStream *meta ) {
	meta->emitVertex( extra );
}

// -----------------------------------------------------------------
template<>
void SingleStreamGeometryClusterEx<EmptyStruct>::emitExtra( GeometryStream* );


// -=-=-=-=------------------------------------------------------=-=-=-=-
template< unsigned N >
MultiStreamGeometryCluster<N>::MultiStreamGeometryCluster( BlockGeometry *geom )
: geom(geom)
{
	for( unsigned i = N > 6 ? 6 : N; i--; ) {
		jVec3Zero( &cutoutVectors[i] );
		cutoutVectors[i].v[i>>1] = i&1 ? 1.0f : -1.0f;
	}
}

// -----------------------------------------------------------------
template< unsigned N >
MultiStreamGeometryCluster<N>::~MultiStreamGeometryCluster() {
}

// -----------------------------------------------------------------
template< unsigned N >
bool MultiStreamGeometryCluster<N>::destroyIfEmpty() {
	for( unsigned i = 0; i < N; i++ )
		if( str[i].getVertCount() )
			return false;

	delete this;
	return true;
}

// -----------------------------------------------------------------
template< unsigned N >
void MultiStreamGeometryCluster<N>::finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx ) {
	Meta1 m1;
	m1.n = 0;
	for( unsigned i = 0; i < N; i++ ) {
		if( str[i].getVertCount() )
			m1.n++;
	}

	meta->emitVertex( geom );
	meta->emitVertex( m1 );

	for( unsigned i = 0; i < N; i++ ) {
		if( str[i].getVertCount() ) {
			Meta2 m2;
			vtx->alignVertices();
			m2.vtx_offset = vtx->getVertSize();
			m2.nVerts = str[i].getVertCount();

			unsigned idxType = compressIndexBuffer( str[i].getIndices(), str[i].getVertCount(), str[i].getTriCount()*3 );
			idx->alignVertices( idxType );
			m2.idx_offset = idx->getVertSize();
			m2.idxType = indexSizeToGLType( idxType );
			m2.nTris = str[i].getTriCount();

			m2.dir = i;

			unsigned vtxSize = str[i].getVertSize();
			vtx->emitVertex( str[i].getVertices(), vtxSize );
			
			unsigned idxSize = m2.nTris*3*idxType;
			idx->emitVertex( str[i].getIndices(), idxSize );

			if( cutoutVectors[i].x == 0.0f && cutoutVectors[i].y == 0.0f && cutoutVectors[i].z == 0.0f ) {
				// Never cut out
				jVec3Zero( &m2.cutoutPlane.n );
				m2.cutoutPlane.d = 1.0f;
			} else {
				// Get a good cutout plane
				jVec3Copy( &m2.cutoutPlane.n, &cutoutVectors[i] );
				m2.cutoutPlane.d = 0.0f;
				unsigned vtxStride = str[i].getVertSize()/m2.nVerts;
				float minD = FLT_MAX;
				for( unsigned v = 0; v < vtxSize; v += vtxStride ) {
					short *pos = (short*)((char*)str[i].getVertices() + v);
					float d = m2.cutoutPlane.n.x * pos[0] + m2.cutoutPlane.n.y * pos[1] + m2.cutoutPlane.n.z * pos[2];
					if( d < minD )
						minD = d;
				}
				m2.cutoutPlane.d = -minD / 16.0f;
			}

			meta->emitVertex( m2 );
		}
	}

	delete this;
}


} // namespace geom
} // namespace eihort

#endif
