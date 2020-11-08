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
#include <cmath>
#include <cstring>

#include "geomsolid.h"
#include "triangle.h"
#include "eihortshader.h"
#include "lightmodel.h"

namespace eihort {
namespace geom {

// -=-=-=-=------------------------------------------------------=-=-=-=-
SolidBlockGeometry::SolidBlockGeometry( unsigned tx, unsigned color )
: color(color)
{
	rg = RenderGroup::OPAQUE;
	for( unsigned i = 0; i < 6; i++ )
		tex[i] = tx;
	xTexScale = 1.0f;
	yTexScale = 1.0f;
}

// -----------------------------------------------------------------
SolidBlockGeometry::SolidBlockGeometry( unsigned *tx, unsigned color )
: color(color)
{
	rg = RenderGroup::OPAQUE;
	for( unsigned i = 0; i < 6; i++ )
		tex[i] = tx[i];
	xTexScale = 1.0f;
	yTexScale = 1.0f;
}

// -----------------------------------------------------------------
SolidBlockGeometry::~SolidBlockGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *SolidBlockGeometry::newCluster() {
	return new SixSidedGeometryCluster( this );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::render( void *&metaData, RenderContext *ctx ) {
	ctx->shader->bindTexGen();
	applyColor();
	solidBlockRender( metaData, ctx );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::solidBlockRender( void *&metaData, RenderContext *ctx ) {
	// This is the heavily-optimized render function for most of the
	// geometry visible in a Minecraft world

	// Texture matrix generation parameters for each face
	static const unsigned TEX_MATRIX_X_COORD[] = { 4, 4, 0, 0, 4, 4 };
	static const float TEX_MATRIX_X_SCALE[] = { -1/16.0f, 1/16.0f, 1/16.0f, -1/16.0f, 1/16.0f, 1/16.0f };
	static const unsigned TEX_MATRIX_Y_COORD[] = { 9, 9, 9, 9, 1, 1 };
	static const float TEX_MATRIX_Y_SCALE[] = { -1/16.0f, -1/16.0f, -1/16.0f, -1/16.0f, -1/16.0f, 1/16.0f };

	// Geometry metadata is in SixSidedGeometryCluster format
	SixSidedGeometryCluster::Meta1 *m1 = (SixSidedGeometryCluster::Meta1*)metaData;
	SixSidedGeometryCluster::Meta2 *m2 = (SixSidedGeometryCluster::Meta2*)((char*)metaData + sizeof(SixSidedGeometryCluster::Meta1));

	// Set GL state
	glEnableClientState( GL_VERTEX_ARRAY );
	glEnable( GL_TEXTURE_2D );

	// Initialize the texture matrix
	glMatrixMode( GL_TEXTURE );
	float glmat[16];
	for( unsigned i = 0; i < 16; i++ )
		glmat[i] = 0.0f;

	// Previous texture ID
	unsigned prevT = 0;

	for( unsigned i = 0; i < m1->n; i++, m2++ ) {
		if( jPlaneDot3( &m2->cutoutPlane, &ctx->viewPos ) >= 0.0f ) {
			// This geometry is facing the camera

			// Change the texture if it is different
			if( prevT != tex[m2->dir] )
				glBindTexture( GL_TEXTURE_2D, prevT = tex[m2->dir] );

			// Set up face-specific GL states
			glVertexPointer( 3, GL_SHORT, sizeof( Vertex ), (void*)m2->vtx_offset );
			glNormal3fv( m2->cutoutPlane.n.v );
			ctx->lightModels[m2->dir].uploadGL();

			// Set up the texture matrix for this face
			unsigned texCoordX = TEX_MATRIX_X_COORD[m2->dir];
			unsigned texCoordY = TEX_MATRIX_Y_COORD[m2->dir];
			glmat[texCoordX] = TEX_MATRIX_X_SCALE[m2->dir] * xTexScale;
			glmat[texCoordY] = TEX_MATRIX_Y_SCALE[m2->dir] * yTexScale;
			glLoadMatrixf( &glmat[0] );

			// Actual draw call
			glDrawElements( GL_TRIANGLES, m2->nTris*3, m2->idxType, (void*)m2->idx_offset );
			ctx->renderedTriCount += m2->nTris;

			// Reset the texture matrix
			glmat[texCoordX] = 0.0f;
			glmat[texCoordY] = 0.0f;
		}
	}

	// Undo GL state damage
	glDisableClientState( GL_VERTEX_ARRAY );
	glDisable( GL_TEXTURE_2D );

	// Point the metadata pointer at the end of this geometry's metadata
	metaData = (void*)m2;
}

// -----------------------------------------------------------------
bool SolidBlockGeometry::beginEmit( GeometryCluster*, InstanceContext* ) {
	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode SolidBlockGeometry::beginIsland( IslandDesc *ctx ) {
	if( !tex[ctx->islandAxis] )
		return ISLAND_CANCEL;
	return BlockGeometry::beginIsland( ctx );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	emitContour( ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis ), ctx, 0 );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::emitContour( GeometryStream *out, const IslandDesc *ctx, int offsetPx ) {
	if( ctx->nContourPoints == 4 && ctx->nHoles == 0 ) {
		// Big quad
		emitQuad( out, ctx, offsetPx );
	} else {
		// Strange shape - send it through Triangle
		triangulateio triIn;
		triangulateio triOut;
		islandToTriangleIO( ctx, &triIn );
		triOut.pointlist = NULL;
		triOut.pointmarkerlist = NULL;
		triOut.trianglelist = NULL;
		triOut.segmentlist = NULL;
		triangulate( const_cast<char*>("QjzpBP"), &triIn, &triOut, NULL );
		freeIslandTriangleIO( &triIn );
		emitTriangulated( out, ctx, &triOut, offsetPx );
	}
}

// -----------------------------------------------------------------
unsigned SolidBlockGeometry::serializeContourPoints( const IslandDesc *ctx, unsigned nContourPoints, const Point *points, REALVec *outVec, int *segments, int baseSegIdx, std::vector<REALVec> &extraHoles ) {
	// This function builds the vertices which form the contour of an island
	// in a form to be sent to Triangle.
	
	unsigned pointCount = 1;
	int prevPoint = 0;

	outVec[0].v[0] = (double)ctx->xd1 * points[0].v[ctx->xax];
	outVec[0].v[1] = (double)ctx->yd1 * points[0].v[ctx->yax];
	segments[1] = baseSegIdx;

	for( unsigned i = 1; i < nContourPoints; i++ ) {
		double x = (double)ctx->xd1 * points[i].v[ctx->xax];
		double y = (double)ctx->yd1 * points[i].v[ctx->yax];
		unsigned pointIndex;

		// Here, we need to deal with the case where the contour meets
		// itself diagonally. I.e. the contour looks like a C
		// Even though the contour tracer will not detect that this is a hole,
		// Triangle requires us to create it as such.
		// TODO: Use a better algorithm for this!
		for( pointIndex = 0; pointIndex < pointCount; pointIndex++ ) {
			if( std::fabs( x - outVec[pointIndex].v[0] ) < 0.01 && std::fabs( y - outVec[pointIndex].v[1] ) < 0.01 ) {
				REALVec d1 = {{ outVec[pointIndex+1].v[0] - x, outVec[pointIndex+1].v[1] - y }};
				REALVec d2 = {{ outVec[prevPoint].v[0] - x, outVec[prevPoint].v[1] - y }};
				d1.scaleToLenAA( 0.5 );
				d2.scaleToLenAA( 0.5 );
				d1.add( d2 );
				REALVec v = outVec[pointIndex];
				v.add( d1 );
				extraHoles.push_back( v );
				goto found_identical_point;
			}
		}

		outVec[pointCount].v[0] = x;
		outVec[pointCount].v[1] = y;
		pointCount++;

	found_identical_point:
		segments[i<<1] = baseSegIdx + prevPoint;
		segments[(i<<1)+1] = baseSegIdx + pointIndex;
		prevPoint = pointIndex;
	}
	segments[0] = baseSegIdx + prevPoint;

	return pointCount;
}

// -----------------------------------------------------------------
void SolidBlockGeometry::islandToTriangleIO( const IslandDesc *ctx, struct triangulateio *out ) {
	std::vector< REALVec > extraHolePoints;

	unsigned totalPointCount = ctx->nContourPoints;
	if( ctx->nHoles )
		totalPointCount += ctx->holeContourEnd[ctx->nHoles-1];

	REALVec *contourReals = new REALVec[totalPointCount];
	out->pointlist = &contourReals[0].v[0];
	int *segments = new int[totalPointCount<<1];
	out->segmentlist = &segments[0];

	// Create vertices for the main contour
	unsigned pointCount = serializeContourPoints( ctx, ctx->nContourPoints, ctx->contourPoints, contourReals, segments, 0, extraHolePoints );
	
	if( ctx->nHoles ) {
		// Create vertices for all holes
		contourReals += pointCount;
		segments += ctx->nContourPoints<<1;
		unsigned contourPointIdx = 0;
		for( unsigned i = 0; i < ctx->nHoles; i++ ) {
			unsigned nPointsIn = ctx->holeContourEnd[i] - contourPointIdx;
			unsigned nPointsOut = serializeContourPoints( ctx, nPointsIn, ctx->holeContourPoints + contourPointIdx, contourReals, segments, pointCount, extraHolePoints );
			contourReals += nPointsOut;
			segments += nPointsIn<<1;
			contourPointIdx += nPointsIn;
			pointCount += nPointsOut;
		}
	}
	
	// Coalesce the hole list
	out->numberofholes = (int)(ctx->nHoles + (unsigned)extraHolePoints.size());
	if( out->numberofholes ) {
		REALVec *holes = new REALVec[out->numberofholes];
		out->holelist = &holes[0].v[0];
		unsigned i = 0;
		for( ; i < ctx->nHoles; i++ ) {
			holes[i].v[0] = (double)ctx->xd1 * ((double)ctx->holeInsidePoint[i].v[ctx->xax] + 0.5);
			holes[i].v[1] = (double)ctx->yd1 * ((double)ctx->holeInsidePoint[i].v[ctx->yax] + 0.5);
		}
		for( unsigned j = 0; j < extraHolePoints.size(); j++, i++ )
			holes[i] = extraHolePoints[j];
	}

	out->numberofpoints = pointCount;
	out->numberofpointattributes = 0;
	out->pointmarkerlist = NULL;
	out->numberofsegments = totalPointCount;
	out->segmentmarkerlist = NULL;
	out->numberofregions = 0;
}

// -----------------------------------------------------------------
void SolidBlockGeometry::freeIslandTriangleIO( triangulateio *out ) {
	delete[] out->segmentlist;
	delete[] out->pointlist;

	if( out->numberofholes )
		delete[] out->holelist;
}

// -----------------------------------------------------------------
void SolidBlockGeometry::emitTriangulated( GeometryStream *target, const IslandDesc *ctx, triangulateio *tri, int offsetPx ) {
	unsigned indexBase = target->getIndexBase();

	// Emit vertices
	Vertex vtx;
	vtx.pos[ctx->zax] = (short)(ctx->contourPoints[0].v[ctx->zax] * 16 + ctx->zd * offsetPx );
	for( unsigned i = 0; i < (unsigned)tri->numberofpoints; i++ ) {
		vtx.pos[ctx->xax] = (short)(ctx->xd1 * (int)floor( tri->pointlist[i<<1] ) * 16);
		vtx.pos[ctx->yax] = (short)(ctx->yd1 * (int)floor( tri->pointlist[(i<<1)+1] ) * 16);
		
		target->emitVertex( vtx );
	}

	// Emit indices
	int *triangle = tri->trianglelist;
	for( unsigned i = 0; i < (unsigned)tri->numberoftriangles; i++ ) {
		target->emitTriangle( (unsigned)triangle[0] + indexBase, (unsigned)triangle[1] + indexBase, (unsigned)triangle[2] + indexBase );
		triangle += 3;
	}

	trifree( tri->pointlist );
	trifree( tri->trianglelist );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::emitQuad( GeometryStream *target, const IslandDesc *ctx, int offsetPx ) {
	unsigned indexBase = target->getIndexBase();

	short offset = (short)(ctx->zd * offsetPx);
	Vertex vtx;
	for( unsigned i = 0; i < 4; i++ ) {
		vtx.pos[0] = (short)(ctx->contourPoints[i].x * 16);
		vtx.pos[1] = (short)(ctx->contourPoints[i].y * 16);
		vtx.pos[2] = (short)(ctx->contourPoints[i].z * 16);
		vtx.pos[ctx->zax] += offset;

		target->emitVertex( vtx );
	}

	target->emitQuad( indexBase, indexBase+1, indexBase+2, indexBase+3 );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::emitQuad( GeometryStream *target, const IslandDesc *ctx, int *offsets ) {
	unsigned indexBase = target->getIndexBase();

	// Find the max extents of the quad
	Point highPos = ctx->contourPoints[0];
	for( unsigned i = 1; i < 4; i++ ) {
		for( unsigned j = 0; j < 3; j++ ) {
			if( ctx->contourPoints[i].v[j] > highPos.v[j] )
				highPos.v[j] = ctx->contourPoints[i].v[j];
		}
	}
	if( (ctx->islandAxis & 1) == 0 )
		highPos.v[ctx->islandAxis >> 1]++;

	// Emit the quad with offsets
	Vertex vtx;
	for( unsigned i = 0; i < 4; i++ ) {
		vtx.pos[0] = (short)(ctx->contourPoints[i].x * 16 + (ctx->contourPoints[i].x == highPos.x ? offsets[1] : -offsets[0]));
		vtx.pos[1] = (short)(ctx->contourPoints[i].y * 16 + (ctx->contourPoints[i].y == highPos.y ? offsets[3] : -offsets[2]));
		vtx.pos[2] = (short)(ctx->contourPoints[i].z * 16 + (ctx->contourPoints[i].z == highPos.z ? offsets[5] : -offsets[4]));

		target->emitVertex( vtx );
	}

	target->emitQuad( indexBase, indexBase+1, indexBase+2, indexBase+3 );
}

// -----------------------------------------------------------------
void SolidBlockGeometry::applyColor() {
	float colors[4];
	colors[0] = ((color>>16)&0xff) / 255.0f;
	colors[1] = ((color>>8)&0xff) / 255.0f;
	colors[2] = (color&0xff) / 255.0f;
	colors[3] = 1.0f;
	glMaterialfv( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, &colors[0] );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
FoliageBlockGeometry::FoliageBlockGeometry( unsigned tx, unsigned foliageTex )
: SolidBlockGeometry(tx), foliageTex(foliageTex)
{
}

// -----------------------------------------------------------------
FoliageBlockGeometry::FoliageBlockGeometry( unsigned *tx, unsigned foliageTex )
: SolidBlockGeometry(tx), foliageTex(foliageTex)
{
}

// -----------------------------------------------------------------
FoliageBlockGeometry::~FoliageBlockGeometry() {
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode FoliageBlockGeometry::beginIsland( IslandDesc *ctx ) {
	ctx->checkFacingSameId = false;
	return SolidBlockGeometry::beginIsland( ctx );
}

// -----------------------------------------------------------------
void FoliageBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	ctx->shader->bindFoliage();
	applyColor();
	glActiveTexture( GL_TEXTURE2 );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, ctx->biomeTextures[foliageTex] );
	glActiveTexture( GL_TEXTURE0 );

	solidBlockRender( meta, ctx );

	glActiveTexture( GL_TEXTURE2 );
	glDisable( GL_TEXTURE_2D );
	glActiveTexture( GL_TEXTURE0 );
}

// -----------------------------------------------------------------
FoliageAlphaBlockGeometry::FoliageAlphaBlockGeometry( unsigned tx, unsigned foliageTex )
: FoliageBlockGeometry( tx, foliageTex )
{
}

// -----------------------------------------------------------------
FoliageAlphaBlockGeometry::FoliageAlphaBlockGeometry( unsigned *tx, unsigned foliageTex )
: FoliageBlockGeometry( tx, foliageTex )
{
}

// -----------------------------------------------------------------
FoliageAlphaBlockGeometry::~FoliageAlphaBlockGeometry() {
}

// -----------------------------------------------------------------
void FoliageAlphaBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	ctx->shader->bindFoliageAlpha();
	applyColor();
	glActiveTexture( GL_TEXTURE2 );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, ctx->biomeTextures[foliageTex] );
	glActiveTexture( GL_TEXTURE0 );

	solidBlockRender( meta, ctx );

	glActiveTexture( GL_TEXTURE2 );
	glDisable( GL_TEXTURE_2D );
	glActiveTexture( GL_TEXTURE0 );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
TransparentSolidBlockGeometry::TransparentSolidBlockGeometry( unsigned tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	rg = RenderGroup::TRANSPARENT;
}

// -----------------------------------------------------------------
TransparentSolidBlockGeometry::TransparentSolidBlockGeometry( unsigned *tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	rg = RenderGroup::TRANSPARENT;
}

// -----------------------------------------------------------------
TransparentSolidBlockGeometry::~TransparentSolidBlockGeometry() {
}

// -----------------------------------------------------------------
void TransparentSolidBlockGeometry::render( void *&metaData, RenderContext *ctx ) {
	glEnable( GL_BLEND );
	glAlphaFunc( GL_GREATER, 0.01f );
	SolidBlockGeometry::render( metaData, ctx );
	glAlphaFunc( GL_GREATER, 0.5f );
	glDisable( GL_BLEND );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
PortalBlockGeometry::PortalBlockGeometry( unsigned tx, unsigned color )
: TransparentSolidBlockGeometry(tx, color)
{
}

// -----------------------------------------------------------------
PortalBlockGeometry::~PortalBlockGeometry() {
}

// -----------------------------------------------------------------
void PortalBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *island ) {
	// Find the axis along which to draw the portal by checking the neighbouring block ids
	unsigned portalAxis = 0;
	if( island->origin.sides[2].id != island->origin.block.id && island->origin.sides[3].id != island->origin.block.id )
		portalAxis = 1;
	
	// Emit squashed geometry along the portal axis
	GeometryStream *out = ((SixSidedGeometryCluster*)outCluster)->getStream( island->islandAxis );
	if( (island->islandAxis >> 1) == portalAxis || island->nContourPoints != 4 ) {
		emitContour( out, island, -6 );
	} else {
		int offsets[6];
		for( unsigned i = 0; i < 6; i++ )
			offsets[i] = 0;
		offsets[portalAxis<<1] = offsets[(portalAxis<<1)+1] = -6;
		emitQuad( out, island, &offsets[0] );
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
HashShapedBlockGeometry::HashShapedBlockGeometry( unsigned tx, int *offsets )
: SolidBlockGeometry( tx )
{
	if( offsets ) {
		for( unsigned i = 0; i < 6; i++ )
			this->offsets[i] = offsets[i];
	} else {
		for( unsigned i = 0; i < 4; i++ )
			this->offsets[i] = -1;
		this->offsets[4] = 0;
		this->offsets[5] = 0;
	}
}

// -----------------------------------------------------------------
HashShapedBlockGeometry::HashShapedBlockGeometry( unsigned *tx, int *offsets )
: SolidBlockGeometry( tx )
{
	if( offsets ) {
		for( unsigned i = 0; i < 6; i++ )
			this->offsets[i] = offsets[i];
	} else {
		for( unsigned i = 0; i < 4; i++ )
			this->offsets[i] = -1;
		this->offsets[4] = 0;
		this->offsets[5] = 0;
	}
}

// -----------------------------------------------------------------
HashShapedBlockGeometry::~HashShapedBlockGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *HashShapedBlockGeometry::newCluster() {
	SixSidedGeometryCluster *cluster = new SixSidedGeometryCluster( this );
	jVec3 zero;
	jVec3Zero( &zero );
	for( unsigned i = 0; i < 4; i++ )
		cluster->setCutoutVector( i, &zero );
	return cluster;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode HashShapedBlockGeometry::beginIsland( IslandDesc *ctx ) {
	ctx->checkFacingSameId = false;
	ctx->checkVisibility = false;
	return SolidBlockGeometry::beginIsland( ctx );
}

// -----------------------------------------------------------------
void HashShapedBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	emitContour( ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis ), ctx, offsets[ctx->islandAxis] );
}

// -----------------------------------------------------------------
void HashShapedBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	glDisable( GL_CULL_FACE );
	SolidBlockGeometry::render( meta, ctx );
	glEnable( GL_CULL_FACE );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
BiomeHashShapedBlockGeometry::BiomeHashShapedBlockGeometry( unsigned tx, int channel, int *offsets )
: HashShapedBlockGeometry( tx, offsets ), biomeChannel(channel)
{
}

// -----------------------------------------------------------------
BiomeHashShapedBlockGeometry::BiomeHashShapedBlockGeometry( unsigned *tx, int channel, int *offsets )
: HashShapedBlockGeometry( tx, offsets ), biomeChannel(channel)
{
}

// -----------------------------------------------------------------
BiomeHashShapedBlockGeometry::~BiomeHashShapedBlockGeometry() {
}

// -----------------------------------------------------------------
void BiomeHashShapedBlockGeometry::render( void *&meta, RenderContext *ctx ) {
	ctx->shader->bindFoliage();
	applyColor();
	glActiveTexture( GL_TEXTURE2 );
	glEnable( GL_TEXTURE_2D );
	glBindTexture( GL_TEXTURE_2D, ctx->biomeTextures[biomeChannel] );
	glActiveTexture( GL_TEXTURE0 );
	glDisable( GL_CULL_FACE );

	solidBlockRender( meta, ctx );

	glEnable( GL_CULL_FACE );
	glActiveTexture( GL_TEXTURE2 );
	glDisable( GL_TEXTURE_2D );
	glActiveTexture( GL_TEXTURE0 );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
FullBrightBlockGeometry::FullBrightBlockGeometry( unsigned tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	rg = RenderGroup::OPAQUE;
}

// -----------------------------------------------------------------
FullBrightBlockGeometry::FullBrightBlockGeometry( unsigned *tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	rg = RenderGroup::OPAQUE;
}

// -----------------------------------------------------------------
FullBrightBlockGeometry::~FullBrightBlockGeometry() {
}

// -----------------------------------------------------------------
void FullBrightBlockGeometry::render( void *&metaData, RenderContext *ctx ) {
	ctx->shader->bindTexGen();
	if( ctx->enableBlockLighting )
		ctx->shader->setLightOffset( 1.0f, 1.0f );
	solidBlockRender( metaData, ctx );
	ctx->shader->setLightOffset( 0.0f, 0.0f );
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
SquashedSolidBlockGeometry::SquashedSolidBlockGeometry( int top, int bottom, unsigned tx, unsigned color )
: SolidBlockGeometry( tx, color )
, top(top)
, bottom(bottom)
{
}

// -----------------------------------------------------------------
SquashedSolidBlockGeometry::SquashedSolidBlockGeometry( int top, int bottom, unsigned *tx, unsigned color )
: SolidBlockGeometry( tx, color )
, top(top)
, bottom(bottom)
{
}

// -----------------------------------------------------------------
SquashedSolidBlockGeometry::~SquashedSolidBlockGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *SquashedSolidBlockGeometry::newCluster() {
	SixSidedGeometryCluster *cluster = new SixSidedGeometryCluster( this );
	jVec3 n;
	jVec3Set( &n, 0.0f, 0.0f, -(16-2*bottom) / 16.0f );
	cluster->setCutoutVector( 4, &n );
	jVec3Set( &n, 0.0f, 0.0f, (16-2*top) / 16.0f );
	cluster->setCutoutVector( 5, &n );

	return cluster;
}

// -----------------------------------------------------------------
bool SquashedSolidBlockGeometry::beginEmit( GeometryCluster*, InstanceContext *ctx ) {
	bool sidesAllSolid = ctx->sides[0].solid & ctx->sides[1].solid & ctx->sides[2].solid & ctx->sides[3].solid;
	if( top )
		ctx->sides[5].solid &= sidesAllSolid;
	if( bottom )
		ctx->sides[4].solid &= sidesAllSolid;
	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode SquashedSolidBlockGeometry::beginIsland( IslandDesc *ctx ) {
	IslandMode superMode = SolidBlockGeometry::beginIsland( ctx );
	if( ctx->islandAxis < 4 ) {
		// Lock the world Z axis
		if( ctx->xax == 2 ) {
			return (IslandMode)(superMode | ISLAND_LOCK_X);
		} else {
			return (IslandMode)(superMode | ISLAND_LOCK_Y);
		}
	} else {
		ctx->checkVisibility = !((ctx->islandAxis == 5 && top) || (bottom && ctx->islandAxis == 4));
		ctx->checkFacingSameId = ctx->checkVisibility;
		return superMode;
	}
}

// -----------------------------------------------------------------
void SquashedSolidBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	if( ctx->islandAxis >= 4 ) {
		emitContour( ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis ), ctx, ctx->islandAxis == 4 ? bottom : top );
	} else {
		// Islands on these axes can only be quads (the Z axis is locked)
		GeometryStream *target = ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis );
		unsigned indexBase = target->getIndexBase();

		// Which z level is the top?
		int topz = ctx->contourPoints[0].z;
		for( unsigned i = 1; i < 4; i++ ) {
			if( ctx->contourPoints[i].z > topz )
				topz = ctx->contourPoints[i].z;
		}

		// Emit the vertices
		Vertex vtx;
		for( unsigned i = 0; i < 4; i++ ) {
			vtx.pos[0] = (short)(ctx->contourPoints[i].x * 16);
			vtx.pos[1] = (short)(ctx->contourPoints[i].y * 16);
			// Offset the z axis
			vtx.pos[2] = (short)(ctx->contourPoints[i].z * 16 + (ctx->contourPoints[i].z == topz ? top : -bottom));

			target->emitVertex( vtx );
		}

		target->emitQuad( indexBase, indexBase+1, indexBase+2, indexBase+3 );
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
CompactedSolidBlockGeometry::CompactedSolidBlockGeometry( int *offsets, unsigned tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	for( unsigned i = 0; i < 6; i++ )
		this->offsets[i] = offsets[i];
	for( unsigned i = 0; i < 6; i += 2 )
		islandViable[i>>1] = offsets[i] == 0 && offsets[i+1] == 0;
	for( unsigned i = 0; i < 3; i++ )
		fullIslands[i] = islandViable[(i+1)%3] && islandViable[(i+2)%3];
}

// -----------------------------------------------------------------
CompactedSolidBlockGeometry::CompactedSolidBlockGeometry( int *offsets, unsigned *tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
	for( unsigned i = 0; i < 6; i++ )
		this->offsets[i] = offsets[i];
	for( unsigned i = 0; i < 6; i += 2 )
		islandViable[i>>1] = offsets[i] == 0 && offsets[i+1] == 0;
	for( unsigned i = 0; i < 3; i++ )
		fullIslands[i] = islandViable[(i+1)%3] && islandViable[(i+2)%3];
}

// -----------------------------------------------------------------
CompactedSolidBlockGeometry::~CompactedSolidBlockGeometry() {
}

// -----------------------------------------------------------------
GeometryCluster *CompactedSolidBlockGeometry::newCluster() {
	SixSidedGeometryCluster *cluster = new SixSidedGeometryCluster( this );
	for( unsigned i = 0; i < 6; i++ ) {
		jVec3 n;
		jVec3Set( &n, 0.0f, 0.0f, (16-2*offsets[i]) / (i&1 ? 16.0f : -16.0f) );
		cluster->setCutoutVector( 4, &n );
	}

	return cluster;
}

// -----------------------------------------------------------------
bool CompactedSolidBlockGeometry::beginEmit( GeometryCluster*, InstanceContext *ctx ) {
	for( unsigned i = 0; i < 6; i++ ) {
		if( offsets[i] != 0 ) {
			ctx->sides[i].solid = 0u;
		} else if( offsets[i^1] == 0 && ctx->sides[i].id == ctx->block.id ) {
			ctx->sides[i].solid = 1u;
		}
	}
	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode CompactedSolidBlockGeometry::beginIsland( IslandDesc *ctx ) {
	unsigned ret = SolidBlockGeometry::beginIsland( ctx );
	if( !islandViable[ctx->xax] )
		ret |= ISLAND_LOCK_X;
	if( !islandViable[ctx->yax] )
		ret |= ISLAND_LOCK_Y;

	ctx->checkVisibility = offsets[ctx->islandAxis] == 0;
	ctx->checkFacingSameId = false;

	return (IslandMode)ret;
}

// -----------------------------------------------------------------
void CompactedSolidBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	if( fullIslands[ctx->islandAxis>>1] ) {
		emitContour( ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis ), ctx, offsets[ctx->islandAxis] );
	} else {
		// Islands on these axes can only be quads
		GeometryStream *target = ((SixSidedGeometryCluster*)outCluster)->getStream( ctx->islandAxis );
		emitQuad( target, ctx, &offsets[0] );
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
MultiCompactedBlockGeometry::MultiCompactedBlockGeometry( int **offsets, unsigned nEmits, unsigned tx, unsigned color )
: SolidBlockGeometry(tx, color), offsets(NULL)
{
	setupOffsets( offsets, nEmits );
}

// -----------------------------------------------------------------
MultiCompactedBlockGeometry::MultiCompactedBlockGeometry( int **offsets, unsigned nEmits, unsigned *tx, unsigned color )
: SolidBlockGeometry(tx, color), offsets(NULL)
{
	setupOffsets( offsets, nEmits );
}

// -----------------------------------------------------------------
MultiCompactedBlockGeometry::~MultiCompactedBlockGeometry() {
	delete[] offsets;
}

// -----------------------------------------------------------------
bool MultiCompactedBlockGeometry::beginEmit( GeometryCluster*, InstanceContext *ctx ) {
	for( unsigned i = 0; i < 6; i++ )
		ctx->sides[i].solid = 0;
	
	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode MultiCompactedBlockGeometry::beginIsland( IslandDesc *island ) {
	island->checkFacingSameId = false;
	island->checkVisibility = false;
		
	return ISLAND_SINGLE;
}

// -----------------------------------------------------------------
void MultiCompactedBlockGeometry::emitIsland( GeometryCluster *out, const IslandDesc *island ) {
	OffsetSet *end = offsets + offsetCount;
	for( OffsetSet *o = offsets; o != end; o++ ) {
		if( o->hide[island->islandAxis] )
			continue;
			
		emitQuad( static_cast<SixSidedGeometryCluster*>(out)->getStream(island->islandAxis), island, &o->offsets[0] );
	}
}

// -----------------------------------------------------------------
void MultiCompactedBlockGeometry::setupOffsets( int **offsets, unsigned nEmits ) {
	offsetCount = nEmits;
	this->offsets = new OffsetSet[nEmits];
	
	for( unsigned i = 0; i < nEmits; i++ ) {
		OffsetSet *o = &this->offsets[i];
		for( unsigned j = 0; j < 6; j++ ) {
			o->offsets[j] = offsets[i][j];
			o->hide[j] = false;
		}
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
CompactedIslandBlockGeometry::CompactedIslandBlockGeometry( int **offsets, unsigned *nEmits, unsigned tx, unsigned color )
: SolidBlockGeometry(tx, color), offsets(NULL)
{
	setupOffsets( offsets, nEmits );
}

// -----------------------------------------------------------------
CompactedIslandBlockGeometry::CompactedIslandBlockGeometry( int **offsets, unsigned *nEmits, unsigned *tx, unsigned color )
: SolidBlockGeometry(tx, color), offsets(NULL)
{
	setupOffsets( offsets, nEmits );
}

// -----------------------------------------------------------------
CompactedIslandBlockGeometry::~CompactedIslandBlockGeometry() {
	delete[] offsets;
}

// -----------------------------------------------------------------
bool CompactedIslandBlockGeometry::beginEmit( GeometryCluster*, InstanceContext *ctx ) {
	for( unsigned i = 0; i < 6; i++ )
		ctx->sides[i].solid = 0;
	
	return true;
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode CompactedIslandBlockGeometry::beginIsland( IslandDesc *island ) {
	IslandMode mode = SolidBlockGeometry::beginIsland( island );
	island->checkFacingSameId = false;
	island->checkVisibility = false;
	for( ; island->islandIndex < 3; island->islandIndex++ ) {
		// Generate locked islands on each dimension

		if( (island->islandAxis >> 1) == island->islandIndex ) {
			if( island->origin.sides[island->islandAxis].id == island->origin.block.id )
				continue;
		} else if( !island->origin.sides[island->islandIndex<<1].outside && island->origin.sides[island->islandIndex<<1].id == island->origin.block.id ) {
			continue;
		}
		
		mode = (IslandMode)(mode | ISLAND_REPEAT);
		if( island->xax != island->islandIndex )
			mode = (IslandMode)(mode | ISLAND_LOCK_X);
		if( island->yax != island->islandIndex )
			mode = (IslandMode)(mode | ISLAND_LOCK_Y);
		return mode;
	}
	
	island->islandIndex = 0;
	return ISLAND_CANCEL;
}

// -----------------------------------------------------------------
void CompactedIslandBlockGeometry::emitIsland( GeometryCluster *out, const IslandDesc *island ) {
	OffsetSet *end = offsets + offsetStart[island->islandIndex+1];
	bool extendBackwards = island->origin.sides[island->islandIndex<<1].outside && island->origin.sides[island->islandIndex<<1].id == island->origin.block.id;
	for( OffsetSet *o = offsets + offsetStart[island->islandIndex]; o != end; o++ ) {
		if( o->hide[island->islandAxis] )
			continue;

		if( extendBackwards ) {
			// The island would have continued except it ran off the end of the qtree chunk
			// We need to extend it into the other chunk's space to pretend that the
			// geometry is contiguous
			int offsets[6];
			memcpy( &offsets[0], &o->offsets[0], sizeof(offsets) );
			unsigned i = island->islandIndex << 1;
			offsets[i] = -offsets[i+1];
			emitQuad( static_cast<SixSidedGeometryCluster*>(out)->getStream(island->islandAxis), island, &offsets[0] );
		} else {
			// Normal emit
			if( island->nContourBlocks == 1 ) {
				if( o->collapses )
					continue;
				// TODO: Reinstate this if:
				//if( o->offsets[island->islandAxis] == 0 && isSolidBlock( island->origin.sides[island->islandAxis].id, island->islandAxis ^ 1u ) ) // Face is flush?
				//	continue;
			}

			emitQuad( static_cast<SixSidedGeometryCluster*>(out)->getStream(island->islandAxis), island, &o->offsets[0] );
		}
	}
}

// -----------------------------------------------------------------
void CompactedIslandBlockGeometry::setupOffsets( int **offsets, unsigned *nEmits ) {
	unsigned nOffsetSets = 0;
	for( unsigned i = 0; i < 3; i++ )
		nOffsetSets += nEmits[i];
	this->offsets = new OffsetSet[nOffsetSets];
	
	unsigned inpOffset = 0;
	offsetStart[0] = 0;
	for( unsigned dim = 0; dim < 3; dim++ ) {
		for( unsigned i = 0; i < nEmits[dim]; i++ ) {
			OffsetSet *o = &this->offsets[inpOffset];
			for( unsigned j = 0; j < 6; j++ ) {
				o->offsets[j] = offsets[inpOffset][j];
				o->hide[j] = false;
			}
			o->collapses = false;
			for( unsigned i = 0; i < 3; i++ ) {
				if( o->offsets[i<<1] + o->offsets[(i<<1)+1] < -16 )
					o->collapses = true; // This island disappears if it is only one block long (e.g. fence slats)
			}
			inpOffset++;
		}
		offsetStart[dim+1] = inpOffset;
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
DoorBlockGeometry::DoorBlockGeometry( unsigned tx, unsigned color )
: SolidBlockGeometry(tx,color), texFlipped(tx,color)
{
	texFlipped.setTexScale( -1.0f, 1.0f );
}

// -----------------------------------------------------------------
DoorBlockGeometry::~DoorBlockGeometry() {
}
	
// -----------------------------------------------------------------
GeometryCluster *DoorBlockGeometry::newCluster() {
	MultiGeometryCluster *cluster = new MultiGeometryCluster;
	cluster->newCluster( 0, SolidBlockGeometry::newCluster() );
	cluster->newCluster( 1, texFlipped.newCluster() );
	return cluster;
}

// -----------------------------------------------------------------
static unsigned dataToIndentedDir( unsigned data ) {
	// Helper to translate door data to the side which is not flush
	// with other blocks
	bool open = (data & 4) != 0;
	data &= 3;
	if( open )
		data++;
	const unsigned DIR[] = { 3, 1, 2, 0, 3 };
	return DIR[data];
}

// -----------------------------------------------------------------
BlockGeometry::IslandMode DoorBlockGeometry::beginIsland( IslandDesc *island ) {
	IslandMode mode = SolidBlockGeometry::beginIsland( island );
	island->checkFacingSameId = false;

	// TODO: Update door geometry generation to the new data format
	unsigned data = island->origin.block.data;
	bool top = (data & 8) != 0;
	unsigned otherSide = top ? 4 : 5;
	if( island->origin.sides[otherSide].id == island->origin.block.id )
		island->origin.sides[otherSide].solid = true;

	island->origin.sides[dataToIndentedDir( data )].solid = false;
	
	return (IslandMode)(mode | ISLAND_SINGLE);
}

// -----------------------------------------------------------------
void DoorBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *ctx ) {
	MultiGeometryCluster *out = static_cast<MultiGeometryCluster*>(outCluster);

	const int DOOR_INDENTATION = -13;

	bool open = (ctx->origin.block.data & 4) != 0;
	unsigned indentedDir = dataToIndentedDir( ctx->origin.block.data );

	if( (ctx->islandAxis >> 1) == (indentedDir >> 1) ) {
		// This is a door face
		GeometryStream *tgt = static_cast<SixSidedGeometryCluster*>(out->getCluster(open ^ (ctx->islandAxis == indentedDir) ? 0 : 1))->getStream(ctx->islandAxis);
		emitContour( tgt, ctx, ctx->islandAxis == indentedDir ? DOOR_INDENTATION : 0 );
	} else {
		GeometryStream *tgt = static_cast<SixSidedGeometryCluster*>(out->getCluster(0))->getStream(ctx->islandAxis);
		int offsets[6];
		for( unsigned i = 0; i < 6; i++ )
			offsets[i] = 0;
		offsets[indentedDir] = DOOR_INDENTATION;
		
		emitQuad( tgt, ctx, &offsets[0] );
	}
}


// -=-=-=-=------------------------------------------------------=-=-=-=-
StairsBlockGeometry::StairsBlockGeometry( unsigned tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
}

// -----------------------------------------------------------------
StairsBlockGeometry::StairsBlockGeometry( unsigned *tx, unsigned color )
: SolidBlockGeometry( tx, color )
{
}

// -----------------------------------------------------------------
StairsBlockGeometry::~StairsBlockGeometry() {
}
	
// -----------------------------------------------------------------
BlockGeometry::IslandMode StairsBlockGeometry::beginIsland( IslandDesc *island ) {
	IslandMode mode = SolidBlockGeometry::beginIsland( island );
	unsigned asc = (island->origin.block.data & 3) ^ 3; // Stairs are ascending towards asc
	unsigned allowedAxis = (asc >> 1) ^ 1;
	unsigned inverted = island->origin.block.data & 4;

	island->continueIsland = &continueIsland;
	if( island->islandAxis >= 4 ) {
		island->checkFacingSameId = false;
		if( island->islandAxis == (inverted ? 5u : 4u) )
			return ISLAND_NORMAL;

		island->checkVisibility = false;
		return (IslandMode)(mode | (island->xax == allowedAxis ? ISLAND_LOCK_Y : ISLAND_LOCK_X));
	}

	island->checkFacingSameId = false;
	if( island->islandAxis == asc )
		return mode;

	island->checkVisibility = false;
	if( island->xax == allowedAxis )
		return (IslandMode)(mode | ISLAND_LOCK_Y);
	if( island->yax == allowedAxis )
		return (IslandMode)(mode | ISLAND_LOCK_X);
	return (IslandMode)(mode | ISLAND_SINGLE);
}

// -----------------------------------------------------------------
void StairsBlockGeometry::emitIsland( GeometryCluster *outCluster, const IslandDesc *island ) {
	SixSidedGeometryCluster *out = static_cast<SixSidedGeometryCluster*>(outCluster);

	unsigned asc = (island->origin.block.data & 3) ^ 3; // Ascending towards asc
	unsigned inverted = island->origin.block.data & 4;
	if( island->islandAxis == (inverted ? 5u : 4u) || island->islandAxis == asc ) {
		// Bottom (or top for inverted) or back face
		emitContour( out->getStream( island->islandAxis ), island, 0 );
	} else if( island->islandAxis == (inverted ? 4u : 5u) ) {
		// "Top" faces
		int offsets[6];
		for( unsigned i = 0; i < 6; i++ )
			offsets[i] = 0;
		offsets[asc^1] = -8;
		emitQuad( out->getStream( island->islandAxis ), island, &offsets[0] );
		offsets[asc^1] = 0;
		offsets[asc] = -8;
		offsets[inverted ? 4 : 5] = -8;
		emitQuad( out->getStream( island->islandAxis ), island, &offsets[0] );
	} else {//if( island->islandAxis == asc ^ 1 ) {
		// Front faces
		// TODO: Move side faces into a separate emit
		int offsets[6];
		for( unsigned i = 0; i < 6; i++ )
			offsets[i] = 0;
		offsets[inverted ? 4 : 5] = -8;
		emitQuad( out->getStream( island->islandAxis ), island, &offsets[0] );
		offsets[inverted ? 4 : 5] = 0;
		offsets[inverted ? 5 : 4] = -8;
		offsets[asc^1] = -8;
		emitQuad( out->getStream( island->islandAxis ), island, &offsets[0] );
	//} else {
	//	// Side faces
	//	assert( island->contourBlocks == 1 );
	}
}

// -----------------------------------------------------------------
bool StairsBlockGeometry::continueIsland( IslandDesc *island, const InstanceContext *nextBlock ) {
	return nextBlock->block.data == island->origin.block.data;
}


} // namespace geom
} // namespace eihort
