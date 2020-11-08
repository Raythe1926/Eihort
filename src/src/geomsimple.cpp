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

#include "geomsimple.h"
#include "eihortshader.h"
#include "lightmodel.h"

namespace eihort {
namespace geom {

// -=-=-=-=------------------------------------------------------=-=-=-=-
SimpleGeometry::SimpleGeometry()
: BlockGeometry()
{
}

// -----------------------------------------------------------------
SimpleGeometry::~SimpleGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *SimpleGeometry::newCluster() {
	return new SingleStreamGeometryCluster( this );
}

// -----------------------------------------------------------------
void SimpleGeometry::render( void *&metaData, RenderContext *ctx ) {
	// Simple geometry uses the "normal" shader
	ctx->shader->bindNormal();
	// .. and the light model for "top-facing" geometry
	ctx->lightModels[5].uploadGL();

	rawRender( metaData, ctx );
}

// -----------------------------------------------------------------
void SimpleGeometry::rawRender( void *&metaData, RenderContext *ctx ) {
	SingleStreamGeometryCluster::Meta *meta = (SingleStreamGeometryCluster::Meta*)metaData;

	// Set up our vertex and index buffers
	glEnableClientState( GL_VERTEX_ARRAY );
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	glVertexPointer( 3, GL_FLOAT, sizeof( Vertex ), (void*)meta->vtx_offset );
	glTexCoordPointer( 2, GL_FLOAT, sizeof( Vertex ), (void*)(meta->vtx_offset + 12) );

	// Draw the geometry
	ctx->renderedTriCount += meta->nTris;
	glDrawElements( GL_TRIANGLES, meta->nTris*3, meta->idxType, (void*)meta->idx_offset );

	// Clean up
	glDisableClientState( GL_VERTEX_ARRAY );
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );

