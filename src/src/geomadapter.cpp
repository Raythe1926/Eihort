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
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/

#include <GL/glew.h>
#include <cstring>

#include "geomadapter.h"

namespace eihort {
namespace geom {

// -=-=-=-=------------------------------------------------------=-=-=-=-
ForwardingMultiGeometryAdapter::ForwardingMultiGeometryAdapter() {
	for( unsigned i = 0; i < 16; i++ )
		geoms[i] = NULL;
}

// -----------------------------------------------------------------
ForwardingMultiGeometryAdapter::~ForwardingMultiGeometryAdapter() {
}

// -----------------------------------------------------------------
GeometryCluster *ForwardingMultiGeometryAdapter::newCluster() {
	return new MultiGeometryCluster;
}

// -----------------------------------------------------------------
bool ForwardingMultiGeometryAdapter::beginEmit( GeometryCluster *outCluster, InstanceContext *ctx ) {
	// Forward the beginEmit call to the appropriate BlockGeometry

	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(outCluster);
	unsigned idx = selectGeometry( ctx );
	assert( geoms[idx] );
	if( !out->getCluster( idx ) )
		out->newCluster( idx, geoms[idx]->newCluster() );
	return geoms[idx]->beginEmit( out->getCluster( idx ), ctx );
}

// -----------------------------------------------------------------
void ForwardingMultiGeometryAdapter::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	// Forward the emitIsland call to the appropriate BlockGeometry

	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(outCluster);
	unsigned idx = selectGeometry( ctx );
	assert( geoms[idx] );
	if( !out->getCluster( idx ) )
		out->newCluster( idx, geoms[idx]->newCluster() );
	geoms[idx]->emitIsland( out->getCluster( idx ), ctx );
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode ForwardingMultiGeometryAdapter::beginIsland( IslandDesc *ctx ) {
	// Forward the beginIsland call to the appropriate BlockGeometry

	unsigned idx = selectGeometry( ctx );
	if( !geoms[idx] )
		return ISLAND_CANCEL;

	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(ctx->curCluster);
	if( !out->getCluster( idx ) )
		out->newCluster( idx, geoms[idx]->newCluster() );
	GeometryCluster *subCluster = out->getCluster( idx );
	ctx->curCluster = subCluster;
	ctx->continueIsland = NULL;

	BlockGeometry::IslandMode ret = geoms[idx]->beginIsland( ctx );

	out->storeContinueIsland( ctx );
	ctx->continueIsland = &continueIsland;
	ctx->cookie = idx;
	ctx->pcookie = (void*)this;
	ctx->curCluster = out;
	return ret;
}

// -----------------------------------------------------------------
unsigned ForwardingMultiGeometryAdapter::selectGeometry( const IslandDesc *ctx ) {
	return selectGeometry( &ctx->origin );
}

// -----------------------------------------------------------------
bool ForwardingMultiGeometryAdapter::continueIsland( IslandDesc *island, const InstanceContext *nextBlock ) {
	IslandDesc ctx;
	memset(&ctx, 0, sizeof(ctx));
	ctx.origin = *nextBlock;
	ctx.islandAxis = island->islandAxis;
	return island->cookie == ((ForwardingMultiGeometryAdapter*)island->pcookie)->selectGeometry( &ctx )
		&& static_cast<MultiGeometryCluster*>(island->curCluster)->callContinueIsland( island, nextBlock );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
DataBasedMultiGeometryAdapter::DataBasedMultiGeometryAdapter( unsigned mask, BlockGeometry **geoms )
: mask(mask)
{
	assert( geoms[0] );
	rg = geoms[0]->getRenderGroup();
	for( unsigned i = 0; i < 16; i++ )
		this->geoms[i] = geoms[i];
}

// -----------------------------------------------------------------
DataBasedMultiGeometryAdapter::~DataBasedMultiGeometryAdapter() {
}

// -----------------------------------------------------------------
bool DataBasedMultiGeometryAdapter::beginEmit( GeometryCluster *outCluster, InstanceContext *ctx ) {
	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(outCluster);
	unsigned idx = selectGeometry( ctx );
	assert( geoms[idx] );
	if( !out->getCluster( idx ) )
		out->newCluster( idx, geoms[idx]->newCluster() );
	unsigned short oldData = ctx->block.data;
	ctx->block.data &= ~mask;
	bool ret = geoms[idx]->beginEmit( out->getCluster( idx ), ctx );
	ctx->block.data = oldData;
	return ret;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode DataBasedMultiGeometryAdapter::beginIsland( IslandDesc *ctx ) {
	unsigned idx = DataBasedMultiGeometryAdapter::selectGeometry( &ctx->origin );
	assert( geoms[idx] );
	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(ctx->curCluster);
	GeometryCluster *subCluster = out->getCluster( idx );
	assert( subCluster );
	ctx->curCluster = subCluster;
	ctx->continueIsland = NULL;

	BlockGeometry::IslandMode ret = geoms[idx]->beginIsland( ctx );

	out->storeContinueIsland( ctx );
	ctx->continueIsland = &continueIsland;
	ctx->cookie = mask;
	ctx->curCluster = out;
	return ret;
}

// -----------------------------------------------------------------
unsigned DataBasedMultiGeometryAdapter::selectGeometry( const InstanceContext *ctx ) {
	return ctx->block.data & mask;
}

// -----------------------------------------------------------------
bool DataBasedMultiGeometryAdapter::continueIsland( IslandDesc *island, const InstanceContext *nextBlock ) {
	return ((nextBlock->block.data ^ island->origin.block.data) & island->cookie) == 0
		&& static_cast<MultiGeometryCluster*>(island->curCluster)->callContinueIsland( island, nextBlock );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
RotatingMultiGeometryAdapter::RotatingMultiGeometryAdapter( BlockGeometry **geoms, unsigned *geomSides )
{
	unsigned defSides[6];
	if( !geomSides ) {
		geomSides = &defSides[0];
		defSides[0] = 1;
		for( unsigned i = 1; i < 6; i++ )
			defSides[i] = 0;
	}
	for( unsigned i = 0; i < 6; i++ ) {
		sideToGeom[i] = geomSides[i];
		this->geoms[sideToGeom[i]] = geoms[sideToGeom[i]];
	}
	rg = geoms[sideToGeom[5]]->getRenderGroup();
}

// -----------------------------------------------------------------
RotatingMultiGeometryAdapter::~RotatingMultiGeometryAdapter() {
}

// -----------------------------------------------------------------
unsigned RotatingMultiGeometryAdapter::selectGeometry( const InstanceContext* ) {
	return sideToGeom[0];
}

// -----------------------------------------------------------------
unsigned RotatingMultiGeometryAdapter::selectGeometry( const IslandDesc *ctx ) {
	if( ctx->islandAxis < 4 ) {
		unsigned dir = ((((ctx->islandAxis & 1) << 1) | ((ctx->islandAxis & 2) >> 1)) + 2) & 3;
		return sideToGeom[(ctx->origin.block.data + dir) & 3];
	} else {
		return sideToGeom[ctx->islandAxis];
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
FaceBitGeometryAdapter::FaceBitGeometryAdapter( BlockGeometry *geom )
{
	assert( geom );
	rg = geom->getRenderGroup();
	geoms[0] = geom;
	geoms[1] = NULL;
}

// -----------------------------------------------------------------
FaceBitGeometryAdapter::~FaceBitGeometryAdapter() {
}

// -----------------------------------------------------------------
unsigned FaceBitGeometryAdapter::selectGeometry( const InstanceContext* ) {
	return 0;
}

// -----------------------------------------------------------------
unsigned FaceBitGeometryAdapter::selectGeometry( const IslandDesc *ctx ) {
	if( ctx->islandAxis >= 4 ) {
		// TODO: Vines attach to the bottom of solid blocks
		return 1u;
	}

	unsigned ax = ((ctx->islandAxis & 1u) << 1) - (ctx->islandAxis >> 1);
	ax &= 3u;
	return ctx->origin.block.data & (1u << ax) ? 0u : 1u;
}

// -----------------------------------------------------------------
FacingMultiGeometryAdapter::FacingMultiGeometryAdapter( BlockGeometry *geom1, BlockGeometry *geom2 )
{
	assert( geom1 || geom2 );
	rg = geom1 ? geom1->getRenderGroup() : geom2->getRenderGroup();
	geoms[0] = geom1;
	geoms[1] = geom2;
}

// -----------------------------------------------------------------
FacingMultiGeometryAdapter::~FacingMultiGeometryAdapter() {
}

// -----------------------------------------------------------------
unsigned FacingMultiGeometryAdapter::selectGeometry( const InstanceContext* ) {
	return geoms[0] ? 0u : 1u;
}

// -----------------------------------------------------------------
unsigned FacingMultiGeometryAdapter::selectGeometry( const IslandDesc *ctx ) {
	return ctx->islandAxis == ctx->origin.block.data - 2u ? 1u : 0u;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
TopModifiedMultiGeometryAdapter::TopModifiedMultiGeometryAdapter( BlockGeometry *normal, BlockGeometry *modified, unsigned modifier )
: modifier(modifier)
{
	rg = normal->getRenderGroup();
	geoms[0] = normal;
	geoms[1] = modified;
}

// -----------------------------------------------------------------
TopModifiedMultiGeometryAdapter::~TopModifiedMultiGeometryAdapter() {
}

// -----------------------------------------------------------------
unsigned TopModifiedMultiGeometryAdapter::selectGeometry( const InstanceContext *ctx ) {
	return ctx->sides[5].id == modifier ? 1 : 0;
}

// -----------------------------------------------------------------
unsigned TopModifiedMultiGeometryAdapter::selectGeometry( const IslandDesc *ctx ) {
	return TopModifiedMultiGeometryAdapter::selectGeometry( &ctx->origin );
}

} // namespace geom
} // namespace eihort
