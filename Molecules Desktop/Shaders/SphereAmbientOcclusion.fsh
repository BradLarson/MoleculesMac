uniform sampler2D depthTexture;
uniform mat3 modelViewProjMatrix;
uniform mat3 inverseModelViewProjMatrix;
uniform float intensityFactor;

varying vec2 impostorSpaceCoordinate;
varying vec3 normalizedViewCoordinate;
varying float adjustedSphereRadius;
varying vec3 adjustmentForOrthographicProjection;

const float oneThird = 1.0 / 3.0;

float depthFromEncodedColor(vec4 encodedColor)
{
    return oneThird * (encodedColor.r + encodedColor.g + encodedColor.b);
    //    return encodedColor.r;
}

vec3 coordinateFromTexturePosition(vec2 texturePosition)
{
    vec2 absoluteTexturePosition = abs(texturePosition);
    float h = 1.0 - absoluteTexturePosition.s - absoluteTexturePosition.t;
    
    if (h >= 0.0)
    {
        return vec3(texturePosition.s, texturePosition.t, h);
    }
    else
    {
        return vec3(sign(texturePosition.s) * (1.0 - absoluteTexturePosition.t), sign(texturePosition.t) * (1.0 - absoluteTexturePosition.s), h);
    }
}

void main()
{
    vec3 currentSphereSurfaceCoordinate = coordinateFromTexturePosition(clamp(impostorSpaceCoordinate, -1.0, 1.0));

    currentSphereSurfaceCoordinate = normalize(modelViewProjMatrix * currentSphereSurfaceCoordinate);
     
    vec3 currentPositionCoordinate = normalizedViewCoordinate + adjustedSphereRadius * currentSphereSurfaceCoordinate * adjustmentForOrthographicProjection;
    
                                                                 
    float previousDepthValue = depthFromEncodedColor(texture2D(depthTexture, currentPositionCoordinate.xy));

    if ( (floor(currentPositionCoordinate.z * 765.0 - 5.0)) <= (ceil(previousDepthValue * 765.0)) )
    {
//        gl_FragColor = vec4(texture2D(depthTexture, currentPositionCoordinate.xy).rgb, 1.0);
        gl_FragColor = vec4(vec3(intensityFactor), 1.0);
//        gl_FragColor = vec4(currentPositionCoordinate, 1.0);
    }
    else
    {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    
//    gl_FragColor = vec4(currentPositionCoordinate, 1.0);
//    gl_FragColor = vec4(currentSphereSurfaceCoordinate, 1.0);
//    gl_FragColor = vec4(textureOffset, 0.0 , 1.0);
        
}