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

#ifndef EIHORTSHADER_H
#define EIHORTSHADER_H

#include "glshader.h"

namespace eihort {

class EihortShader {
	// Responsible for loading and maintaining a small set of
	// shaders used to draw everything

public:
	EihortShader();
	~EihortShader();

	// Bind the "normal" shader - XYZ and UV in vertices, one texture
	void bindNormal() { bindFlavour( &normal ); }
	// Bind the "UV-generating" shader - only XYZ in vertices, texture matrix is expected
	void bindTexGen() { bindFlavour( &texGen ); }
	// Bind the "biome" shader - XYZ in verts, UV generated, two textures (output = tex1 * tex2) 
	void bindFoliage() { bindFlavour( &foliage ); }
	// Bind the "biome-in-alpha" shader - XYZ in verts, UV generated, two textures (output = tex1 + tex1.a * tex2)
	void bindFoliageAlpha() { bindFlavour( &foliageAlpha ); }
	// Ensure that no shader is bound
	void unbind();

	// Adjust the lighting offset
	// The shader must be bound
	// Used to make certain sides of blocks darker
	void setLightOffset( float blockLight, float skyLight );

private:
	struct ShaderFlavour {
		// Link the given vertex and fragment shaders into a program
		void link( GLShaderObject *vs, GLShaderObject *fs, const char *name );

		// Actual GL shader
		GLShader shader;
		// The uniform index for lightOffset
		int lightOffsetUniform;
	};

	// Available shaders
	ShaderFlavour normal, texGen, foliage, foliageAlpha;
	// The currently bound shader
	ShaderFlavour *bound;

	// Binds the given shader
	void bindFlavour( ShaderFlavour *flv );

	// Vertex shader: XYZ + UV in verts
	GLShaderObject vtxObj;
	// Vertex shader: XYZ in verts, UV generated
	GLShaderObject vtxObjTexGen;
	// Fragment shader: One texture
	GLShaderObject fragObj;
	// Fragment shader: Two textures, output = tex1 * tex2
	GLShaderObject fragObjFoliage;
	// Fragment shader: Two textures, output = tex1 + tex1.a * tex2
	GLShaderObject fragObjFoliageAlpha;
};

} // namespace eihort

#endif
