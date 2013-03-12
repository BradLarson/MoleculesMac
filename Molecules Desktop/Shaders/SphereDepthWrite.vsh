attribute mediump vec3 position;
attribute mediump vec2 inputImpostorSpaceCoordinate;

uniform mediump mat3 modelViewProjMatrix;
uniform mediump float sphereRadius;
uniform mediump mat3 orthographicMatrix;
uniform mediump vec3 translation;

void main()
{
    mediump vec3 transformedPosition = modelViewProjMatrix * (position + translation);
//    mediump vec2 insetCoordinate = inputImpostorSpaceCoordinate * 0.707107; // Square
    mediump vec2 insetCoordinate = inputImpostorSpaceCoordinate * 0.91017; // Octagon
        
    transformedPosition.xy = transformedPosition.xy + insetCoordinate * vec2(sphereRadius);
    transformedPosition.z = transformedPosition.z + sphereRadius + 0.006;
    transformedPosition = transformedPosition * orthographicMatrix;
    
    gl_Position = vec4(transformedPosition, 1.0);
}
