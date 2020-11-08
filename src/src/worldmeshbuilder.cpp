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


#include <cassert>
#include <cstring>
#include <GL/glew.h>

#include "worldmeshbuilder.h"
#include "worldmesh.h"
#include "mcmap.h"
#include "geombase.h"
#include "mcbiome.h"
#include "mcblockdesc.h"
#include "json.h"

namespace eihort {

// -----------------------------------------------------------------
WorldMeshBuilder::WorldMeshBuilder( MCMap *map, const MCBlockDesc *blocks )
: blockInfo(NULL), sizex(0), sizey(0), sizez(0), totalSize(0)
, allOne(NULL), lightingTex(NULL)
, blockDesc(blocks), map(map)
{
}

// -----------------------------------------------------------------
WorldMeshBuilder::~WorldMeshBuilder() {
	delete[] blockInfo;
	delete[] allOne;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::generate( const Extents &hull, const Extents &ltext, WorldMeshSectionData &into ) {
	// Point the internal structures at this region
	reorient( hull, ltext );

	// Make space for the lighting texture
	into.lightingTex.resize( 2u << (shiftx+shifty+shiftz), 0 );
	lightingTex = &into.lightingTex[0];
	into.ltSzX = ltext.maxx - ltext.minx + 1;
	into.ltSzY = ltext.maxy - ltext.miny + 1;
	into.ltSzZ = ltext.maxz - ltext.minz + 1;
	lightMapEdges();

	// Main geometry generation
	for( int x = hull.minx; x <= hull.maxx; x++ ) {
		for( int y = hull.miny; y <= hull.maxy; y++ ) {
			MCMap::Column col;
			if( map->getColumn( x, y, col ) ) {
				// Get MCMap::Column's for the target column and neighbouring columns
				MCMap::Column sides[4];
				bool sideExists[4];
				sideExists[0] = map->getColumn( x-1, y, sides[0] );
				sideExists[1] = map->getColumn( x+1, y, sides[1] );
				sideExists[2] = map->getColumn( x, y-1, sides[2] );
				sideExists[3] = map->getColumn( x, y+1, sides[3] );
				for( unsigned i = 0; i < 4; i++ ) {
					if( !sideExists[i] ) {
						sides[i].id = allOne;
						sides[i].minZ = col.minZ;
						sides[i].maxZ = col.maxZ;
					}
				}

				// Fill in lighting
				lightMapColumn( x, y, col, &sides[0] );

				int stopatz = std::min( hull.maxz, col.maxZ );
				for( int z = std::max( hull.minz, col.minZ ); z <= stopatz; z++ ) {
					unsigned id = col.getId( z );
					geom::BlockGeometry *geom = blockDesc->getGeometry( id );
					if( geom ) {
						// First check the solidity of all adjacent blocks
						memset(&island, 0, sizeof(island));
						for( unsigned i = 0; i < 4; i++ )
							island.origin.sides[i].solid = !!blockDesc->getSolidity( island.origin.sides[i].id = (unsigned short)sides[i].getId(z), i );
						island.origin.sides[4].solid = !!blockDesc->getSolidity( island.origin.sides[4].id = (unsigned short)col.getId(z-1), 4 );
						island.origin.sides[5].solid = !!blockDesc->getSolidity( island.origin.sides[5].id = (unsigned short)col.getId(z+1), 5 );

						if( blockDesc->shouldHighlight( id ) ) {
							// Override the solidity of blocks beside highlighted blocks
							for( unsigned i = 0; i < 4; i++ )
								island.origin.sides[i].solid = !sideExists[i];
							island.origin.sides[4].solid = z <= col.minZ;
							island.origin.sides[5].solid = 0;
						} else {
							if( island.origin.sides[0].solid && island.origin.sides[1].solid && island.origin.sides[2].solid
							 && island.origin.sides[3].solid && island.origin.sides[4].solid && island.origin.sides[5].solid ) {
								// All adjacent blocks are solid
								// There is no way to see this block
								continue;
							}
						}

						// The block is potentially visible
						island.origin.sides[0].outside = x == hull.minx;
						island.origin.sides[1].outside = x == hull.maxx;
						island.origin.sides[2].outside = y == hull.miny;
						island.origin.sides[3].outside = y == hull.maxy;
						island.origin.sides[4].outside = z == hull.minz;
						island.origin.sides[5].outside = z == hull.maxz;
						island.origin.block.id = (unsigned short)id;
						island.origin.block.data = (unsigned short)col.getData( z );
						island.origin.block.pos.x = x; island.origin.block.pos.y = y; island.origin.block.pos.z = z;
						geom::Point worldSpacePos = island.origin.block.pos;
						toLocalSpace( island.origin.block.pos );

						// Generate geometry for this block
						if( geom->beginEmit( getGeometryCluster( id ), &island.origin ) ) {
							island.origin.block.pos = worldSpacePos;
							generateIslands( geom );
						}
					}
				}
			}
		}
	}

	// Output sign text
	outputSignsFromMap( hull.minx, hull.maxx, hull.miny, hull.maxy );

	// Get the biome coordinates
	into.biomeSrc = blockDesc->getBiomes();
	into.biomeCoords = into.biomeSrc->readBiomeCoords( map, ltext.minx, ltext.maxx, ltext.miny, ltext.maxy );

	// Get a list of all geometries in this mesh
	std::vector< GeomAndCluster > renderOrder;
	for( unsigned i = 0; i < BLOCK_ID_COUNT; i++ ) {
		if( geomStreams[i] ) {
			if( !geomStreams[i]->destroyIfEmpty() ) {
				GeomAndCluster gc;
				gc.geom = blockDesc->getGeometry( i );
				gc.cluster = geomStreams[i];
				renderOrder.push_back( gc );
			}
			geomStreams[i] = NULL;
		}
	}

	if( !renderOrder.empty() ) {
		// Sort the geometries by render group
		std::sort( renderOrder.begin(), renderOrder.end() );
		
		// Finalize all geometry clusters into monolithic meta, vertex, and index buffers
		geom::GeometryStream &metaStream = into.metaStream;
		geom::GeometryStream &vtxStream = into.vtxStream;
		geom::GeometryStream &idxStream = into.idxStream;
		into.opaqueEnd = 0;
		for( std::vector< GeomAndCluster >::const_iterator it = renderOrder.begin(); it != renderOrder.end(); ++it ) {
			it->cluster->finalize( &metaStream, &vtxStream, &idxStream );

			if( it->geom->getRenderGroup() < geom::RenderGroup::TRANSPARENT )
				into.opaqueEnd = metaStream.getVertSize();
		}
		into.transpEnd = metaStream.getVertSize();
	} else {
		// Empty mesh
		into.opaqueEnd = 0;
		into.transpEnd = 0;
	}

	into.origin[0] = origin[0];
	into.origin[1] = origin[1];
	into.origin[2] = origin[2];
	into.lightTexScale[0] = (1.0/16.0) / sizex;
	into.lightTexScale[1] = (1.0/16.0) / sizey;
	into.lightTexScale[2] = (1.0/16.0) / sizez;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::generateOptimal( Extents &ext, std::list<WorldMeshSectionData> &into ) {
	into.clear();
	if( !map->getRegions()->isAnvil() ) {
		// MCRegion - create a single section from 0-127
		Extents ltext( ext.minx - 1, ext.maxx + 1, ext.miny - 1, ext.maxy + 1, ext.minz, ext.maxz );
		into.emplace_back();
		generate( ext, ltext, into.back() );
	} else {
		// Anvil - potentially 256 blocks high
		Extents hull = ext;
		map->getExtentsWithin( ext.minx, ext.maxx, ext.miny, ext.maxy, ext.minz, ext.maxz );
		
		// TODO: More intelligent shrinking and subdivision of the volume
		if( ext.maxz <= 127 )
			hull.maxz = 127;

		Extents ltext( hull.minx - 1, hull.maxx + 1, hull.miny - 1, hull.maxy + 1, hull.minz, hull.maxz );
		into.emplace_back();
		generate( hull, ltext, into.back() );
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::reorient( const Extents &hull, const Extents &ltext ) {
	// Ensure the allOne vector is large enough
	unsigned minsizez = unsigned(ltext.maxz - ltext.minz + 1);
	if( sizez < minsizez ) {
		delete[] allOne;
		allOne = new unsigned short[minsizez];
		for( unsigned z = 0; z < minsizez; z++ )
			allOne[z] = 1;
	}

	// Get the new sizes, shifts, and origin
	hullExt = hull;
	pow2Ext = ltext;
	sizex = (unsigned)(pow2Ext.maxx-pow2Ext.minx+1);
	sizey = (unsigned)(pow2Ext.maxy-pow2Ext.miny+1);
	sizez = (unsigned)(pow2Ext.maxz-pow2Ext.minz+1);
	shiftx = getPow2( sizex );
	shifty = getPow2( sizey );
	shiftz = getPow2( sizez );
	origin[0] = pow2Ext.minx + (sizex>>1);
	origin[1] = pow2Ext.miny + (sizey>>1);
	origin[2] = pow2Ext.minz + (sizez>>1);

	// Resize blockInfo if needed
	unsigned newTotalSize = 1u << (shiftx + shifty + shiftz);
	if( newTotalSize > totalSize ) {
		delete[] blockInfo;
		blockInfo = new unsigned short[totalSize = newTotalSize];
	}

	// All blocks start out unflagged
	for( unsigned i = 0; i < newTotalSize; i++ )
		blockInfo[i] = 0;

	// No geometry streams
	for( unsigned i = 0; i < BLOCK_ID_COUNT; i++ )
		geomStreams[i] = NULL;
}

// -----------------------------------------------------------------
geom::GeometryCluster *WorldMeshBuilder::getGeometryCluster( unsigned id ) {
	geom::GeometryCluster *str = geomStreams[id];
	if( !str )
		str = geomStreams[id] = blockDesc->getGeometry(id)->newCluster();
	return str;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::toLocalSpace( std::vector< geom::Point > &points ) {
	for( std::vector< geom::Point >::iterator it = points.begin(); it != points.end(); ++it )
		toLocalSpace( *it );
}

// -----------------------------------------------------------------
void WorldMeshBuilder::transformHolesToLocalSpace() {
	for( std::list< IslandHole >::iterator it = holes.begin(); it != holes.end(); ++it ) {
		toLocalSpace( it->blocks() );
		toLocalSpace( it->points() );
		toLocalSpace( it->insidePoint() );
	}
}

// -----------------------------------------------------------------
unsigned WorldMeshBuilder::getPow2( unsigned i ) {
	if( i ) {
		i >>= 1;
		unsigned shift = 0;
		while( i ) {
			shift++;
			i >>= 1;
		}
		return shift;
	}
	return 0;
}

// -----------------------------------------------------------------
unsigned WorldMeshBuilder::gatherHoleContourPoints( unsigned *&ends, geom::Point *&points, geom::Point *&inside ) {
	// Get the indices of the endpoints for each hole in the final point array
	ends = new unsigned[holes.size()];
	inside = new geom::Point[holes.size()];
	unsigned pointCount = 0, n = 0;
	for( std::list< IslandHole >::const_iterator it = holes.begin(); it != holes.end(); ++it ) {
		if( !it->isRemovable() ) {
			ends[n] = (pointCount += (unsigned)it->points().size());
			inside[n] = it->insidePoint();
			n++;
		}
	}
		
	if( n ) {
		// There are non-removed holes.. serialize the contour points
		geom::Point *pt = points = new geom::Point[ends[n-1]];
		for( std::list< IslandHole >::const_iterator it = holes.begin(); it != holes.end(); ++it ) {
			if( !it->isRemovable() ) {
				memcpy( pt, &it->points()[0], sizeof(geom::Point) * it->points().size() );
				pt += it->points().size();
			}
		}
	} else {
		// All holes were removed.. return nothing
		points = NULL;
		delete[] ends;
		ends = NULL;
		delete[] inside;
		inside = NULL;
	}

	return n;
}

// -----------------------------------------------------------------
bool WorldMeshBuilder::IslandHole::isRemovable() const {
	if( !(firstBlockIsNonVisible && contourPoints.size() == 4) )
		return false;

	// TODO: Expand on these conditions to remove more non-necessary holes

	// The hole is removable if the first block is not visible, and it's
	// the only block in the island
	int dist1 = abs( contourPoints[0].v[0] - contourPoints[1].v[0] ) +
			    abs( contourPoints[0].v[1] - contourPoints[1].v[1] ) +
				abs( contourPoints[0].v[2] - contourPoints[1].v[2] );
	int dist2 = abs( contourPoints[1].v[0] - contourPoints[2].v[0] ) +
			    abs( contourPoints[1].v[1] - contourPoints[2].v[1] ) +
				abs( contourPoints[1].v[2] - contourPoints[2].v[2] );
	return dist1 == 1 && dist2 == 1;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::moveCoordsInDir( int *coords, unsigned dir ) {
	switch( dir ) {
	case 0: coords[island.xax] -= island.xd;
		    coords[island.zax] -= island.xslope; break;
	case 1: coords[island.yax] -= island.yd;
		    coords[island.zax] -= island.yslope; break;
	case 2: coords[island.xax] += island.xd;
		    coords[island.zax] += island.xslope; break;
	case 3: coords[island.yax] += island.yd;
		    coords[island.zax] += island.yslope; break;
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::moveCoordsInDir1( int *coords, unsigned dir ) {
	switch( dir ) {
	case 0: coords[island.xax] -= island.xd1;
		    coords[island.zax] -= island.xslope; break;
	case 1: coords[island.yax] -= island.yd1;
		    coords[island.zax] -= island.yslope; break;
	case 2: coords[island.xax] += island.xd1;
		    coords[island.zax] += island.xslope; break;
	case 3: coords[island.yax] += island.yd1;
		    coords[island.zax] += island.yslope; break;
	}
}

// -----------------------------------------------------------------
bool WorldMeshBuilder::scanContourAndFlag( const geom::Point &start, unsigned startDir, std::vector< geom::Point > &contourBlocks, std::vector< geom::Point > &contourPoints ) {
	geom::Point pos = start;
	geom::Point contourPt = pos;
	unsigned islDir = startDir, lastDir = startDir;
	bool exploratory = false;
	
	// Adjust the starting point for the contour based on the starting direction
	if( island.islandAxis&1 ) contourPt.v[island.zax]++;
	switch( startDir ) {
	case 0:
		contourPt.v[island.xax] += island.xd<0 ? 1 : 0;
		contourPt.v[island.yax] += island.yd>0 ? 1 : 0;
		break;
	case 1:
		contourPt.v[island.xax] += island.xd<0 ? 1 : 0;
		contourPt.v[island.yax] += island.yd<0 ? 1 : 0;
		break;
	case 2:
		contourPt.v[island.xax] += island.xd>0 ? 1 : 0;
		contourPt.v[island.yax] += island.yd<0 ? 1 : 0;
		break;
	case 3:
		contourPt.v[island.xax] += island.xd>0 ? 1 : 0;
		contourPt.v[island.yax] += island.yd>0 ? 1 : 0;
		break;
	}


	do {
		if( contourBlocks.size() > 9999 ) // Failsafe
			return false;

		// Try to move in islDir
		geom::Point nextPos = pos;
		moveCoordsInDir( nextPos.v, islDir );

		// Is it out of the bounds of the area we are building a mesh for?
		if( !hullExt.contains( nextPos.x, nextPos.y, nextPos.z ) )
			goto dont_continue_island;

		// Does the map exist here? Does the block have the same id?
		MCMap::Column nextCol;
		if( !map->getColumn( nextPos.x, nextPos.y, nextCol ) ||
			nextCol.getId( nextPos.z ) != island.origin.block.id )
			goto dont_continue_island;

		// Complex island check
		if( island.continueIsland ) {
			geom::InstanceContext nextBlock;
			nextBlock.block.pos = nextPos;
			nextBlock.block.id = (unsigned short)nextCol.getId( nextPos.z );
			nextBlock.block.data = (unsigned short)nextCol.getData( nextPos.z );
			nextBlock.sides[4].id = (unsigned short)(nextPos.z > hullExt.minz ? nextCol.getId( nextPos.z - 1 ) : 1u);
			nextBlock.sides[5].id = (unsigned short)(nextPos.z < hullExt.maxz ? nextCol.getId( nextPos.z + 1 ) : 1u);
			if( !island.continueIsland( &island, &nextBlock ) )
				goto dont_continue_island;
		}

		// Is the block visible?
		if( island.checkVisibility | island.checkFacingSameId ) {
			unsigned short facingId;
			if( island.zax == 2 ) {
				facingId = (unsigned short)nextCol.getId( nextPos.z + island.zd );
			} else {
				nextPos.v[island.zax] += island.zd;
				if( !map->getBlockID( nextPos.x, nextPos.y, nextPos.z, facingId ) )
					// Invisible - skip the block
					goto dont_continue_island;
				nextPos.v[island.zax] -= island.zd;
			}
			if( (island.checkFacingSameId && facingId == island.origin.block.id) ||
				(island.checkVisibility && blockDesc->getSolidity( facingId, island.islandAxis )) )
				// Invisible - skip the block
				goto dont_continue_island;
		}

		// Continue the island
		lastDir = islDir;
		if( exploratory ) {
			// Output corner point
			contourPoints.push_back( contourPt );

			// Output corner block
			contourBlocks.push_back( pos );

			// There is no sense in exploring twice in a row
			moveCoordsInDir1( contourPt.v, islDir );
			flagEdge( nextPos, (islDir - 1) & 3 );
			exploratory = false;
		} else {
			// Explore clockwise
			exploratory = true;
			islDir = (islDir - 1) & 3;
		}

		pos = nextPos;

		continue;

dont_continue_island:
		if( exploratory ) {
			exploratory = false;
		} else {
			// Output contour point
			contourPoints.push_back( contourPt );
			if( lastDir == islDir ) {
				// Output corner block
				contourBlocks.push_back( pos );
			}
		}

		// Mark the edge
		flagEdge( pos, islDir );

		// Rotate counterclockwise
		islDir = (islDir + 1) & 3;
		moveCoordsInDir1( contourPt.v, islDir );

	} while( islDir != startDir || pos != start );

	if( contourBlocks.size() > 1 && contourBlocks.front() == contourBlocks.back() )
		contourBlocks.pop_back();

	return true;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::holeScan( const geom::Point &start, unsigned dir ) {
	// First check if the starting position has overlapping flags
	// This takes care of the case where the island has 1-square wide sections
	if( isEdgeFlagged( start, dir ) )
		return;

	geom::Point pos = start;
	markDone( pos, island.islandAxis );
	geom::Point nextPos;
	bool holeIsVisible = true;
	while( true ) {
		// Try to move one square
		nextPos = pos;
		moveCoordsInDir( nextPos.v, dir );

		if( isEdgeFlagged( nextPos, dir ) )
			break; // Hit the other side!

		// Does the map exist here?
		MCMap::Column nextCol;
		if( !map->getColumn( nextPos.x, nextPos.y, nextCol ) ) {
			holeIsVisible = false;
			goto its_a_hole;
		}

		// Is the block visible?
		if( island.checkVisibility | island.checkFacingSameId ) {
			unsigned short facingId;
			if( island.zax == 2 ) {
				facingId = (unsigned short)nextCol.getId( nextPos.z + island.zd );
			} else {
				nextPos.v[island.zax] += island.zd;
				if( !map->getBlockID( nextPos.x, nextPos.y, nextPos.z, facingId ) ) {
					// Hit the outside - should never happen in current maps
					holeIsVisible = false;
					goto its_a_hole;
				}
				nextPos.v[island.zax] -= island.zd;
			}
			holeIsVisible = !island.checkVisibility || !blockDesc->getSolidity( facingId, island.islandAxis );
			if( (island.checkFacingSameId && facingId == island.origin.block.id) ||
				!holeIsVisible )
				// Invisible - hole!
				goto its_a_hole;
		}

		// Does the next block have the same id?
		if( nextCol.getId( nextPos.z ) != island.origin.block.id )
			goto its_a_hole;

		// Complex island check
		if( island.continueIsland ) {
			geom::InstanceContext nextBlock;
			nextBlock.block.pos = nextPos;
			nextBlock.block.id = (unsigned short)nextCol.getId( nextPos.z );
			nextBlock.block.data = (unsigned short)nextCol.getData( nextPos.z );
			nextBlock.sides[4].id = (unsigned short)(nextPos.z > hullExt.minz ? nextCol.getId( nextPos.z - 1 ) : 1u);
			nextBlock.sides[5].id = (unsigned short)(nextPos.z < hullExt.maxz ? nextCol.getId( nextPos.z + 1 ) : 1u);
			if( !island.continueIsland( &island, &nextBlock ) )
				goto its_a_hole;
		}

		// Not a hole
		pos = nextPos;
		markDone( pos, island.islandAxis );
	}

	//markDone( pos, island.islandAxis );
	return;

its_a_hole:
	// It's a hole!!
	IslandHole *hole = newHole( holeIsVisible );
	hole->insidePoint() = nextPos;
	scanContourAndFlag( pos, (dir+1)&3, hole->blocks(), hole->points() );
}

// -----------------------------------------------------------------
void WorldMeshBuilder::searchForHoles( const std::vector< geom::Point > &contourBlocks ) {
	assert( contourBlocks.size() > 1 );

	geom::Point pos = contourBlocks.back();

	for( unsigned i = 0; i < contourBlocks.size(); i++ ) {
		const geom::Point& dest = contourBlocks[i];

		unsigned dir;
		if( pos.v[island.yax] == dest.v[island.yax] ) {
			dir = (pos.v[island.xax] > dest.v[island.xax]) == (island.xd > 0) ? 0 : 2;
		} else {
			// To anyone debugging, if you hit this assert, PREPARE FOR MISERY!
			// This means that something has gone wrong with the island generation
			// such that an island contour has been created which does not end where
			// it began. The causes for this are innumerate and all hard to trace.
			// For example, if an island is initiated not on the periphery of the
			// island (e.g. due to incorrect face flags in WorldMeshBuilder::blockInfo),
			// this will happen. Happy bug hunting!
			assert( pos.v[island.xax] == dest.v[island.xax] );
			dir = (pos.v[island.yax] > dest.v[island.yax]) == (island.yd > 0) ? 1 : 3;
		}
		
		holeScan( pos, (dir + 1) & 3 );
		do {
			moveCoordsInDir( pos.v, dir );
			holeScan( pos, (dir + 1) & 3 );
		} while( pos != dest );
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::unflagContour( const std::vector< geom::Point > &contourBlocks, bool mark ) {
	assert( contourBlocks.size() > 1 );

	for( unsigned i = 0; i < contourBlocks.size(); i++ ) {
		geom::Point pos = i ? contourBlocks[i-1] : contourBlocks.back();
		const geom::Point& dest = contourBlocks[i];

		unsigned dir;
		if( pos.v[island.yax] == dest.v[island.yax] ) {
			dir = (pos.v[island.xax] > dest.v[island.xax]) == (island.xd > 0) ? 0 : 2;
		} else {
			dir = (pos.v[island.yax] > dest.v[island.yax]) == (island.yd > 0) ? 1 : 3;
		}
		
		unflagEdge( pos );
		if( mark )
			markDone( pos, island.islandAxis );
		do {
			moveCoordsInDir( pos.v, dir );
			unflagEdge( pos );
			if( mark )
				markDone( pos, island.islandAxis );
		} while( pos != dest );
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::generateIslands( geom::BlockGeometry *geom ) {
	std::vector< geom::Point > contourBlocks;
	std::vector< geom::Point > contourPoints;
	std::vector< std::vector< geom::BlockData > > holes;

	geom::GeometryCluster *cluster = getGeometryCluster( island.origin.block.id );
	geom::BlockData oriBlock = island.origin.block;
	unsigned nextIslandIndex = 0;
	for( unsigned dir = 0; dir < 6; dir++ ) {
		if( isDone( island.origin.block.pos, dir ) )
			continue; // This face is finished by another island
		
		// Set up the island axes
		island.islandAxis = dir;
		island.zax = dir >> 1;
		island.zd = dir&1 ? 1 : -1;
		switch( dir ) {
		case 0:
			island.xax = 2;
			island.xd = -1;
			island.yax = 1;
			island.yd = -1;
			break;
		case 1:
			island.xax = 1;
			island.xd = -1;
			island.yax = 2;
			island.yd = -1;
			break;
		case 2:
			island.xax = 0;
			island.xd = -1;
			island.yax = 2;
			island.yd = -1;
			break;
		case 3:
			island.xax = 2;
			island.xd = -1;
			island.yax = 0;
			island.yd = -1;
			break;
		case 4:
			island.xax = 0;
			island.xd = 1;
			island.yax = 1;
			island.yd = -1;
			break;
		case 5:
			island.xax = 0;
			island.xd = -1;
			island.yax = 1;
			island.yd = -1;
			break;
		}

		// Set up the context
		island.xd1 = island.xd;
		island.yd1 = island.yd;
		island.xslope = 0;
		island.yslope = 0;
		island.origin.block = oriBlock;
		island.continueIsland = NULL;
		island.checkVisibility = true;
		island.checkFacingSameId = true;
		island.curCluster = cluster;
		island.islandIndex = nextIslandIndex;

		// Start island generation
		unsigned mode = geom->beginIsland( &island );
		if( island.checkVisibility && island.origin.sides[dir].solid )
			continue;
		if( island.checkFacingSameId && island.origin.sides[dir].id == island.origin.block.id )
			continue;
		bool markAsDone = true;
		nextIslandIndex = 0;
		if( mode ) {
			if( mode & geom::BlockGeometry::ISLAND_CANCEL )
				continue;
			if( mode & geom::BlockGeometry::ISLAND_LOCK_X )
				island.xd *= 99999;
			if( mode & geom::BlockGeometry::ISLAND_LOCK_Y )
				island.yd *= 99999;
			if( mode & geom::BlockGeometry::ISLAND_REPEAT ) {
				assert( mode & geom::BlockGeometry::ISLAND_SINGLE );
				dir--;
				markAsDone = false;
				nextIslandIndex = island.islandIndex + 1;
			}
		}

		island.checkVisibility &= !blockDesc->shouldHighlight( island.origin.block.id );

		// Generate the island
		if( scanContourAndFlag( island.origin.block.pos, 0, contourBlocks, contourPoints ) ) {
			if( contourBlocks.size() > 1 ) {
				if( contourBlocks.size() > 2 ) {
					// The island has an interior - search for holes
					searchForHoles( contourBlocks );
					for( std::list< IslandHole >::const_iterator it = getHoles().begin(); it != getHoles().end(); ++it )
						searchForHoles( it->blocks() );
					// Clean up
					unflagContour( contourBlocks );
					for( std::list< IslandHole >::const_iterator it = getHoles().begin(); it != getHoles().end(); ++it )
						unflagContour( it->blocks() );

					transformHolesToLocalSpace();

					island.nHoles = (unsigned)getHoles().size();
					if( island.nHoles ) {
						island.nHoles = gatherHoleContourPoints( island.holeContourEnd, island.holeContourPoints, island.holeInsidePoint );
						clearHoles();
					}
				} else {
					island.nHoles = 0;
					unflagContour( contourBlocks, markAsDone );
				}

				toLocalSpace( contourBlocks );
				toLocalSpace( contourPoints );
				toLocalSpace( island.origin.block.pos );

				island.nContourBlocks = (unsigned)contourBlocks.size();
				island.contourBlocks = &contourBlocks[0];
				island.nContourPoints = (unsigned)contourPoints.size();
				island.contourPoints = &contourPoints[0];
				geom->emitIsland( cluster, &island );

				if( island.nHoles ) {
					delete[] island.holeContourEnd;
					delete[] island.holeContourPoints;
					delete[] island.holeInsidePoint;
				}
			} else {
				// Single square - mark as done and clear flags
				if( markAsDone )
					markDone( island.origin.block.pos, dir );
				unflagEdge( island.origin.block.pos );

				toLocalSpace( contourBlocks );
				toLocalSpace( contourPoints );
				toLocalSpace( island.origin.block.pos );

				island.nHoles = 0;
				island.nContourBlocks = (unsigned)contourBlocks.size();
				island.contourBlocks = &contourBlocks[0];
				island.nContourPoints = (unsigned)contourPoints.size();
				island.contourPoints = &contourPoints[0];

				geom->emitIsland( cluster, &island );
			}
		}

		contourBlocks.clear();
		contourPoints.clear();
		island.origin.block.pos = oriBlock.pos;
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::glowAreaAround( int x, int y, int z ) {
	const unsigned LIGHT_LEVEL[4] = { 15, 14, 12, 10 };
	for( int xp = x - 1; xp <= x + 1; xp++ ) {
		for( int yp = y - 1; yp <= y + 1; yp++ ) {
			for( int zp = z - 1; zp <= z + 1; zp++ ) {
				if( pow2Ext.contains( xp, yp, zp ) ) {
					unsigned lv = (xp==x ? 0u : 1u) + (yp==y ? 0u : 1u) + (zp==z ? 0u : 1u);
					setLightingAt( xp, yp, zp, LIGHT_LEVEL[lv], 0 );
				}
			}
		}
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::lightMapColumn( int x, int y, const MCMap::Column &col, const MCMap::Column *sides ) {
	const unsigned AO_HARSHNESS = 4;

	for( int z = hullExt.minz; z <= hullExt.maxz; z++ ) {
		unsigned id = col.getId( z );
		unsigned blockLight = blockDesc->enableBlockLighting() ? col.getBlockLight( z ) : 0u;
		unsigned skyLight = col.getSkyLight( z );
		setLightingAt( x, y, z, blockLight, skyLight );

		if( id > 0 ) {
			if( blockDesc->shouldHighlight( id ) ) {
				glowAreaAround( x, y, z );
			} else {
				// Un-harshen the lighting by letting the light 'seep' into blocks from above
				if( blockLight == 0 && skyLight == 0 ) {
					unsigned maxBlockLight = 0, maxSkyLight = 0;
					for( unsigned i = 0; i < 4; i++ ) {
						if( !blockDesc->getSolidity( sides[i].getId( z ), i ) ) {
							unsigned light = sides[i].getBlockLight( z );
							if( light > maxBlockLight )
								maxBlockLight = light;
							light = sides[i].getSkyLight( z );
							if( light > maxSkyLight )
								maxSkyLight = light;
						}
					}
					if( /*z > col.minZ &&*/ !blockDesc->getSolidity( col.getId( z-1 ), 4 ) ) {
						unsigned light = col.getBlockLight( z-1 );
						if( light > maxBlockLight )
							maxBlockLight = light;
						light = col.getSkyLight( z-1 );
						if( light > maxSkyLight )
							maxSkyLight = light;
					}
					if( /*z < col.maxZ &&*/ !blockDesc->getSolidity( col.getId( z+1 ), 5 ) ) {
						unsigned light = col.getBlockLight( z+1 );
						if( light > maxBlockLight )
							maxBlockLight = light;
						light = col.getSkyLight( z+1 );
						if( light > maxSkyLight )
							maxSkyLight = light;
					}

					if( !blockDesc->enableBlockLighting() )
						maxBlockLight = 0;
					if( maxBlockLight <= AO_HARSHNESS ) {
						maxBlockLight = 0;
					} else {
						maxBlockLight -= AO_HARSHNESS;
					}
					if( maxSkyLight <= AO_HARSHNESS ) {
						maxSkyLight = 0;
					} else {
						maxSkyLight -= AO_HARSHNESS;
					}

					setLightingAt( x, y, z, maxBlockLight, maxSkyLight );
				}
			
				// HACK - Always let light seep into non-solid blocks (especially slabs) from above
				if( blockDesc->enableBlockLighting() && blockDesc->getSolidity( id, 4 ) && z < col.maxZ ) {
					setLightingAt( x, y, z,
						std::max( AO_HARSHNESS, col.getBlockLight( z+1 ) ) - AO_HARSHNESS,
						std::max( AO_HARSHNESS, col.getSkyLight( z+1 ) ) - AO_HARSHNESS );
				}
			}
		} else {
			// This is air
			if( blockDesc->getDefAirSkyLightOverride() )
				// Override the skylight (for the End)
				setLightingAt( x, y, z, blockLight, blockDesc->getDefAirSkyLight() );
		}
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::lightMapColumn( int x, int y ) {
	MCMap::Column col;
	if( map->getColumn( x, y, col ) ) {
		MCMap::Column sides[4];
		bool sideExists[4];
		sideExists[0] = map->getColumn( x-1, y, sides[0] );
		sideExists[1] = map->getColumn( x+1, y, sides[1] );
		sideExists[2] = map->getColumn( x, y-1, sides[2] );
		sideExists[3] = map->getColumn( x, y+1, sides[3] );
		for( unsigned i = 0; i < 4; i++ ) {
			if( !sideExists[i] ) {
				sides[i].id = allOne;
				sides[i].minZ = col.minZ;
			}
		}

		lightMapColumn( x, y, col, &sides[0] );
	}
}

// -----------------------------------------------------------------
void WorldMeshBuilder::lightMapEdges() {
	// Set up the lighting around the edge of the section
	for( int x = pow2Ext.minx; x <= pow2Ext.maxx; x++ ) {
		lightMapColumn( x, pow2Ext.miny );
		lightMapColumn( x, pow2Ext.maxy );
	}
	for( int y = pow2Ext.miny; y <= pow2Ext.maxy; y++ ) {
		lightMapColumn( pow2Ext.minx, y );
		lightMapColumn( pow2Ext.maxx, y );
	}
}

// -----------------------------------------------------------------
static std::size_t parseText( char *dest, std::size_t destLen, const char *src, std::size_t srcLen ) {
	// Try to parse the text as JSON
	json::Object obj;
	if( obj.parse( src, srcLen ) && obj.find("text") != obj.end() ) {
		// TODO: MC supports some format codes as well
		 // {"text":"","color":"dark_blue","bold":true,"obfuscated":false}
		 // these should be translated to the sign-codes for the renderer

		// Get the string
		src = obj["text"].c_str();
		srcLen = obj["text"].size();
	}

	// Copy verbatim
	std::size_t ncopy = std::min( destLen, srcLen );
	std::memcpy( dest, src, ncopy );

	return ncopy;
}

// -----------------------------------------------------------------
void WorldMeshBuilder::outputSignsFromMap( int minx, int maxx, int miny, int maxy ) {
	geom::SignTextGeometry *signGeom = (geom::SignTextGeometry*)blockDesc->getGeometry( SIGNTEXT_BLOCK_ID );
	geom::GeometryCluster *cluster = getGeometryCluster( SIGNTEXT_BLOCK_ID );
	MCMap::SignList signs;
	map->getSignsInArea( minx, maxx, miny, maxy, signs );
	char text[512];
	for( MCMap::SignList::const_iterator it = signs.begin(); it != signs.end(); ++it ) {
		char *t = &text[0];
		uint32_t n = uint32_t(sizeof(text));
		for( unsigned i = 0; i < 4; i++ ) {
			std::size_t ncopy = parseText( t, n, it->text[i], it->textLen[i] );
			n -= ncopy;
			t += ncopy;
			if( n ) {
				*t++ = '\n';
				n--;
			}
		}
		t[-1] = '\0';

		if( n == sizeof(text) - 4 )
			continue; // Skip empty signs
	
		geom::Point p = {{{ it->x, it->y, it->z }}};
		toLocalSpace( p );

		jMatrix mat;
		//jMatrixSetIdentity( &mat );
		jVec3Zero( &mat.up );
		jVec3Zero( &mat.right );
		//jVec3Set( &mat.right, 0.0f, 0.0f, 0.0f );
		jVec3Set( &mat.fwd, 0.0f, 0.0f, -8.0f );
		jVec3Set( &mat.pos, (float)(p.x * 16), (float)(p.y * 16), (float)(p.z * 16) );
		
		if( it->onWall ) {
			//assert( it->orientation >= 2 );
			
			unsigned ori = (it->orientation - 2) & 3;
			unsigned axis = ori >> 1;
			mat.right.v[axis ^ 1] = (ori & 1) ^ axis ? 16.0f : -16.0f;
			mat.pos.z += 12.0f;
			mat.pos.v[axis] += ori & 1 ? 2.1f : 13.9f;
			mat.pos.v[axis^1] += 8.0f;

			signGeom->emitSign( cluster, &mat, text );
		} else {
			// TODO: Floor signs
			//mat.pos.z += 16.0f;
		}
		
		//signGeom->emitSign( cluster, &mat, text );
	}
}

} // namespace eihort
