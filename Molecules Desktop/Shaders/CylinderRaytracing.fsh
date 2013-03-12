precision mediump float;

uniform vec3 cylinderColor;
uniform sampler2D depthTexture;
uniform sampler2D ambientOcclusionTexture;
uniform mat3 inverseModelViewProjMatrix;
uniform mediump float ambientOcclusionTexturePatchWidth;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump vec3 normalAlongCenterAxis;
varying mediump float depthOffsetAlongCenterAxis;
varying mediump float normalizedDepthOffsetAlongCenterAxis;
varying mediump float normalizedDisplacementAtEndCaps;
varying mediump float normalizedRadialDisplacementAtEndCaps;
varying mediump vec2 rotationFactor;
varying mediump vec3 normalizedViewCoordinate;
varying mediump vec2 ambientOcclusionTextureBase;
varying mediump float depthAdjustmentForOrthographicProjection;
varying mediump float normalizedDistanceAlongZAxis;

const mediump float oneThird = 1.0 / 3.0;
const vec3 lightPosition = vec3(0.312757, 0.248372, 0.916785);


mediump float depthFromEncodedColor(mediump vec4 encodedColor)
{
    return oneThird * (encodedColor.r + encodedColor.g + encodedColor.b);
    //    return encodedColor.r;
}

mediump vec2 textureCoordinateForCylinderSurfacePosition(mediump vec3 cylinderSurfacePosition)
{
    vec2 halfAbsoluteXY = abs(cylinderSurfacePosition.xy / 2.0);
    
    if (cylinderSurfacePosition.x >= 0.0)
    {
        return vec2(cylinderSurfacePosition.y / (4.0 * (halfAbsoluteXY.x + halfAbsoluteXY.y)) - 0.5, cylinderSurfacePosition.z);
    }
    else
    {
        return vec2(-cylinderSurfacePosition.y / (4.0 * (halfAbsoluteXY.x + halfAbsoluteXY.y)) + 0.5, cylinderSurfacePosition.z);
    }
}

void main()
{
    float adjustmentFromCenterAxis = sqrt(1.0 - impostorSpaceCoordinate.s * impostorSpaceCoordinate.s);
    float displacementFromCurvature = normalizedDisplacementAtEndCaps * adjustmentFromCenterAxis;
    float depthOffset = depthOffsetAlongCenterAxis * adjustmentFromCenterAxis * depthAdjustmentForOrthographicProjection;

    vec3 normal = vec3(normalizedRadialDisplacementAtEndCaps * rotationFactor.x * adjustmentFromCenterAxis + impostorSpaceCoordinate.s * rotationFactor.y,
                       -(normalizedRadialDisplacementAtEndCaps * rotationFactor.y * adjustmentFromCenterAxis + impostorSpaceCoordinate.s * rotationFactor.x),
                       normalizedDepthOffsetAlongCenterAxis * adjustmentFromCenterAxis);
    
    normal = normalize(normal);
    
    if ( (impostorSpaceCoordinate.t <= (-1.0 + displacementFromCurvature)) || (impostorSpaceCoordinate.t >= (1.0 + displacementFromCurvature)))
    {
        gl_FragColor = vec4(0.0); // Black background
//        gl_FragColor = vec4(1.0); // White background
    }
    else
    {
        float currentDepthValue = normalizedViewCoordinate.z - depthOffset + 0.0025;
        float previousDepthValue = depthFromEncodedColor(texture2D(depthTexture, normalizedViewCoordinate.xy));
        
        //if ( (floor(currentDepthValue * 765.0)) > (ceil(previousDepthValue * 765.0)) )
        if ( (currentDepthValue - 0.006) > (previousDepthValue) )
        {
            gl_FragColor = vec4(0.0); // Black background
//            gl_FragColor = vec4(1.0); // White background
        }
        else
        {
            vec3 finalCylinderColor = cylinderColor;
            
            // ambient
            vec3 aoNormal = vec3(0.5, 0.5, normalizedDistanceAlongZAxis);
            //    vec3 aoNormal = normal;
            //    aoNormal.z = -aoNormal.z;
            //    aoNormal = (inverseModelViewProjMatrix * vec4(aoNormal, 0.0)).xyz;
            //    aoNormal.z = -aoNormal.z;
            vec2 textureCoordinateForAOLookup = ambientOcclusionTextureBase + ambientOcclusionTexturePatchWidth * 0.5 * textureCoordinateForCylinderSurfacePosition(aoNormal);
            vec3 ambientOcclusionIntensity = texture2D(ambientOcclusionTexture, textureCoordinateForAOLookup).rgb;
            
            float lightingIntensity = 0.1 + clamp(dot(lightPosition, normal), 0.0, 1.0) * ambientOcclusionIntensity.r;
            finalCylinderColor *= lightingIntensity;
            
            // Per fragment specular lighting
            lightingIntensity  = clamp(dot(lightPosition, normal), 0.0, 1.0);
            lightingIntensity  = pow(lightingIntensity, 60.0) * ambientOcclusionIntensity.r * 1.2;
            finalCylinderColor += 0.4 * lightingIntensity;
            
            //    gl_FragColor = texture2D(depthTexture, normalizedViewCoordinate.xy);
            
            //    normal.z = -normal.z;
            //    normal = (inverseModelViewProjMatrix * vec4(normal, 0.0)).xyz;
            //    normal.z = -normal.z;
            //    
            //    gl_FragColor = vec4(normal, 1.0);
            
            //    gl_FragColor = vec4(textureCoordinateForCylinderSurfacePosition(aoNormal), 0.0, 1.0);
            //    gl_FragColor = vec4(ambientOcclusionTextureBase, 0.0, 1.0);
            
//                gl_FragColor = vec4(ambientOcclusionIntensity, 1.0);
            
            //    gl_FragColor = vec4(vec3((1.0 + normalizedDistanceAlongZAxis) / 2.0), 1.0);
            gl_FragColor = vec4(finalCylinderColor, 1.0);
        }            
   }        
}
