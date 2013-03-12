uniform mat3 inverseModelViewProjMatrix;

varying vec2 impostorSpaceCoordinate;
varying vec2 depthLookupCoordinate;

void main()
{
    float distanceFromCenter = length(impostorSpaceCoordinate);

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

    gl_FragColor = vec4((lookupTextureCoordinate / 2.0) + 0.5, 0.0, 1.0);
}