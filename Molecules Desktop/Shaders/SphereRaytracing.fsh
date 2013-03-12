precision mediump float;

uniform lowp vec3 sphereColor;
uniform lowp sampler2D depthTexture;
uniform lowp sampler2D ambientOcclusionTexture;
uniform lowp sampler2D precalculatedAOLookupTexture;
uniform mediump mat3 inverseModelViewProjMatrix;
uniform mediump float ambientOcclusionTexturePatchWidth;
uniform lowp sampler2D sphereDepthMap;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump vec2 depthLookupCoordinate;
varying mediump vec3 normalizedViewCoordinate;
varying mediump vec2 ambientOcclusionTextureBase;
varying mediump float adjustedSphereRadius;

const mediump float oneThird = 1.0 / 3.0;
const vec3 lightPosition = vec3(0.312757, 0.248372, 0.916785);

mediump float depthFromEncodedColor(mediump vec3 encodedColor)
{
    return (encodedColor.r + encodedColor.g + encodedColor.b) * oneThird;
}

void main()
{
    lowp vec4 precalculatedDepthAndLighting = texture2D(sphereDepthMap, depthLookupCoordinate);
    lowp float alphaComponent = 1.0;
  
//    gl_FragColor = vec4(1.0);
    
    alphaComponent = step(0.5, precalculatedDepthAndLighting.a);

    float currentDepthValue = normalizedViewCoordinate.z - adjustedSphereRadius * precalculatedDepthAndLighting.r;        
    vec3 encodedColor = texture2D(depthTexture, normalizedViewCoordinate.xy).rgb;
    float previousDepthValue = depthFromEncodedColor(encodedColor);
      
        // Check to see that this fragment is the frontmost one for this area
    alphaComponent = alphaComponent * step((currentDepthValue - 0.004), previousDepthValue);
//    alphaComponent = alphaComponent * smoothstep((currentDepthValue - 0.024), (currentDepthValue - 0.006), previousDepthValue);
//    alphaComponent = alphaComponent * smoothstep((currentDepthValue - 0.006), (currentDepthValue - 0.024), previousDepthValue);
    
    lowp vec2 lookupTextureCoordinate = texture2D(precalculatedAOLookupTexture, depthLookupCoordinate).st;
    lookupTextureCoordinate = (lookupTextureCoordinate * 2.0) - 1.0;
    
    vec2 textureCoordinateForAOLookup = ambientOcclusionTextureBase + ambientOcclusionTexturePatchWidth * lookupTextureCoordinate;
    lowp float ambientOcclusionIntensity = texture2D(ambientOcclusionTexture, textureCoordinateForAOLookup).r;
    
    // Ambient lighting            
//    lowp float lightingIntensity = 0.2 + 1.7 * precalculatedDepthAndLighting.g * ambientOcclusionIntensity;
    lowp float lightingIntensity = 0.1 + precalculatedDepthAndLighting.g * ambientOcclusionIntensity;
//    lowp float lightingIntensity = precalculatedDepthAndLighting.g;
    lowp vec3 finalSphereColor = sphereColor * lightingIntensity;
    
    // Specular lighting    
    finalSphereColor = finalSphereColor + ( (precalculatedDepthAndLighting.b * ambientOcclusionIntensity) * (vec3(1.0) - finalSphereColor));
    
    gl_FragColor = vec4(finalSphereColor * alphaComponent, alphaComponent); // Black background
//    gl_FragColor = vec4(finalSphereColor * alphaComponent + (1.0 - 1.0 * alphaComponent), alphaComponent); // White background
//            gl_FragColor = vec4(texture2D(ambientOcclusionTexture, textureCoordinateForAOLookup).rgb * alphaComponent + (1.0 - 1.0 * alphaComponent), alphaComponent);
//            gl_FragColor = vec4(textureCoordinateForAOLookup * alphaComponent, 0.0, alphaComponent);
            //    gl_FragColor = vec4(normalizedViewCoordinate, 1.0);
            //    gl_FragColor = vec4(precalculatedDepthAndLighting, 1.0);
}