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

vec2 ambientOcclusionLookupCoordinate(float distanceFromCenter)
{
    vec3 aoNormal;
    
    if (distanceFromCenter > 1.0)
    {
        distanceFromCenter = 1.0;
        aoNormal = vec3(normalize(impostorSpaceCoordinate), 0.0);
    }
    else
    {
        float precalculatedDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
        aoNormal = vec3(impostorSpaceCoordinate, -precalculatedDepth);
    }
    
    // Ambient occlusion factor
    aoNormal = inverseModelViewProjMatrix * aoNormal;
    aoNormal.z = -aoNormal.z;
    
    vec3 absoluteSphereSurfacePosition = abs(aoNormal);
    float d = absoluteSphereSurfacePosition.x + absoluteSphereSurfacePosition.y + absoluteSphereSurfacePosition.z;
    
    vec2 lookupTextureCoordinate;
    if (aoNormal.z <= 0.0)
    {
        lookupTextureCoordinate = aoNormal.xy / d;
    }
    else
    {
        vec2 theSign = aoNormal.xy / absoluteSphereSurfacePosition.xy;
        //vec2 aSign = sign(aoNormal.xy);
        lookupTextureCoordinate =  theSign  - absoluteSphereSurfacePosition.yx * (theSign / d);
    }
    
    return (lookupTextureCoordinate / 2.0) + 0.5;
}

void main()
{
    float distanceFromCenter = length(impostorSpaceCoordinate);
    distanceFromCenter = min(distanceFromCenter, 1.0);
    float normalizedDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
    float alphaComponent = step(distanceFromCenter, 0.99);
    
    float currentDepthValue = normalizedViewCoordinate.z - adjustedSphereRadius * normalizedDepth;
    gl_FragDepth = currentDepthValue + (1.0 - alphaComponent);

    vec2 lookupTextureCoordinate = ambientOcclusionLookupCoordinate(distanceFromCenter);

//    vec2 lookupTextureCoordinate = texture2D(precalculatedAOLookupTexture, depthLookupCoordinate).st;
    lookupTextureCoordinate = (lookupTextureCoordinate * 2.0) - 1.0;
    
    vec2 textureCoordinateForAOLookup = ambientOcclusionTextureBase + ambientOcclusionTexturePatchWidth * lookupTextureCoordinate;
    float ambientOcclusionIntensity = texture2D(ambientOcclusionTexture, textureCoordinateForAOLookup).r;
    
    // Ambient lighting            
//    float lightingIntensity = 0.1 + precalculatedDepthAndLighting.g * ambientOcclusionIntensity;
    
    // Specular lighting
//    finalSphereColor = finalSphereColor + ( (precalculatedDepthAndLighting.b * ambientOcclusionIntensity) * (vec3(1.0) - finalSphereColor));
        
    // Ambient lighting
    vec3 normal = vec3(impostorSpaceCoordinate, normalizedDepth);
    float ambientLightingIntensityFactor = clamp(dot(lightPosition, normal), 0.0, 1.0);
    
    float lightingIntensity = 0.1 + ambientLightingIntensityFactor * ambientOcclusionIntensity;
    vec3 finalSphereColor = sphereColor * lightingIntensity;
    
    // Specular lighting
    float specularLightingIntensityFactor = pow(ambientLightingIntensityFactor, 60.0) * 0.6;
    finalSphereColor = finalSphereColor + ((specularLightingIntensityFactor * ambientOcclusionIntensity)  * (vec3(1.0) - finalSphereColor));

    gl_FragColor = vec4(finalSphereColor * alphaComponent, 1.0); // Black background
}