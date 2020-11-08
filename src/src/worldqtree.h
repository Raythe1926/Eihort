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

#ifndef WORLDQTREE_H
#define WORLDQTREE_H

#include "mcregionmap.h"
#include "worldmeshbuilder.h"
#include "jmath.h"
#include "luaobject.h"
#include "lightmodel.h"
#include "mempool.h"

// Lua metatable name
#define WORLDQTREE_META "WorldView"

namespace eihort {

class MCMap;
class MCBlockDesc;
class WorldMesh;

class WorldQTree : public LuaObject, public MCRegionMap::ChangeListener {
	// Main class for managing and rendering a set of WorldMeshes
	// Also includes camera functionality

public:
	WorldQTree( MCRegionMap *regions, MCBlockDesc *blockDesc, unsigned leafShift = 7, const BiomeCoordData *biomeIdToCoords = NULL );
	virtual ~WorldQTree();

	// Set the current camera position
	void setPosition( const jMatrix *mat );
	// Set the view distance
	void setViewDistance( float dist );
	// Set camera properties
	void setCameraParams( float yfov, float aspect, float near, float far );
	// Set the fog properties
	void setFog( float start, float end, float *color );
	// Get the current camera position
	const jMatrix *getEyeMat() const { return &eyeMat; }
	// Get the set of planes describing the camera's frustum
	// NOTE: Plane 6 has been replaced by a bounding sphere
	const jPlane *getFrustum() const;
	
	// Draw the world
	void draw();
	// Draws boxes where the world is loading
	void drawLoadingCarat();

	// Chunk change listener
	virtual void chunkChanged( int x, int y );
	// Unloads all meshes
	void kickOutAllMeshes();
	// Remove meshes within the given extents
	void kickOutTheseMeshes( const Extents *ext );
	// How many quadtree leaves are currently loading?
	unsigned getLoadingCount() const { return nMeshesLoading; }

	// Stop the loading of new meshes
	void pauseLoading( bool pause );
	// Are we still loading something?
	inline bool isLoading() const { return getLoadingCount() > 0; }

	// Set the GL state for the camera
	void initCamera();
	// Set the GL state for the camera with no translation
	void initCameraNoTrans();

	// Lua functions
	// Documented in the "World Rendering" section of Eihort Lua API.txt

	static int lua_setPosition( lua_State *L );
	static int lua_setViewDistance( lua_State *L );
	static int lua_setCameraParams( lua_State *L );
	static int lua_setFog( lua_State *L );
	static int lua_getLightModel( lua_State *L );
	static int lua_isLoading( lua_State *L );
	static int lua_pauseLoading( lua_State *L );
	static int lua_reloadAll( lua_State *L );
	static int lua_reloadRegion( lua_State *L );
	static int lua_setGpuAllowance( lua_State *L );
	static int lua_getGpuAllowance( lua_State *L );
	static int lua_getLastFrameStats( lua_State *L );
	static int lua_render( lua_State *L );
	static void createNew( lua_State *L, MCRegionMap *regions, MCBlockDesc *blocks, unsigned leafShift, const BiomeCoordData& biomeIdToCoords );
	static int lua_destroy( lua_State *L );
	static void setupLua( lua_State *L );

private:
	struct QTreeLeaf {
		// A leaf of the quadtree

		// Previous/Next pointers for the render list
		QTreeLeaf *prev, *next;
		// Distance of the leaf from the camera (updated if visible)
		float distance;
		// The mesh associated with the leaf
		WorldMesh *mesh;
		// The last frame on which this leaf was rendered
		unsigned lastRender;
		// Actual extents of the leaf mesh
		Extents lastExtents;
		// false when this leaf is loading
		bool load;
	};

	struct QTreeNode {
		// A node of the quadtree

		QTreeNode() { }
		// Root node constructor
		QTreeNode( WorldQTree *qtree, unsigned level, int minz, int maxz );
		// Intermediate node constructor
		QTreeNode( WorldQTree *qtree, const QTreeNode *parent, unsigned quadrant );

		// Full extents of all meshes in this world
		Extents ext;
		// Center of the qtree node
		jVec3 center;
		// Level of the node - i.e. how far above the leaves is this node
		unsigned level;
		
		union {
			// Child nodes (if level > 0)
			QTreeNode *subNodes[4];
			// Leaves (if level == 0)
			QTreeLeaf *leaves[4];
		};
	};

