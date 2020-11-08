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
#include <cassert>
#include <cstring>

#include "geombase.h"
#include "geomadapter.h"
#include "geomsolid.h"
#include "geomsimple.h"
#include "eihortshader.h"
#include "lightmodel.h"
#include "uidrawcontext.h"

namespace eihort {
namespace geom {

// -=-=-=-=------------------------------------------------------=-=-=-=-
void GeometryStream::ensureVertCap( unsigned cap ) {
	if( !vertCapacity )
		vertCapacity = 128;

	while( vertCapacity < cap )
		vertCapacity <<= 1;

	void *newVerts = malloc( vertCapacity );
	memcpy( newVerts, verts, vertSize );
	free( verts );
	verts = newVerts;
}

// -----------------------------------------------------------------
void GeometryStream::emitVertex( const void *src, unsigned size ) {
	if( vertSize + size > vertCapacity )
		ensureVertCap( vertSize + size );
	memcpy( (unsigned char*)verts + vertSize, src, size );
	vertSize += size;
	vertCount++;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
GeometryCluster::GeometryCluster()
{
}

// -----------------------------------------------------------------
GeometryCluster::~GeometryCluster() {
}

// -----------------------------------------------------------------
unsigned GeometryCluster::getSmallestIndexSize( unsigned nVerts ) {
	if( nVerts < 256 ) {
		return 1;
	} else if( nVerts < 256*256 ) {
		return 2;
	} else {
		return 4;
	}
}

// -----------------------------------------------------------------
unsigned GeometryCluster::compressIndexBuffer( unsigned *indices, unsigned nVerts, unsigned nIndices ) {
	unsigned indexSize = getSmallestIndexSize( nVerts );

	if( indexSize == 4 )
		return 4; // Indices are already 4 bytes wide

	if( indexSize == 2 ) {
		// Compress to 2 bytes
		unsigned short *dest = (unsigned short*)indices;
		while( nIndices-- )
			*(dest++) = (unsigned short)*(indices++);
	} else {
		// Compress to 1 byte
		unsigned char *dest = (unsigned char*)indices;
		while( nIndices-- )
			*(dest++) = (unsigned char)*(indices++);
	}
	return indexSize;
}

// -----------------------------------------------------------------
unsigned GeometryCluster::indexSizeToGLType( unsigned size ) {
	switch( size ) {
	case 1: return GL_UNSIGNED_BYTE;
	case 2: return GL_UNSIGNED_SHORT;
	case 4: return GL_UNSIGNED_INT;
	default: assert(false);
	}
	return GL_UNSIGNED_INT;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
template<>
void SingleStreamGeometryClusterEx<EmptyStruct>::emitExtra( GeometryStream* ) {
	// This template specialization is here since sizeof(EmptyStruct) > 0,
	// yet we do not actually want to emit anything
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
MetaGeometryCluster::MetaGeometryCluster( BlockGeometry *geom )
: geom(geom), n(0)
{
}

// -----------------------------------------------------------------
MetaGeometryCluster::~MetaGeometryCluster() {
}

// -----------------------------------------------------------------
bool MetaGeometryCluster::destroyIfEmpty() {
	if( n == 0 ) {
		delete this;
		return true;
	}
	return false;
}

// -----------------------------------------------------------------
void MetaGeometryCluster::finalize( GeometryStream *meta, GeometryStream*, GeometryStream* ) {
	meta->emitVertex( geom );
	meta->emitVertex( n );
	meta->emitVertex( str.getVertices(), str.getVertSize() );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
MultiGeometryCluster::MultiGeometryCluster()
{
}

// -----------------------------------------------------------------
MultiGeometryCluster::~MultiGeometryCluster() {
}

// -----------------------------------------------------------------
bool MultiGeometryCluster::destroyIfEmpty() {
	bool nonEmpty = false;
	for( unsigned i = 0; i < clusters.size(); i++ ) {
		if( clusters[i] ) {
			if( clusters[i]->destroyIfEmpty() ) {
				clusters[i] = NULL;
			} else {
				nonEmpty = true;
			}
		}
	}

	if( !nonEmpty ) {
		delete this;
		return true;
	}

	return false;
}

// -----------------------------------------------------------------
void MultiGeometryCluster::finalize( GeometryStream *meta, GeometryStream *vtx, GeometryStream *idx ) {
	for( unsigned i = 0; i < clusters.size(); i++ ) {
		if( clusters[i] ) {
			clusters[i]->finalize( meta, vtx, idx );
			clusters[i] = NULL;
		}
	}
}

// -----------------------------------------------------------------
GeometryCluster *MultiGeometryCluster::getCluster( unsigned i ) {
	if( i >= clusters.size() )
		return NULL;
	return clusters[i];
}

// -----------------------------------------------------------------
void MultiGeometryCluster::newCluster( unsigned i, GeometryCluster *cluster ) {
	if( i >= clusters.size() )
		clusters.resize( i+1, NULL );
	assert( clusters[i] == NULL );
	clusters[i] = cluster;
}

// -----------------------------------------------------------------
void MultiGeometryCluster::storeContinueIsland( const IslandDesc *island ) {
	ciFn = island->continueIsland;
	ciCookie = island->cookie;
	cipCookie = island->pcookie;
	subCluster = island->curCluster;
}

// -----------------------------------------------------------------
bool MultiGeometryCluster::callContinueIsland( IslandDesc *island, const InstanceContext *nextBlock ) {
	if( !ciFn )
		return true;

	unsigned cookie = island->cookie;
	void *pcookie = island->pcookie;
	island->cookie = ciCookie;
	island->pcookie = cipCookie;
	island->curCluster = subCluster;
	bool ret = ciFn( island, nextBlock );
	island->cookie = cookie;
	island->pcookie = pcookie;
	island->curCluster = this;

	return ret;
}

// -=-=-=-=------------------------------------------------------=-=-=-=-
BlockGeometry::BlockGeometry() {
	rg = RenderGroup::LAST;
}

// -----------------------------------------------------------------
BlockGeometry::~BlockGeometry() {
}

// -----------------------------------------------------------------
void BlockGeometry::render( void *&meta, RenderContext *ctx ) {
	assert( false );
	(void)meta;
	(void)ctx;
}

// -----------------------------------------------------------------
void BlockGeometry::emitIsland( GeometryCluster*, const IslandDesc* ) {
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode BlockGeometry::beginIsland( IslandDesc* ) {
	return ISLAND_NORMAL;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
SignTextGeometry::SignTextGeometry()
{
	rg = RenderGroup::OPAQUE + 100;
}

// -----------------------------------------------------------------
SignTextGeometry::~SignTextGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *SignTextGeometry::newCluster() {
	return new MetaGeometryCluster( this );
}

// -----------------------------------------------------------------
void SignTextGeometry::render( void *&meta, RenderContext *ctx ) {
	char *cursor = (char*)meta;
	unsigned n = *(unsigned*)cursor;
	cursor += sizeof(unsigned);

	// TODO: not sure what this means, but my signs get culled away
	 // and the torches use this as well
	const float SIGN_CUTOFF_DIST = 200.0f;

	if( jVec3LengthSq( &ctx->viewPos ) > SIGN_CUTOFF_DIST*SIGN_CUTOFF_DIST ) {
		// Signs are too far away - skip over all signtext metadata
		for( unsigned i = 0; i < n; i++ ) {
			cursor += 16*sizeof(float);
			unsigned len = *(unsigned*)cursor;
			cursor += sizeof(unsigned);
			cursor += len;
		}
	} else {
		// Ensure a "clean" GL state
		ctx->shader->unbind();
		LightModel::unloadGL();
		glActiveTexture( GL_TEXTURE1 );
		glDisable( GL_TEXTURE_3D );
		glActiveTexture( GL_TEXTURE0 );
		glDisable( GL_CULL_FACE );

		// Clear the texture matrix
		glMatrixMode( GL_TEXTURE );
		glPushMatrix();
		glLoadIdentity();
		glMatrixMode( GL_MODELVIEW );

		// Set up the UI draw context
		UIDrawContext draw( false );
		draw.setFontVectorsAA( 0.15f*.825f, 0.25f*.825f );
		draw.setWidth( 2.0f );
		draw.setHeight( 1.0f );
		draw.color( 0xff000000 );
		draw.setFormatColorBrightness( 1.f/2.5f );

		for( unsigned i = 0; i < n; i++ ) {
			// Push the transform to the sign
			glPushMatrix();
			glMultMatrixf( (float*)cursor );
			cursor += 16*sizeof(float);

			// Draw the text
			unsigned len = *(unsigned*)cursor;
			cursor += sizeof(unsigned);
			draw.moveTo( -1.0f, .045f );
			draw.layoutText( cursor );
			draw.drawText( UIDrawContext::CENTER );

			cursor += len;
			glPopMatrix();
		}

		// Undo the damage we did above
		glActiveTexture( GL_TEXTURE1 );
		glEnable( GL_TEXTURE_3D );
		glActiveTexture( GL_TEXTURE0 );
		glEnable( GL_CULL_FACE );

		glMatrixMode( GL_TEXTURE );
		glPopMatrix();
		glMatrixMode( GL_MODELVIEW );
	}

	meta = cursor;
}

// -----------------------------------------------------------------
bool SignTextGeometry::beginEmit( GeometryCluster*, InstanceContext* ) {
	return false;
}

// -----------------------------------------------------------------
void SignTextGeometry::emitSign( GeometryCluster *outCluster, const jMatrix *pos, const char *text ) {
	// Sign format in the metadata stream:
	//   float[16] GL_matrix;
	//   unsigned text_length; // includes the \0, and may include padding
	//   char[text_length] text; // \0-terminated UTF-8 string

	MetaGeometryCluster *out = static_cast<MetaGeometryCluster*>(outCluster);
	GeometryStream *str = out->getStream();
	float glMat[16];
	jMatrixToGL( &glMat[0], pos );
	str->emitVertex( &glMat[0], sizeof(glMat) );
	unsigned len = (strlen( text ) + 4) & ~3;
	str->emitVertex( len );
	str->emitVertex( text, len );
	out->incEntry();
}


// ===========================================================================
//  Lua functions

// -----------------------------------------------------------------
static unsigned luaL_checktextureid( lua_State *L, int idx ) {
	return (unsigned)luaL_checknumber( L, idx );
}

// -----------------------------------------------------------------
static unsigned luaL_opttextureid( lua_State *L, int idx, unsigned def ) {
	return (unsigned)luaL_optnumber( L, idx, def );
}

// -----------------------------------------------------------------
static void luaL_checkfacingtextures( lua_State *L, int idx, unsigned *tx ) {
	// Handles the variable amount of textures that can be passed
	// to one of the geometry generator creating functions

	tx[0] = luaL_checktextureid( L, idx );
	tx[1] = tx[2] = tx[3] = tx[0];
	tx[4] = luaL_opttextureid( L, idx+1, tx[0] );
	tx[5] = luaL_opttextureid( L, idx+2, tx[4] );
	if( lua_isnumber( L, idx+3 ) ) {
		tx[1] = tx[3] = tx[4];
		tx[4] = tx[5];
		tx[5] = luaL_checktextureid( L, idx+3 );
		if( lua_isnumber( L, idx + 4 ) ) {
			tx[2] = tx[4];
			tx[3] = tx[5];
			tx[4] = luaL_checktextureid( L, idx+4 );
			tx[5] = luaL_checktextureid( L, idx+5 );
			std::swap( tx[0], tx[2] );
			std::swap( tx[1], tx[3] );
		}
	}
}

// -----------------------------------------------------------------
int BlockGeometry::lua_setTexScale( lua_State *L ) {
	// geom:setTexScale( uscale, vscale )
	BlockGeometry *geom = getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );
	SolidBlockGeometry *solidGeom = dynamic_cast<SolidBlockGeometry*>( geom );
	luaL_argcheck( L, solidGeom, 1, "Geom must be a variant of a SolidBlockGeometry" );

	solidGeom->setTexScale( (float)luaL_checknumber( L, 2 ), (float)luaL_checknumber( L, 3 ) );
	return 0;
}

// -----------------------------------------------------------------
int BlockGeometry::lua_renderGroupAdd( lua_State *L ) {
	// geom:renderGroupAdd( n )
	BlockGeometry *geom = getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );
	geom->rg += (unsigned)luaL_checknumber( L, 2 );
	return 0;
}

// -----------------------------------------------------------------
int BlockGeometry::createDataAdapter( lua_State *L ) {
	// geom = eihort.geom.dataAdapter( mask, ... )
	unsigned mask = (unsigned)luaL_checknumber( L, 1 );
	BlockGeometry *geoms[16];
	int n = 2;
	for( unsigned i = 0; i < 16; i++ ) {
		if( (mask & i) == i ) {
			geoms[i] = getLuaObjectArg<BlockGeometry>( L, n, BLOCKGEOMETRY_META );
			n++;
		} else {
			geoms[i] = NULL;
		}
	}

	BlockGeometry *geom = new DataBasedMultiGeometryAdapter( mask, &geoms[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createRotatingAdapter( lua_State *L ) {
	// geom = eihort.geom.rotatingAdapter( geom1, geom2 )
	BlockGeometry *geoms[2];
	geoms[0] = getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );
	geoms[1] = getLuaObjectArg<BlockGeometry>( L, 2, BLOCKGEOMETRY_META );

	BlockGeometry *geom = new RotatingMultiGeometryAdapter( &geoms[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createFaceBitAdapter( lua_State *L ) {
	// geom = eihort.geom.faceBitAdapter( geom1, geom2 )
	BlockGeometry *subGeom = getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );

	BlockGeometry *geom = new FaceBitGeometryAdapter( subGeom );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createFacingAdapter( lua_State *L ) {
	// geom = eihort.geom.facingAdapter( geom1, geom2 )
	BlockGeometry *geoms[2];
	geoms[0] = lua_toboolean( L, 1 ) ? getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META ) : NULL;
	geoms[1] = getLuaObjectArg<BlockGeometry>( L, 2, BLOCKGEOMETRY_META );

	BlockGeometry *geom = new FacingMultiGeometryAdapter( geoms[0], geoms[1] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createTopDifferentAdapter( lua_State *L ) {
	// geom = eihort.geom.topDifferentAdapter( geom1, geom2, top )
	BlockGeometry *sideGeom = getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );
	BlockGeometry *diffGeom = getLuaObjectArg<BlockGeometry>( L, 2, BLOCKGEOMETRY_META );
	unsigned diffId = (unsigned)luaL_checknumber( L, 3 );

	BlockGeometry *geom = new TopModifiedMultiGeometryAdapter( sideGeom, diffGeom, diffId );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createOpaqueBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.opaqueBlock( tex... )
	unsigned tx[6];
	luaL_checkfacingtextures( L, 1, &tx[0] );

	BlockGeometry *geom = new SolidBlockGeometry( &tx[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createBrightOpaqueBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.brightOpaqueBlock( tex... )
	unsigned tx[6];
	luaL_checkfacingtextures( L, 1, &tx[0] );

	BlockGeometry *geom = new FullBrightBlockGeometry( &tx[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createTransparentBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.transparentBlock( tex... )
	unsigned tx[6];
	unsigned rg = (unsigned)luaL_checknumber( L, 1 );
	luaL_checkfacingtextures( L, 2, &tx[0] );

	BlockGeometry *geom = new TransparentSolidBlockGeometry( &tx[0] );
	geom->setRenderGroup( RenderGroup::TRANSPARENT + rg );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createSquashedBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.squashedBlock( top, bottom, tex... )
	unsigned tx[6];
	int top = (int)luaL_checknumber( L, 1 );
	int bottom = (int)luaL_checknumber( L, 2 );
	luaL_checkfacingtextures( L, 3, &tx[0] );

	BlockGeometry *geom = new SquashedSolidBlockGeometry( top, bottom, &tx[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createCompactedGeometry( lua_State *L ) {
	unsigned tx[6];
	int offsets[6];
	offsets[0] = (int)luaL_checknumber( L, 3 );
	offsets[1] = (int)luaL_checknumber( L, 4 );
	offsets[2] = (int)luaL_checknumber( L, 1 );
	offsets[3] = (int)luaL_checknumber( L, 2 );
	offsets[4] = (int)luaL_checknumber( L, 5 );
	offsets[5] = (int)luaL_checknumber( L, 6 );
	luaL_checkfacingtextures( L, 7, &tx[0] );

	BlockGeometry *geom = new CompactedSolidBlockGeometry( &offsets[0], &tx[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createMultiCompactedBlock( lua_State *L ) {
	std::vector<int*> allOffsets;
	std::vector<bool> showFace;

	luaL_argcheck( L, lua_istable(L,1), 1, "Expected table" );

	int n = lua_rawlen( L, 1 );
	if( n % 6 != 0 ) {
		lua_pushstring( L, "Invalid face offsets" );
		lua_error( L );
	}

	// Pull the offsets for all blocks from the table in arg 1
	// into a temporary structure
	n /= 6;
	unsigned emits = n;
	for( int i = 0; i < n; i++ ) {
		int *offsets = new int[6];
		allOffsets.push_back( offsets );
		for( int j = 0; j < 6; j++ ) {
			lua_rawgeti( L, 1, i*6+j+1 );
			if( !lua_isnumber( L, -1 ) ) {
				lua_pushstring( L, "Invalid face offsets" );
				lua_error( L );
			}
			lua_Number offNum = lua_tonumber( L, -1 );
			int off = (int)offNum;
			lua_pop( L, 1 );

			showFace.push_back( offNum < 0.0001 );
			offsets[j] = -abs(off);
		}
	}

	// Create the MultiCompactedBlockGeometry using the gathered offsets
	unsigned tx[6];
	luaL_checkfacingtextures( L, 2, &tx[0] );
	MultiCompactedBlockGeometry *geom = new MultiCompactedBlockGeometry( &allOffsets[0], emits, &tx[0] );

	// Use positive values as a flag to hide faces
	unsigned k = 0;
	for( unsigned i = 0; i < allOffsets.size(); i++ ) {
		for( unsigned j = 0; j < 6; j++, k++ ) {
			if( !showFace[k] )
				geom->showFace( i, j, false );
		}
		delete[] allOffsets[i];
	}

	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createMultiCompactedConnectedGeometry( lua_State *L ) {
	// geom = eihort.geom.multiCompactedConnectedBlock( offsets, tex... )
	std::vector<int*> allOffsets;
	std::vector<bool> showFace;
	unsigned emitsPerDir[3] = { 0u, 0u, 0u };

	// Get the islands to generate in each dimension
	for( unsigned dir = 0; dir < 3; dir++ ) {
		luaL_argcheck( L, lua_istable(L,dir+1), dir+1, "Expected table" );

		// Multiple complements of offsets can be set for each dimension,
		// creating multiple "elongated" blocks along those dimensions

		int n = lua_rawlen( L, dir+1 );
		if( n % 6 != 0 ) {
			lua_pushstring( L, "Invalid face offsets" );
			lua_error( L );
		}

		// Pull the offsets out of Lua's table and store them in
		// a temporary structure
		n /= 6;
		emitsPerDir[dir] = n;
		for( int i = 0; i < n; i++ ) {
			int *offsets = new int[6];
			allOffsets.push_back( offsets );
			for( int j = 0; j < 6; j++ ) {
				lua_rawgeti( L, dir+1, i*6+j+1 );
				if( !lua_isnumber( L, -1 ) ) {
					lua_pushstring( L, "Invalid face offsets" );
					lua_error( L );
				}
				lua_Number offNum = lua_tonumber( L, -1 );
				int off = (int)offNum;
				lua_pop( L, 1 );

				showFace.push_back( offNum < 0.0001 );
				offsets[j] = -abs(off);
			}
		}
	}

	// Create the CompactedIslandBlockGeometry with the stored offsets
	unsigned tx[6];
	luaL_checkfacingtextures( L, 4, &tx[0] );
	CompactedIslandBlockGeometry *geom = new CompactedIslandBlockGeometry( &allOffsets[0], &emitsPerDir[0], &tx[0] );

	// Use positive values as a flag to hide faces
	unsigned k = 0;
	for( unsigned i = 0; i < allOffsets.size(); i++ ) {
		for( unsigned j = 0; j < 6; j++, k++ ) {
			if( !showFace[k] )
				geom->showFace( i, j, false );
		}
		delete[] allOffsets[i];
	}

	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createBiomeOpaqueGeometry( lua_State *L ) {
	// geom = eihort.geom.biomeOpaqueBlock( channel, tex... )
	unsigned tx[6];
	unsigned biomeChannel = (unsigned)luaL_checknumber( L, 1 );
	luaL_checkfacingtextures( L, 2, &tx[0] );

	BlockGeometry *geom = new FoliageBlockGeometry( &tx[0], biomeChannel );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createBiomeAlphaOpaqueGeometry( lua_State *L ) {
	// geom = eihort.geom.biomeAlphaOpaqueBlock( channel, tex... )
	unsigned tx[6];
	unsigned biomeChannel = (unsigned)luaL_checknumber( L, 1 );
	luaL_checkfacingtextures( L, 2, &tx[0] );

	BlockGeometry *geom = new FoliageAlphaBlockGeometry( &tx[0], biomeChannel );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createPortalGeometry( lua_State *L ) {
	// geom = eihort.geom.portal( tex )
	unsigned tx = luaL_checktextureid( L, 1 );

	BlockGeometry *geom = new PortalBlockGeometry( tx );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createHashShapedBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.hashShapedBlock( X1, X2, Y1, Y2, tex... )
	unsigned tx[6];
	int offsets[6];

	// Get the offsets from Lua as either a number, or a table of 6 numbers
	if( lua_isnumber( L, 1 ) ) {
		int off = (int)luaL_checknumber( L, 1 );
		for( unsigned i = 0; i < 4; i++ )
			offsets[i] = off;
		offsets[4] = offsets[5] = 0;
	} else {
		int n = lua_rawlen( L, 1 );
		luaL_argcheck( L, n == 1 || n == 6, 2, "Offset table must be one number or 6." );
		if( n == 1 ) {
			lua_rawgeti( L, 1, 1 );
			int off = (int)luaL_checknumber( L, -1 );
			lua_pop( L, 1 );
			for( unsigned i = 0; i < 6; i++ )
				offsets[i] = off;
		} else {
			for( unsigned i = 0; i < 6; i++ ) {
				lua_rawgeti( L, 1, i + 1 );
				int off = (int)luaL_checknumber( L, -1 );
				lua_pop( L, 1 );
				offsets[i] = off;
			}
		}
	}
	luaL_checkfacingtextures( L, 2, &tx[0] );

	BlockGeometry *geom = new HashShapedBlockGeometry( &tx[0], offsets );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createBiomeHashShapedBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.biomeHashShapedBlock( channel, X1, X2, Y1, Y2, tex... )
	unsigned tx[6];
	int offsets[6];
	int biomeChannel = (int)luaL_checknumber( L, 1 );
	
	// Get the offsets from Lua as either a number, or a table of 6 numbers
	if( lua_isnumber( L, 2 ) ) {
		int off = (int)luaL_checknumber( L, 2 );
		for( unsigned i = 0; i < 4; i++ )
			offsets[i] = off;
		offsets[4] = offsets[5] = 0;
	} else if( lua_istable( L, 2 ) ) {
		int n = lua_rawlen( L, 2 );
		luaL_argcheck( L, n == 1 || n == 6, 2, "Offset table must be one number or 6." );
		if( n == 1 ) {
			lua_rawgeti( L, 2, 1 );
			int off = (int)luaL_checknumber( L, -1 );
			lua_pop( L, 1 );
			for( unsigned i = 0; i < 6; i++ )
				offsets[i] = off;
		} else {
			for( unsigned i = 0; i < 6; i++ ) {
				lua_rawgeti( L, 2, i + 1 );
				int off = (int)luaL_checknumber( L, -1 );
				lua_pop( L, 1 );
				offsets[i] = off;
			}
		}
	}
	luaL_checkfacingtextures( L, 3, &tx[0] );

	BlockGeometry *geom = new BiomeHashShapedBlockGeometry( &tx[0], biomeChannel, offsets );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createRailGeometry( lua_State *L ) {
	// geom = eihort.geom.rail( texStraight, texTurn )
	unsigned txStraight = luaL_checktextureid( L, 1 );
	unsigned txTurn = luaL_opttextureid( L, 2, txStraight );

	BlockGeometry *geom = new RailGeometry( txStraight, txTurn );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createDoorGeometry( lua_State *L ) {
	// geom = eihort.geom.door( tex )
	unsigned tx = luaL_checktextureid( L, 1 );

	BlockGeometry *geom = new DoorBlockGeometry( tx );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createStairsGeometry( lua_State *L ) {
	// geom = eihort.geom.stairs( tex... )
	unsigned tx[6];
	luaL_checkfacingtextures( L, 1, &tx[0] );

	BlockGeometry *geom = new StairsBlockGeometry( &tx[0] );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createTorchGeometry( lua_State *L ) {
	// geom = eihort.geom.torch( tex )
	unsigned tx = luaL_checktextureid( L, 1 );

	BlockGeometry *geom = new TorchGeometry( tx );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createXShapedBlockGeometry( lua_State *L ) {
	// geom = eihort.geom.xShapedBlock( tex )
	unsigned tx = luaL_checktextureid( L, 1 );

	BlockGeometry *geom = new XShapedBlockGeometry( tx );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::createXShapedBlockBiomeGeometry( lua_State *L ) {
	// geom = eihort.geom.biomeXShapedBlock( channel, tex )
	unsigned biomeChannel = (unsigned)luaL_checknumber( L, 1 );
	unsigned tx = luaL_checktextureid( L, 2 );

	BlockGeometry *geom = new BiomeXShapedBlockGeometry( tx, biomeChannel );
	geom->setupLuaObject( L, BLOCKGEOMETRY_META );
	geom->lua_push();
	return 1;
}

// -----------------------------------------------------------------
int BlockGeometry::lua_destroy( lua_State *L ) {
	// geom:destroy()
	delete getLuaObjectArg<BlockGeometry>( L, 1, BLOCKGEOMETRY_META );
	*(void**)luaL_checkudata( L, 1, BLOCKGEOMETRY_META ) = NULL;
	return 0;
}

// -----------------------------------------------------------------
static const luaL_Reg BlockGeometry_functions[] = {
	{ "setTexScale", &BlockGeometry::lua_setTexScale },
	{ "renderGroupAdd", &BlockGeometry::lua_renderGroupAdd },
	{ "destroy", &BlockGeometry::lua_destroy },
	{ NULL, NULL }
};

// -----------------------------------------------------------------
static const luaL_Reg BlockGeometry_geom[] = {
	{ "dataAdapter", &BlockGeometry::createDataAdapter },
	{ "rotatingAdapter", &BlockGeometry::createRotatingAdapter },
	{ "faceBitAdapter", &BlockGeometry::createFaceBitAdapter },
	{ "facingAdapter", &BlockGeometry::createFacingAdapter },
	{ "topDifferentAdapter", &BlockGeometry::createTopDifferentAdapter },

	{ "opaqueBlock", &BlockGeometry::createOpaqueBlockGeometry },
	{ "brightOpaqueBlock", &BlockGeometry::createBrightOpaqueBlockGeometry },
	{ "transparentBlock", &BlockGeometry::createTransparentBlockGeometry },
	{ "squashedBlock", &BlockGeometry::createSquashedBlockGeometry },
	{ "compactedBlock", &BlockGeometry::createCompactedGeometry },
	{ "multiCompactedBlock", &BlockGeometry::createMultiCompactedBlock },
	{ "multiCompactedConnectedBlock", &BlockGeometry::createMultiCompactedConnectedGeometry },
	{ "biomeOpaqueBlock", &BlockGeometry::createBiomeOpaqueGeometry },
	{ "biomeAlphaOpaqueBlock", &BlockGeometry::createBiomeAlphaOpaqueGeometry },
	{ "portal", &BlockGeometry::createPortalGeometry },
	{ "hashShapedBlock", &BlockGeometry::createHashShapedBlockGeometry },
	{ "biomeHashShapedBlock", &BlockGeometry::createBiomeHashShapedBlockGeometry },
	{ "rail", &BlockGeometry::createRailGeometry },
	{ "door", &BlockGeometry::createDoorGeometry },
	{ "stairs", &BlockGeometry::createStairsGeometry },
	{ "torch", &BlockGeometry::createTorchGeometry },
	{ "xShapedBlock", &BlockGeometry::createXShapedBlockGeometry },
	{ "biomeXShapedBlock", &BlockGeometry::createXShapedBlockBiomeGeometry },

	{ NULL, NULL }
};

// -----------------------------------------------------------------
void BlockGeometry::setupLua( lua_State *L ) {
	luaL_newmetatable( L, BLOCKGEOMETRY_META );
	lua_pushvalue( L, -1 );
	lua_setfield( L, -2, "__index" );
	luaL_setfuncs( L, &BlockGeometry_functions[0], 0 );
	lua_pop( L, 1 );

	lua_newtable( L );
	luaL_setfuncs( L, &BlockGeometry_geom[0], 0 );
	lua_setfield( L, -2, "geom" );
}

} // namespace geom
} // namespace eihort
