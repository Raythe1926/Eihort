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


#include <new>
#include <cassert>
#include <GL/glew.h>
#include "worldmeshbuilder.h"
#include "worldmesh.h"
#include "geombase.h"
#include "mcbiome.h"
#include "mcblockdesc.h"

namespace eihort {

// ============================ WorldMeshSection =============================

WorldMeshSection::WorldMeshSection( const WorldMeshSectionData &data )
: biomeSrc(data.biomeSrc), lightTex(0), meta(NULL)
, opaqueEnd(0), transpEnd(0), vtx_vbo(0), idx_vbo(0)
, vtxMem(0), idxMem(0), texMem(0)
{
	opaqueEnd = data.opaqueEnd;
	transpEnd = data.transpEnd;

	if( transpEnd > 0 ) {
		// Store the meta buffer in a block of memory tailored to its size
		meta = malloc( data.metaStream.getVertSize() );
		memcpy( meta, data.metaStream.getVertices(), data.metaStream.getVertSize() );

		// Generate and upload the vertex and index VBOs
		glGenBuffers( 1, &vtx_vbo );
		glBindBuffer( GL_ARRAY_BUFFER, vtx_vbo );
		glBufferData( GL_ARRAY_BUFFER, data.vtxStream.getVertSize(), data.vtxStream.getVertices(), GL_STATIC_DRAW );
		vtxMem += data.vtxStream.getVertSize();

		glGenBuffers( 1, &idx_vbo );
		glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, idx_vbo );
		glBufferData( GL_ELEMENT_ARRAY_BUFFER, data.idxStream.getVertSize(), data.idxStream.getVertices(), GL_STATIC_DRAW );
		idxMem += data.idxStream.getVertSize();

		glBindBuffer( GL_ARRAY_BUFFER, 0 );
		glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );

		// Generate and upload the lighting texture
		glGenTextures( 1, &lightTex );
		glEnable( GL_TEXTURE_3D );
		glBindTexture( GL_TEXTURE_3D, lightTex );

