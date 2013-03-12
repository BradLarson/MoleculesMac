varying vec2 impostorSpaceCoordinate;
varying float normalizedDepth;
varying float adjustedSphereRadius;
varying vec2 depthLookupCoordinate;

uniform sampler2D sphereDepthMap;

const vec3 stepValues = vec3(2.0, 1.0, 0.0);

void main()
{
    vec2 precalculatedDepthAndAlpha = texture2D(sphereDepthMap, depthLookupCoordinate).ra;
    
    float outOfCircleMultiplier = step(precalculatedDepthAndAlpha.g, 0.5);
    
    float currentDepthValue = normalizedDepth - adjustedSphereRadius * precalculatedDepthAndAlpha.r;
    
    // Inlined color encoding for the depth values
    currentDepthValue = currentDepthValue * 3.0;
    
    vec3 intDepthValue = vec3(currentDepthValue) - stepValues;
    
    vec3 temporaryColor = vec3(outOfCircleMultiplier) + vec3(1.0 - outOfCircleMultiplier) * intDepthValue;
    gl_FragColor = vec4(temporaryColor, 1.0);
}
