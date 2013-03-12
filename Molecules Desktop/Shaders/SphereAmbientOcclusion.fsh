precision mediump float;

uniform sampler2D depthTexture;
uniform highp mat3 modelViewProjMatrix;
uniform mediump mat3 inverseModelViewProjMatrix;
uniform mediump float intensityFactor;

varying highp vec2 impostorSpaceCoordinate;
varying mediump vec3 normalizedViewCoordinate;
varying mediump float adjustedSphereRadius;
varying mediump vec3 adjustmentForOrthographicProjection;

const mediump float oneThird = 1.0 / 3.0;

mediump float depthFromEncodedColor(mediump vec4 encodedColor)
{
    return oneThird * (encodedColor.r + encodedColor.g + encodedColor.b);
    //    return encodedColor.r;
}

highp vec3 coordinateFromTexturePosition(highp vec2 texturePosition)
{
    highp vec2 absoluteTexturePosition = abs(texturePosition);
    highp float h = 1.0 - absoluteTexturePosition.s - absoluteTexturePosition.t;
    
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
    highp vec3 currentSphereSurfaceCoordinate = coordinateFromTexturePosition(clamp(impostorSpaceCoordinate, -1.0, 1.0));

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