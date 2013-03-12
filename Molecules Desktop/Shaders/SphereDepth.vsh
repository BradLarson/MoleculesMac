//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

attribute vec3 position;
attribute vec2 inputImpostorSpaceCoordinate;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump float normalizedDepth;
varying mediump float adjustedSphereRadius;
varying mediump vec2 depthLookupCoordinate;

uniform mediump mat3 modelViewProjMatrix;
uniform mediump float sphereRadius;
uniform mediump mat3 orthographicMatrix;
uniform mediump vec3 translation;

void main()
{
    vec3 transformedPosition;
	transformedPosition = modelViewProjMatrix * (position + translation);
    impostorSpaceCoordinate = inputImpostorSpaceCoordinate.xy;
    
    depthLookupCoordinate = (impostorSpaceCoordinate / 2.0) + 0.5;
    
    transformedPosition.xy = transformedPosition.xy + inputImpostorSpaceCoordinate.xy * vec2(sphereRadius);
    transformedPosition = transformedPosition * orthographicMatrix;

    float depthAdjustmentForOrthographicProjection = (vec3(0.0, 0.0, 0.5) * orthographicMatrix).z;
    adjustedSphereRadius = sphereRadius * depthAdjustmentForOrthographicProjection;
    
    normalizedDepth = transformedPosition.z / 2.0 + 0.5;
    gl_Position = vec4(transformedPosition, 1.0);
}
