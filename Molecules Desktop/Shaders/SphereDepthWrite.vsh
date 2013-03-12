attribute vec3 position;
attribute vec2 inputImpostorSpaceCoordinate;

uniform mat3 modelViewProjMatrix;
uniform float sphereRadius;
uniform mat3 orthographicMatrix;
uniform vec3 translation;

void main()
{
    vec3 transformedPosition = modelViewProjMatrix * (position + translation);
//    vec2 insetCoordinate = inputImpostorSpaceCoordinate * 0.707107; // Square
    vec2 insetCoordinate = inputImpostorSpaceCoordinate * 0.91017; // Octagon
        
    transformedPosition.xy = transformedPosition.xy + insetCoordinate * vec2(sphereRadius);
    transformedPosition.z = transformedPosition.z + sphereRadius + 0.006;
    transformedPosition = transformedPosition * orthographicMatrix;
    
    gl_Position = vec4(transformedPosition, 1.0);
}
