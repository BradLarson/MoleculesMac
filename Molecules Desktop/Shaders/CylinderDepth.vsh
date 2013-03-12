attribute vec3 position;
attribute vec3 direction;
attribute vec3 inputImpostorSpaceCoordinate;

uniform mat3 modelViewProjMatrix;
uniform float cylinderRadius;
uniform mat3 orthographicMatrix;
uniform vec3 translation;

varying vec2 impostorSpaceCoordinate;
varying float depthOffsetAlongCenterAxis;
varying float normalizedDisplacementAtEndCaps;
varying float normalizedDepth;
varying float depthAdjustmentForOrthographicProjection;

void main()
{
    vec2 rotationFactor;
    vec3 transformedDirection, transformedPosition, transformedOtherPosition;
    vec3 viewDisplacementForVertex, displacementDirectionAtEndCap;
    float displacementAtEndCaps, lengthOfCylinder, lengthOfCylinderInView;
    
    depthAdjustmentForOrthographicProjection = (vec3(0.0, 0.0, 0.5) * orthographicMatrix).z;

	transformedPosition = modelViewProjMatrix * (position + translation);
    transformedOtherPosition = modelViewProjMatrix * (position + direction + translation);
    transformedDirection = transformedOtherPosition - transformedPosition;

    lengthOfCylinder = length(transformedDirection.xyz);
    lengthOfCylinderInView = length(transformedDirection.xy);
    rotationFactor = transformedDirection.xy / lengthOfCylinderInView;

    displacementAtEndCaps = cylinderRadius * (transformedOtherPosition.z - transformedPosition.z) / lengthOfCylinder;
    
    normalizedDisplacementAtEndCaps = displacementAtEndCaps / lengthOfCylinderInView;
    
    depthOffsetAlongCenterAxis = cylinderRadius * lengthOfCylinder * inversesqrt(lengthOfCylinder * lengthOfCylinder - (transformedOtherPosition.z - transformedPosition.z) * (transformedOtherPosition.z - transformedPosition.z));
    depthOffsetAlongCenterAxis = clamp(depthOffsetAlongCenterAxis, 0.0, cylinderRadius * 2.0);

    displacementDirectionAtEndCap.xy = displacementAtEndCaps * rotationFactor;
    displacementDirectionAtEndCap.z = transformedDirection.z * displacementAtEndCaps / lengthOfCylinder;
    
    transformedDirection.xy = normalize(transformedDirection.xy);
    
    if ((displacementAtEndCaps * inputImpostorSpaceCoordinate.t) > 0.0)
    {
        viewDisplacementForVertex.x = inputImpostorSpaceCoordinate.x * transformedDirection.y * cylinderRadius + displacementDirectionAtEndCap.x;
        viewDisplacementForVertex.y = -inputImpostorSpaceCoordinate.x * transformedDirection.x * cylinderRadius + displacementDirectionAtEndCap.y;
        viewDisplacementForVertex.z = displacementDirectionAtEndCap.z;
        impostorSpaceCoordinate = vec2(inputImpostorSpaceCoordinate.s, inputImpostorSpaceCoordinate.t + 1.0 * normalizedDisplacementAtEndCaps);
    }
    else
    {
        viewDisplacementForVertex.x = inputImpostorSpaceCoordinate.x * transformedDirection.y * cylinderRadius;
        viewDisplacementForVertex.y = -inputImpostorSpaceCoordinate.x * transformedDirection.x * cylinderRadius;    
        viewDisplacementForVertex.z = 0.0;
        impostorSpaceCoordinate = vec2(inputImpostorSpaceCoordinate.s, inputImpostorSpaceCoordinate.t);
    }
        
    transformedPosition.xyz = (transformedPosition.xyz + viewDisplacementForVertex);
    transformedPosition *= orthographicMatrix;
    normalizedDepth = transformedPosition.z / 2.0 + 0.5;

    gl_Position = vec4(transformedPosition, 1.0);
}