	// Unload meshes below node that intersect with ext
	void reloadArea( QTreeNode *node, const Extents *ext );
	// Complete the loading of any loading leaves
	void completeLoading();
	// Unload the mesh associated with a leaf
	void freeLeafMesh( QTreeLeaf *leaf );
	// Generate the render list of leaves below this node, and merge it into lists
	void generateRenderList( QTreeNode *node, QTreeLeaf **lists, unsigned &maxn );
	// Merge a leaf into a render list
	static void mergeLeafIntoRenderLists( QTreeLeaf **lists, unsigned &maxn, QTreeLeaf *leaf );
	// Merge render lists; returns the new first leaf
	static QTreeLeaf *mergeRenderLists( QTreeLeaf *list1, QTreeLeaf *list2 );
	// Merge render lists; returns the new first leaf; also give the new tail
	static QTreeLeaf *mergeRenderLists( QTreeLeaf *list1, QTreeLeaf *list2, QTreeLeaf *&tail );
	// Final merge of render lists (flattens the list of lists)
	static void mergeRenderListsFinal( QTreeLeaf **lists, unsigned maxn, QTreeLeaf *&head, QTreeLeaf *&tail );

	// Does the frustum intersect with the extents?
	static bool frustumIntersectsExtents( const jPlane *frustum, const Extents &ext );
	// Does the frustum intersect with a sphere?
	static bool frustumIntersects( const jPlane *frustum, const jVec3 *center, float rad );
	// Get the distance to the center of the sphere
	// If it's not visible, returns FLT_MAX
	static float getVisibleDistance( const jPlane *frustum, const jVec3 *center, float rad );
	// Divide the extents into the extents of one of its quadrants in the XY plane
	static void splitExtents( Extents *ext, unsigned corner );

	struct LoadingMesh {
		// Leaf which requested the loading
		QTreeLeaf *leaf;
		// The loaded data structure
		std::list<WorldMeshSectionData> loadedData;
		// Blocks from which to get the data
		const MCBlockDesc *blocks;
		// This worker's map object
		MCMap *map;
		// The extents to load the mesh in
		Extents loadingExt;
		// Has this mesh finished loading?
		bool loaded;
	};

	// Entrypoint for the mesh loading worker
	static void loadMesh_worker( void *ldmesh );

	// Rebuild the view frustum
	void buildViewFrustum();

	// Mesh loading controller
	LoadingMesh meshesLoading[MAX_WORKERS];
	// Total "cost" available for new meshes
	int newMeshAllowance;
	// VRAM available to use
	unsigned gpuAllowanceLeft;
	// Stops new leaves from loading
	bool holdLoading;
	// Mutex to protext large changes to the meshesLoading structure
	SDL_mutex *loadingMutex;

	// Memory pool for nodes
	MemoryPool<QTreeNode> nodePool;
	// Memory pool for leaves
	MemoryPool<QTreeLeaf> leafPool;
	// The root qtree node
	QTreeNode rootNode;
	// Linked list of unseen leaves (in LRS order)
	QTreeLeaf *unseenLeafHead, *unseenLeafTail;
	// Linked list of currently visible leaves
	QTreeLeaf *curRenderHead, *curRenderTail;

	// Region map from which to draw map data
	MCRegionMap *regions;
	// Block geometry to generate the world with
	MCBlockDesc *blockDesc;
	// The size of leaves is (1u<<leafShift)-2
	unsigned leafShift;
	// Size of the qtree leaves
	unsigned leafSize;

	// Radius of a node at given level
	float subVisRadii[32];
	// Used for limiting the draw distance when VRAM is limiting
	float newLoadDistanceLimit, limitLoadDistance;
	// Lighting models of the 6 sides
	LightModel lightModels[6];

	// Triangles rendered last frame
	unsigned trisILD;
	// Vertex buffer space used last frame
	unsigned vtxSpaceILD;
	// Index buffer space last frame
	unsigned idxSpaceILD;
	// Texture memory used last frame
	unsigned texSpaceILD;
	// Number of meshes currently loading
	unsigned nMeshesLoading;
	// The index of the current frame (compared with QTreeLeaf::lastRender)
	unsigned lastRender;

	// TODO: Move this to a camera class

	// Camera frustum planes
	jPlane frustum[6];
	// Camera position
	jMatrix eyeMat;
	// Fog color
	float fogColor[4];
	// Fog distances
	float fogStart, fogEnd;
	// Maximum view distance
	float viewDistance;
	// Y FOV / 2
	float yfov_2;
	// Height of the frustum, at a distance of 1 nearPlane from the camera
	float windowHt_2;
	// Aspect ratio of the screen
	float screenAspect;
	// Near and far plane distances
	float nearPlane, farPlane;
	// Does the frustum need to be regenerated?
	bool frustumIsDirty;

	// Meshes scheduled for destruction
	std::vector< QTreeLeaf* > meshesToKill;
	// Extents which have been kicked out recently
	std::vector< Extents > killedExts;
};

} // namespace eihort

#endif
