varying vec2 impostorSpaceCoordinate;
varying float normalizedDepth;
varying float adjustedSphereRadius;
varying vec2 depthLookupCoordinate;

const vec3 stepValues = vec3(2.0, 1.0, 0.0);

void main()
{
    float distanceFromCenter = length(impostorSpaceCoordinate);
    distanceFromCenter = min(distanceFromCenter, 1.0);
    float normalizedSphereDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
    float alphaComponent = step(distanceFromCenter, 0.99);

    float currentDepthValue = normalizedDepth - adjustedSphereRadius * normalizedSphereDepth;
    gl_FragDepth = currentDepthValue + (1.0 - alphaComponent);
    
    // Inlined color encoding for the depth values
    currentDepthValue = currentDepthValue * 3.0;
    
    vec3 intDepthValue = vec3(currentDepthValue) - stepValues;
    
    vec3 temporaryColor = vec3(1.0 - alphaComponent) + vec3(alphaComponent) * intDepthValue;
    gl_FragColor = vec4(temporaryColor, 1.0);
}
