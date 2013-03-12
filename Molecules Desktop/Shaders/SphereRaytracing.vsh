//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

attribute vec3 position;
attribute vec2 inputImpostorSpaceCoordinate;
attribute vec2 ambientOcclusionTextureOffset;

varying vec2 impostorSpaceCoordinate;
varying vec3 normalizedViewCoordinate;
varying vec2 depthLookupCoordinate;
varying vec2 ambientOcclusionTextureBase;
varying float adjustedSphereRadius;

uniform mat3 modelViewProjMatrix;
uniform mat3 orthographicMatrix;
uniform float sphereRadius;
uniform vec3 translation;

void main()
{
    ambientOcclusionTextureBase = ambientOcclusionTextureOffset;
    
	vec3 transformedPosition = modelViewProjMatrix * (position + translation);
    impostorSpaceCoordinate = inputImpostorSpaceCoordinate;
    depthLookupCoordinate = (inputImpostorSpaceCoordinate / 2.0) + 0.5;

    transformedPosition.xy = transformedPosition.xy + inputImpostorSpaceCoordinate.xy * vec2(sphereRadius);
    transformedPosition = transformedPosition * orthographicMatrix;
    
    float depthAdjustmentForOrthographicProjection = (vec3(0.0, 0.0, 0.5) * orthographicMatrix).z;
//    adjustedSphereRadius = sphereRadius * 0.5 * depthAdjustmentForOrthographicProjection;
    adjustedSphereRadius = sphereRadius * depthAdjustmentForOrthographicProjection;

    normalizedViewCoordinate = (transformedPosition / 2.0) + 0.5;
    gl_Position = vec4(transformedPosition, 1.0);
}
