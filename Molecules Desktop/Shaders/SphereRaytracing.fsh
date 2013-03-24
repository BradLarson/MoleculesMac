uniform vec3 sphereColor;
uniform sampler2D depthTexture;
uniform sampler2D ambientOcclusionTexture;
uniform sampler2D precalculatedAOLookupTexture;
uniform mat3 inverseModelViewProjMatrix;
uniform float ambientOcclusionTexturePatchWidth;
uniform sampler2D sphereDepthMap;

varying vec2 impostorSpaceCoordinate;
varying vec2 depthLookupCoordinate;
varying vec3 normalizedViewCoordinate;
varying vec2 ambientOcclusionTextureBase;
varying float adjustedSphereRadius;

const float oneThird = 1.0 / 3.0;
const vec3 lightPosition = vec3(0.312757, 0.248372, 0.916785);

float depthFromEncodedColor(vec3 encodedColor)
{
    return (encodedColor.r + encodedColor.g + encodedColor.b) * oneThird;
}

void main()
{
    vec4 precalculatedDepthAndLighting = texture2D(sphereDepthMap, depthLookupCoordinate);
    float alphaComponent = 1.0;
  
    alphaComponent = step(0.5, precalculatedDepthAndLighting.a);

    float currentDepthValue = normalizedViewCoordinate.z - adjustedSphereRadius * precalculatedDepthAndLighting.r;
    gl_FragDepth = currentDepthValue + (1.0 - alphaComponent);
    
    vec2 lookupTextureCoordinate = texture2D(precalculatedAOLookupTexture, depthLookupCoordinate).st;
    lookupTextureCoordinate = (lookupTextureCoordinate * 2.0) - 1.0;
    
    vec2 textureCoordinateForAOLookup = ambientOcclusionTextureBase + ambientOcclusionTexturePatchWidth * lookupTextureCoordinate;
    float ambientOcclusionIntensity = texture2D(ambientOcclusionTexture, textureCoordinateForAOLookup).r;
    
    // Ambient lighting            
//   float lightingIntensity = 0.2 + 1.7 * precalculatedDepthAndLighting.g * ambientOcclusionIntensity;
    float lightingIntensity = 0.1 + precalculatedDepthAndLighting.g * ambientOcclusionIntensity;
//   float lightingIntensity = precalculatedDepthAndLighting.g;
    vec3 finalSphereColor = sphereColor * lightingIntensity;
    
    // Specular lighting    
    finalSphereColor = finalSphereColor + ( (precalculatedDepthAndLighting.b * ambientOcclusionIntensity) * (vec3(1.0) - finalSphereColor));
    
    gl_FragColor = vec4(finalSphereColor * alphaComponent, 1.0); // Black background
}