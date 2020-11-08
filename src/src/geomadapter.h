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

#ifndef GEOMADAPTER_H
#define GEOMADAPTER_H

#include <cstdlib>
#include <vector>
#include "jmath.h"
#include "geombase.h"

namespace eihort {
namespace geom {

class ForwardingMultiGeometryAdapter : public BlockGeometry {
	// Parent class for geometry adapters which forward their responsibilities
	// to other BlockGeometry objects

public:
	ForwardingMultiGeometryAdapter();
	virtual ~ForwardingMultiGeometryAdapter();

	virtual GeometryCluster *newCluster();

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );
	virtual void emitIsland( GeometryCluster *out, const IslandDesc *ctx );
	virtual IslandMode beginIsland( IslandDesc *ctx );

protected:
	// Selects which BlockGeometry to use based on the block context
	virtual unsigned selectGeometry( const InstanceContext *ctx ) = 0;
	// Selects which BlockGeometry to use based on the island context
	virtual unsigned selectGeometry( const IslandDesc *ctx );
	// continueIsland callback which simply forwards the call to the appropriate BlockGeometry objects
	static bool continueIsland( IslandDesc *island, const InstanceContext *nextBlock );

	// The possible BlockGeometry objects beneath this object
	BlockGeometry *geoms[16];
};

class DataBasedMultiGeometryAdapter : public ForwardingMultiGeometryAdapter {
	// A ForwardingMultiGeometryAdapter which selects which geometry
	// to use based on the data field associated with the block id.
	// For wool, slabs, wood, etc...

public:
	DataBasedMultiGeometryAdapter( unsigned mask, BlockGeometry **geoms );
	virtual ~DataBasedMultiGeometryAdapter();

	virtual bool beginEmit( GeometryCluster *out, InstanceContext *ctx );
	virtual IslandMode beginIsland( IslandDesc *ctx );

protected:
	virtual unsigned selectGeometry( const InstanceContext *ctx );
	static bool continueIsland( IslandDesc *island, const InstanceContext *nextBlock );

	unsigned mask;
};

class RotatingMultiGeometryAdapter : public ForwardingMultiGeometryAdapter {
	// A ForwardingMultiGeometryAdapter which puts different geometry on
	// different faces based on the data field associated with the block id.
	// Made pumpkins and jack-o-lanterns

public:
	RotatingMultiGeometryAdapter( BlockGeometry **geoms, unsigned *sideToGeoms = NULL );
	virtual ~RotatingMultiGeometryAdapter();

private:
	virtual unsigned selectGeometry( const InstanceContext *ctx );
	virtual unsigned selectGeometry( const IslandDesc *ctx );

	unsigned sideToGeom[6];
};

class FaceBitGeometryAdapter : public ForwardingMultiGeometryAdapter {
	// A ForwardingMultiGeometryAdapter which only forwards if the
	// corresponding bit in the data field is set.
	// Made for vines

public:
	FaceBitGeometryAdapter( BlockGeometry *geom );
	virtual ~FaceBitGeometryAdapter();

private:
	virtual unsigned selectGeometry( const InstanceContext *ctx );
	virtual unsigned selectGeometry( const IslandDesc *ctx );
};

class FacingMultiGeometryAdapter : public ForwardingMultiGeometryAdapter {
	// A ForwardingMultiGeometryAdapter which puts different geometry on
	// different faces based on the data field associated with the block id.
	// The order is slightly different from RotatingMultiGeometryAdapter.
	// Mainly for furnaces, dispensers and ladders

public:
	FacingMultiGeometryAdapter( BlockGeometry *geom1, BlockGeometry *geom2 );
	virtual ~FacingMultiGeometryAdapter();

private:
	virtual unsigned selectGeometry( const InstanceContext *ctx );
	virtual unsigned selectGeometry( const IslandDesc *ctx );
};

class TopModifiedMultiGeometryAdapter : public ForwardingMultiGeometryAdapter {
	// A ForwardingMultiGeometryAdapter which uses a 'modified' block
	// type when the block on top of the current block has a specific ID.
	// Made for grass/snowy grass

public:
	TopModifiedMultiGeometryAdapter( BlockGeometry *normal, BlockGeometry *modified, unsigned modifier );
	virtual ~TopModifiedMultiGeometryAdapter();

private:
	virtual unsigned selectGeometry( const InstanceContext *ctx );
	virtual unsigned selectGeometry( const IslandDesc *ctx );

	// Block ID that causes the modification
	unsigned modifier;
};

} // namespace geom
} // namespace eihort

#endif
