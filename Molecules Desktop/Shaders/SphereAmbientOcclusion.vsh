//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

#define AMBIENTOCCLUSIONTEXTUREWIDTH 512.0
//#define AMBIENTOCCLUSIONTEXTUREWIDTH 2048.0

attribute vec3 position;
attribute vec2 inputImpostorSpaceCoordinate;
attribute vec2 ambientOcclusionTextureOffset;

varying highp vec2 impostorSpaceCoordinate;
varying mediump vec2 depthLookupCoordinate;
varying mediump vec3 normalizedViewCoordinate;
varying mediump float adjustedSphereRadius;
varying mediump vec3 adjustmentForOrthographicProjection;
varying mediump float depthAdjustmentForOrthographicProjection;

uniform highp mat3 modelViewProjMatrix;
uniform mediump float sphereRadius;
uniform mediump mat3 orthographicMatrix;
uniform mediump float ambientOcclusionTexturePatchWidth;

void main()
{
	vec3 transformedPosition = modelViewProjMatrix * position;
//    impostorSpaceCoordinate = inputImpostorSpaceCoordinate;
    vec2 adjustedImpostorSpaceCoordinate;
    if (inputImpostorSpaceCoordinate.x != 0.0)
    {
        adjustedImpostorSpaceCoordinate = sign(inputImpostorSpaceCoordinate);
    }
    else
    {
        adjustedImpostorSpaceCoordinate = vec2(0.0, 0.0);
    }
        
    
    impostorSpaceCoordinate = adjustedImpostorSpaceCoordinate * (1.0 + 2.0 / (AMBIENTOCCLUSIONTEXTUREWIDTH * ambientOcclusionTexturePatchWidth));

    adjustedSphereRadius = sphereRadius;
    
    transformedPosition = transformedPosition * orthographicMatrix;
    
    adjustmentForOrthographicProjection = (vec3(0.5, 0.5, 0.5) * orthographicMatrix).xyz;
    
    normalizedViewCoordinate = (transformedPosition / 2.0) + 0.5;

    gl_Position = vec4(ambientOcclusionTextureOffset * 2.0 - vec2(1.0) + (ambientOcclusionTexturePatchWidth * adjustedImpostorSpaceCoordinate), 0.0, 1.0);
}
