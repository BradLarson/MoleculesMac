//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

attribute mediump vec3 position;
attribute mediump vec2 inputImpostorSpaceCoordinate;
attribute mediump vec2 ambientOcclusionTextureOffset;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump vec3 normalizedViewCoordinate;
varying mediump vec2 depthLookupCoordinate;
varying mediump vec2 ambientOcclusionTextureBase;
varying mediump float adjustedSphereRadius;

uniform mediump mat3 modelViewProjMatrix;
uniform mediump mat3 orthographicMatrix;
uniform mediump float sphereRadius;
uniform mediump vec3 translation;

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