		glTexParameterf (GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameterf (GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glTexParameterf (GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf (GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameterf (GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

		glTexParameteri( GL_TEXTURE_3D, GL_GENERATE_MIPMAP, GL_FALSE ); 

		glTexImage3D( GL_TEXTURE_3D, 0, GL_LUMINANCE4_ALPHA4, data.ltSzX, data.ltSzY, data.ltSzZ, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, data.lightingTex.data() );
		texMem += data.ltSzX * data.ltSzY * data.ltSzZ;

		glDisable( GL_TEXTURE_3D );
		glBindTexture( GL_TEXTURE_3D, 0 );

		// Generate and upload the biome textures
		biomeSrc = data.biomeSrc;
		texMem += biomeSrc->finalizeBiomeTextures( data.biomeCoords, unsigned(data.ltSzX), unsigned(data.ltSzY), &biomeTex[0] );
	} else {
		// Empty mesh
		meta = NULL;
		cost = 0;

		biomeSrc = NULL;
		biomeTex[0] = 0;
		biomeTex[1] = 0;
		biomeTex[2] = 0;
	}

	origin[0] = data.origin[0];
	origin[1] = data.origin[1];
	origin[2] = data.origin[2];
	lightTexScale[0] = (1.0/16.0) / data.ltSzX;
	lightTexScale[1] = (1.0/16.0) / data.ltSzY;
	lightTexScale[2] = (1.0/16.0) / data.ltSzZ;
}

// -----------------------------------------------------------------
WorldMeshSection::~WorldMeshSection() {
	if( lightTex )
		glDeleteTextures( 1, &lightTex );

	if( biomeSrc )
		biomeSrc->freeBiomeTextures( &biomeTex[0] );

	if( meta ) {
		glDeleteBuffers( 1, &vtx_vbo );
		glDeleteBuffers( 1, &idx_vbo );
		free( meta );
	}
}

// -----------------------------------------------------------------
void WorldMeshSection::renderOpaque( geom::RenderContext *ctx ) {
	if( opaqueEnd > 0 ) {
		beginRender( ctx );
		jVec3 oldViewPos;
		jVec3Copy( &oldViewPos, &ctx->viewPos );
		ctx->viewPos.x -= (float)origin[0];
		ctx->viewPos.y -= (float)origin[1];
		ctx->viewPos.z -= (float)origin[2];
		ctx->vertexSize += vtxMem;
		ctx->indexSize += idxMem;
		ctx->texSize += texMem;
		
		unsigned char *cursor = (unsigned char*)meta;
		unsigned char *end = cursor + opaqueEnd;
		do {
			MeshMeta *mesh = (MeshMeta*)cursor;

			cursor += sizeof( MeshMeta );
			mesh->geom->render( (void*&)cursor, ctx );
		} while( cursor < end );

		jVec3Copy( &ctx->viewPos, &oldViewPos );
		endRender();
	}
}

// -----------------------------------------------------------------
void WorldMeshSection::renderTransparent( geom::RenderContext *ctx ) {
	if( transpEnd > opaqueEnd ) {
		beginRender( ctx );
		jVec3 oldViewPos;
		jVec3Copy( &oldViewPos, &ctx->viewPos );
		ctx->viewPos.x -= (float)origin[0];
		ctx->viewPos.y -= (float)origin[1];
		ctx->viewPos.z -= (float)origin[2];
		
		unsigned char *cursor = (unsigned char*)meta;
		unsigned char *end = cursor + transpEnd;
		cursor += opaqueEnd;
		do {

			MeshMeta *mesh = (MeshMeta*)cursor;

			cursor += sizeof( MeshMeta );
			mesh->geom->render( (void*&)cursor, ctx );
		} while( cursor < end );

		jVec3Copy( &ctx->viewPos, &oldViewPos );
		endRender();
	}
}

// -----------------------------------------------------------------
void WorldMeshSection::beginRender( geom::RenderContext *ctx ) {
	// Bind the giant vertex and index buffers
	glBindBuffer( GL_ARRAY_BUFFER, vtx_vbo );
	glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, idx_vbo );

	// Bind the lighting texture
	glActiveTexture( GL_TEXTURE1 );
	glEnable( GL_TEXTURE_3D );
	glBindTexture( GL_TEXTURE_3D, lightTex );
	
	// Set up the lighting scale
	glMatrixMode( GL_TEXTURE );
	glLoadIdentity();
	glTranslated( 0.5, 0.5, 0.5 );
	glScaled( lightTexScale[0], lightTexScale[1], lightTexScale[2] );
	
	glActiveTexture( GL_TEXTURE0 );

	// Translate to the origin
	glMatrixMode( GL_MODELVIEW );
	glPushMatrix();
	glTranslated( origin[0], origin[1], origin[2] );
	glScaled( 1.0/16.0, 1.0/16.0, 1.0/16.0 );

	// Point to the appropriate biome textures
	ctx->biomeTextures = biomeTex;
}

// -----------------------------------------------------------------
void WorldMeshSection::endRender() {
	glBindBuffer( GL_ARRAY_BUFFER, 0 );
	glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );

	glActiveTexture( GL_TEXTURE1 );
	glDisable( GL_TEXTURE_3D );
	glBindTexture( GL_TEXTURE_3D, 0 );

	glMatrixMode( GL_MODELVIEW );
	glPopMatrix();

	glMatrixMode( GL_TEXTURE );
	glLoadIdentity();
	glActiveTexture( GL_TEXTURE0 );
	glLoadIdentity();
}

// ================================ WorldMesh ================================

WorldMesh::WorldMesh( const std::list<WorldMeshSectionData> &data )
: vtxMem(0)
, idxMem(0)
, texMem(0)
, cost(0)
{
	nSections = data.size();
	sections = (WorldMeshSection*)malloc( sizeof(WorldMeshSection) * nSections );
	size_t i = 0;
	for( auto it = data.begin(); it != data.end(); ++it, ++i ) {
		WorldMeshSection *mesh = new(&sections[i]) WorldMeshSection( *it );
		vtxMem += mesh->vtxMem;
		idxMem += mesh->idxMem;
		texMem += mesh->texMem;
		cost += mesh->cost;
	}
}

// -----------------------------------------------------------------
WorldMesh::~WorldMesh() {
	for( size_t i = 0; i < nSections; i++ )
		sections[i].~WorldMeshSection();
	free( sections );
}

// -----------------------------------------------------------------
bool WorldMesh::isEmpty() const {
	for( size_t i = 0; i < nSections; i++ )
		if( !sections[i].isEmpty() )
			return false;
	return true;
}

// -----------------------------------------------------------------
void WorldMesh::renderOpaque( geom::RenderContext *ctx ) {
	for( size_t i = 0; i < nSections; i++ )
		sections[i].renderOpaque( ctx );
}

// -----------------------------------------------------------------
void WorldMesh::renderTransparent( geom::RenderContext *ctx ) {
	for( size_t i = 0; i < nSections; i++ )
		sections[i].renderTransparent( ctx );
}

} // namespace eihort
