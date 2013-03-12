//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

attribute vec3 position;
attribute vec2 inputImpostorSpaceCoordinate;
attribute vec3 direction;
attribute vec2 ambientOcclusionTextureOffset;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump vec3 normalizedStartingCoordinate;
varying mediump vec3 normalizedEndingCoordinate;
varying mediump float halfCylinderRadius;
varying mediump vec3 adjustmentForOrthographicProjection;
varying mediump float depthAdjustmentForOrthographicProjection;

uniform mediump mat3 modelViewProjMatrix;
uniform mediump float cylinderRadius;
uniform mediump mat3 orthographicMatrix;
uniform mediump float ambientOcclusionTexturePatchWidth;

void main()
{
    vec3 transformedStartingCoordinate, transformedEndingCoordinate;
    
    if (inputImpostorSpaceCoordinate.t < 0.0)
    {
        transformedStartingCoordinate = modelViewProjMatrix * position;
        transformedEndingCoordinate = modelViewProjMatrix * (position + direction);
    }
    else
    {
        transformedStartingCoordinate = modelViewProjMatrix * (position - direction);
        transformedEndingCoordinate = modelViewProjMatrix * position;
    }

    transformedStartingCoordinate *= orthographicMatrix;
    transformedEndingCoordinate *= orthographicMatrix;

    adjustmentForOrthographicProjection = (vec3(0.5, 0.5, 0.5) * orthographicMatrix).xyz;

//    normalizedStartingCoordinate = (transformedStartingCoordinate.xyz + 1.0) * adjustmentForOrthographicProjection;
//    normalizedEndingCoordinate = (transformedEndingCoordinate.xyz + 1.0) * adjustmentForOrthographicProjection;

    normalizedStartingCoordinate = (transformedStartingCoordinate / 2.0) + 0.5;

    normalizedEndingCoordinate = (transformedEndingCoordinate / 2.0) + 0.5;

    impostorSpaceCoordinate = inputImpostorSpaceCoordinate.xy;
    
    halfCylinderRadius = cylinderRadius;
    
    gl_Position = vec4(ambientOcclusionTextureOffset * 2.0 - vec2(1.0) + (ambientOcclusionTexturePatchWidth * impostorSpaceCoordinate), 0.0, 1.0);
}