	metaData = &meta[1];
}

// -----------------------------------------------------------------
void SimpleGeometry::emitSimpleQuad( GeometryStream *target, const jMatrix *loc, const jMatrix *tex ) {
	jMatrix id;
	if( tex == NULL ) {
		jMatrixSetIdentity( &id );
		tex = &id;
	}
	
	Vertex v;
	jVec3Scale( &v.pos, &loc->pos, 16.0f );
	v.u = tex->pos.x; v.v = tex->pos.z;
	
	unsigned idxBase = target->getIndexBase();

	target->emitVertex( v );
	jVec3MA( &v.pos, &loc->right, 16.0f, &v.pos );
	v.u += tex->right.x;
	v.v += tex->right.z;
	target->emitVertex( v );
	jVec3MA( &v.pos, &loc->up, 16.0f, &v.pos );
	v.u += tex->up.x;
	v.v += tex->up.z;
	target->emitVertex( v );
	jVec3MA( &v.pos, &loc->right, -16.0f, &v.pos );
	v.u -= tex->right.x;
	v.v -= tex->right.z;
	target->emitVertex( v );

	target->emitQuad( idxBase, idxBase+1, idxBase+2, idxBase+3 );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
RailGeometry::RailGeometry( unsigned txStraight, unsigned txTurn )
: texStraight(txStraight), texTurn(txTurn)
{
	rg = RenderGroup::OPAQUE + 100;
}

// -----------------------------------------------------------------
RailGeometry::~RailGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *RailGeometry::newCluster() {
	// Two clusters - one for each texture
	MultiGeometryCluster *clust = new MultiGeometryCluster;
	clust->newCluster( 0, new SingleStreamGeometryClusterEx<unsigned>( this, 0 ) );
	clust->newCluster( 1, new SingleStreamGeometryClusterEx<unsigned>( this, 1 ) );
	return clust;
}

// -----------------------------------------------------------------
void RailGeometry::render( void *&meta, RenderContext *ctx ) {
	glEnable( GL_TEXTURE_2D );
	glNormal3f( 0.0f, 0.0f, 1.0f );
	
	unsigned *mid = (unsigned*)meta;
	meta = &mid[1];
	if( mid[0] == 0 ) {
		glBindTexture( GL_TEXTURE_2D, texStraight );
		SimpleGeometry::render( meta, ctx );
	} else {
		glBindTexture( GL_TEXTURE_2D, texTurn );
		SimpleGeometry::render( meta, ctx );
	}

	glDisable( GL_TEXTURE_2D );
}

// -----------------------------------------------------------------
bool RailGeometry::beginEmit( GeometryCluster *outCluster, InstanceContext *ctx ) {
	outCluster = ((MultiGeometryCluster*)outCluster)->getCluster( ctx->block.data < 6 ? 0 : 1 );
	GeometryStream *out = ((SingleStreamGeometryClusterEx<unsigned>*)outCluster)->getStream();

	jVec3 v1, v2, v3, v4;
	float z = ctx->block.pos.z * 16.0f + 1.0f;
	float x = (float)ctx->block.pos.x * 16.0f, y = (float)ctx->block.pos.y * 16.0f;
	const float ONE = 16.0f; // One block is 16 pixels

	switch( ctx->block.data ) {
	case 0: // Flat east/west track
		jVec3Set( &v1, x, y, z );
		jVec3Set( &v2, x+ONE, y, z );
		jVec3Set( &v3, x+ONE, y+ONE, z );
		jVec3Set( &v4, x, y+ONE, z );
		break;
	case 1: // Flat north/south track
		jVec3Set( &v1, x+ONE, y, z );
		jVec3Set( &v2, x+ONE, y+ONE, z );
		jVec3Set( &v3, x, y+ONE, z );
		jVec3Set( &v4, x, y, z );
		break;
	case 3: // Ascending south
		jVec3Set( &v1, x, y+ONE, z );
		jVec3Set( &v2, x, y, z+ONE );
		jVec3Set( &v3, x+ONE, y, z+ONE );
		jVec3Set( &v4, x+ONE, y+ONE, z );
		break;
	case 2: // Ascending north
		jVec3Set( &v1, x+ONE, y, z );
		jVec3Set( &v2, x+ONE, y+ONE, z+ONE );
		jVec3Set( &v3, x, y+ONE, z+ONE );
		jVec3Set( &v4, x, y, z );
		break;
	case 5: // Ascending east
		jVec3Set( &v1, x, y, z );
		jVec3Set( &v2, x+ONE, y, z+ONE );
		jVec3Set( &v3, x+ONE, y+ONE, z+ONE );
		jVec3Set( &v4, x, y+ONE, z );
		break;
	case 4: // Ascending west
		jVec3Set( &v1, x+ONE, y+ONE, z );
		jVec3Set( &v2, x, y+ONE, z+ONE );
		jVec3Set( &v3, x, y, z+ONE );
		jVec3Set( &v4, x+ONE, y, z );
		break;
	case 7: // Northeast corner
		jVec3Set( &v1, x, y+ONE, z );
		jVec3Set( &v2, x, y, z );
		jVec3Set( &v3, x+ONE, y, z );
		jVec3Set( &v4, x+ONE, y+ONE, z );
		break;
	case 8: // Southeast corner
		jVec3Set( &v1, x+ONE, y+ONE, z );
		jVec3Set( &v2, x, y+ONE, z );
		jVec3Set( &v3, x, y, z );
		jVec3Set( &v4, x+ONE, y, z );
		break;
	case 9: // Southwest corner
		jVec3Set( &v1, x+ONE, y, z );
		jVec3Set( &v2, x+ONE, y+ONE, z );
		jVec3Set( &v3, x, y+ONE, z );
		jVec3Set( &v4, x, y, z );
		break;
	case 6: // Northwest corner
		jVec3Set( &v1, x, y, z );
		jVec3Set( &v2, x+ONE, y, z );
		jVec3Set( &v3, x+ONE, y+ONE, z );
		jVec3Set( &v4, x, y+ONE, z );
		break;
	}

	Vertex v;
	jVec3Copy( &v.pos, &v1 );
	v.u = 0.0f; v.v = 0.0f;
	
	unsigned idxBase = out->getIndexBase();

	out->emitVertex( v );
	jVec3Copy( &v.pos, &v2 );
	v.v += 1.0f;
	out->emitVertex( v );
	jVec3Copy( &v.pos, &v3 );
	v.u = 1.0f;
	out->emitVertex( v );
	jVec3Copy( &v.pos, &v4 );
	v.v = 0.0f;
	out->emitVertex( v );

	out->emitQuad( idxBase, idxBase+1, idxBase+2, idxBase+3 );

	return false;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
TorchGeometry::TorchGeometry( unsigned tx )
: tex(tx)
{
	rg = RenderGroup::OPAQUE + 100;
}

// -----------------------------------------------------------------
TorchGeometry::~TorchGeometry() {
}

// -----------------------------------------------------------------
void TorchGeometry::render( void *&meta, RenderContext *ctx ) {
	if( jVec3LengthSq( &ctx->viewPos ) > 200.0f*200.0f ) {
		meta = (char*)meta + sizeof(SingleStreamGeometryCluster::Meta);
		return;
	}

	glEnable( GL_BLEND );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, tex );
	
	ctx->shader->bindNormal();
	if( ctx->enableBlockLighting )
		ctx->shader->setLightOffset( 1.0f, 0.0f );
	SimpleGeometry::render( meta, ctx );
	ctx->shader->setLightOffset( 0.0f, 0.0f );

	glDisable( GL_TEXTURE_2D );
	glDisable( GL_BLEND );
}

// -----------------------------------------------------------------
bool TorchGeometry::beginEmit( GeometryCluster *outCluster, InstanceContext *ctx ) {
	GeometryStream *out = ((SingleStreamGeometryCluster*)outCluster)->getStream();

	jVec3 base, top;
	jVec3Set( &base, (float)ctx->block.pos.x, (float)ctx->block.pos.y, (float)ctx->block.pos.z );
	jVec3Copy( &top, &base );
	top.z += 1.0f;

	const float BASE_MOVE = 0.5f;
	const float ONWALL_MOVE_Z = 3.0f / 16.0f;
	const float TOP_MOVE = 2.0f/16.0f;
	const float TORCH_WIDTH = 2/16.0f;
	switch( ctx->block.data ) {
	case 1: // Pointing South
		top.y -= TOP_MOVE;
		base.y -= BASE_MOVE;
		top.z += ONWALL_MOVE_Z;
		base.z += ONWALL_MOVE_Z;
		break;
	case 2: // North
		top.y += TOP_MOVE;
		base.y += BASE_MOVE;
		top.z += ONWALL_MOVE_Z;
		base.z += ONWALL_MOVE_Z;
		break;
	case 3: // West
		top.x -= TOP_MOVE;
		base.x -= BASE_MOVE;
		top.z += ONWALL_MOVE_Z;
		base.z += ONWALL_MOVE_Z;
		break;
	case 4: // East
		top.x += TOP_MOVE;
		base.x += BASE_MOVE;
		top.z += ONWALL_MOVE_Z;
		base.z += ONWALL_MOVE_Z;
		break;
	case 5: // On floor
		break;
	}

	jMatrix pos, tx;
	jMatrixSetIdentity( &tx );

	// Y+ Side
	tx.pos.z = 1.0f;
	tx.up.z = -1.0f;
	jVec3Subtract( &pos.up, &top, &base );
	jVec3Copy( &pos.pos, &base );
	jVec3Set( &pos.right, 1.0f, 0.0f, 0.0f );
	pos.pos.y += 0.5f - TORCH_WIDTH/2;
	emitSimpleQuad( out, &pos, &tx );

	// Y- Side
	pos.right.x = -1.0f;
	pos.pos.y += TORCH_WIDTH;
	pos.pos.x += 1.0f;
	emitSimpleQuad( out, &pos, &tx );

	// X+ Side
	pos.right.x = 0.0f;
	pos.right.y = 1.0f;
	pos.pos.y = base.y;
	pos.pos.x = base.x + 0.5f + TORCH_WIDTH/2;
	emitSimpleQuad( out, &pos, &tx );

	// X- Side
	pos.right.y = -1.0f;
	pos.pos.y += 1.0f;
	pos.pos.x -= TORCH_WIDTH;
	emitSimpleQuad( out, &pos, &tx );

	// Bottom
	jVec3Set( &pos.right, TORCH_WIDTH, 0.0f, 0.0f );
	jVec3Set( &pos.up, 0.0f, -TORCH_WIDTH, 0.0f );
	jVec3Copy( &pos.pos, &base );
	pos.pos.x += 0.5f - TORCH_WIDTH/2;
	pos.pos.y += 0.5f + TORCH_WIDTH/2;
	tx.pos.x = 0.5f - TORCH_WIDTH/2;
	tx.pos.z = 1.0f;
	tx.right.x = TORCH_WIDTH;
	tx.up.z = -TORCH_WIDTH;
	emitSimpleQuad( out, &pos, &tx );

	// Top
	jVec3Set( &pos.right, TORCH_WIDTH, 0.0f, 0.0f );
	jVec3Set( &pos.up, 0.0f, TORCH_WIDTH, 0.0f );
	jVec3Lerp( &pos.pos, &base, &top, 0.5f + TORCH_WIDTH );
	pos.pos.x += 0.5f - TORCH_WIDTH/2;
	pos.pos.y += 0.5f - TORCH_WIDTH/2;
	tx.pos.x = 0.5f - TORCH_WIDTH/2;
	tx.pos.z = 0.5f;
	tx.right.x = TORCH_WIDTH;
	tx.up.z = -TORCH_WIDTH;
	emitSimpleQuad( out, &pos, &tx );

	return false;
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
XShapedBlockGeometry::XShapedBlockGeometry( unsigned tx )
: tex(tx)
{
	rg = RenderGroup::OPAQUE + 100;
}

// -----------------------------------------------------------------
XShapedBlockGeometry::~XShapedBlockGeometry() {
}

// -----------------------------------------------------------------
void XShapedBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	ctx->shader->bindNormal();
	ctx->lightModels[5].uploadGL();

	glDisable( GL_CULL_FACE );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, tex );
	rawRender( meta, ctx );
	glDisable( GL_TEXTURE_2D );
	glEnable( GL_CULL_FACE );
}

// -----------------------------------------------------------------
bool XShapedBlockGeometry::beginEmit( GeometryCluster*, InstanceContext *ctx ) {
	// Only emit one island - vertically
	for( unsigned i = 0; i < 6; i++ )
		ctx->sides[i].solid = true;
	ctx->sides[2].solid = false;

	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode XShapedBlockGeometry::beginIsland( IslandDesc *ctx ) {
	ctx->checkVisibility = false;
	ctx->checkFacingSameId = false;
	return ISLAND_SINGLE;
}

// -----------------------------------------------------------------
void XShapedBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	// TODO: Proper emit for reeds/tall grass.. this would probably
	// actually result in a decent speedboost

	GeometryStream *out = ((SingleStreamGeometryCluster*)outCluster)->getStream();

	jMatrix pos, tx;
	jMatrixSetIdentity( &tx );
	tx.pos.z = 1.0f;
	tx.up.z = -1.0f;

	// Make one diagonal
	jVec3Set( &pos.pos, (float)ctx->origin.block.pos.x, (float)ctx->origin.block.pos.y, (float)ctx->origin.block.pos.z );
	jVec3Set( &pos.up, 0.0f, 0.0f, 1.0f );
	jVec3Set( &pos.right, 1.0f, 1.0f, 0.0f );
	emitSimpleQuad( out, &pos, &tx );

	/*
	// Flip it around
	jVec3Add( &pos.pos, &pos.right, &pos.pos );
	jVec3Set( &pos.right, -1.0f, -1.0f, 0.0f );
	tx.pos.x = 1.0f;
	tx.right.x = -1.0f;
	emitSimpleQuad( out, &pos, &tx );
	*/

	// Make the other diagonal
	tx.pos.x = 0.0f;
	tx.right.x = 1.0f;
	jVec3Set( &pos.pos, (float)ctx->origin.block.pos.x, (float)ctx->origin.block.pos.y, (float)ctx->origin.block.pos.z );
	jVec3Set( &pos.up, 0.0f, 0.0f, 1.0f );
	jVec3Set( &pos.right, 1.0f, -1.0f, 0.0f );
	pos.pos.y += 1.0f;
	emitSimpleQuad( out, &pos, &tx );

	/*
	// Flip it around
	jVec3Add( &pos.pos, &pos.right, &pos.pos );
	jVec3Set( &pos.right, -1.0f, 1.0f, 0.0f );
	tx.pos.x = 1.0f;
	tx.right.x = -1.0f;
	emitSimpleQuad( out, &pos, &tx );
	*/
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
BiomeXShapedBlockGeometry::BiomeXShapedBlockGeometry( unsigned tx, unsigned biomeTex )
: XShapedBlockGeometry( tx ), biomeTex(biomeTex)
{
}

// -----------------------------------------------------------------
BiomeXShapedBlockGeometry::~BiomeXShapedBlockGeometry() {
}

// -----------------------------------------------------------------
void BiomeXShapedBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	// Use the only foliage shader
	ctx->shader->bindFoliage();
	ctx->lightModels[5].uploadGL();
	//ctx->shader->setLightOffset( 0.0f, 0.0f );

	glActiveTexture( GL_TEXTURE2 );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, ctx->biomeTextures[biomeTex] );
	glActiveTexture( GL_TEXTURE0 );

	// To use the foliage shader, we need a texture matrix
	glMatrixMode( GL_TEXTURE );
	const float texMat[] = {
		1.f/16, 0.f, 0.f, 0.f,
		0.f, 0.f, 0.f, 0.f,
		0.f, -1.f/16, 0.f, 0.f,
		0.f, 0.f, 0.f, 0.f
	};
	glLoadMatrixf( &texMat[0] );

	glDisable( GL_CULL_FACE );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, tex );
	rawRender( meta, ctx );
	glDisable( GL_TEXTURE_2D );
	glEnable( GL_CULL_FACE );

	glActiveTexture( GL_TEXTURE2 );
	glDisable( GL_TEXTURE_2D );
	glActiveTexture( GL_TEXTURE0 );
}


} // namespace geom
} // namespace eihort
