varying vec2 impostorSpaceCoordinate;
varying float depthOffsetAlongCenterAxis;
varying float normalizedDisplacementAtEndCaps;
varying float normalizedDepth;
varying float depthAdjustmentForOrthographicProjection;

const vec3 stepValues = vec3(2.0, 1.0, 0.0);
const float scaleDownFactor = 1.0 / 255.0;

void main()
{
    float adjustmentFromCenterAxis = sqrt(1.0 - impostorSpaceCoordinate.s * impostorSpaceCoordinate.s);
    float displacementFromCurvature = normalizedDisplacementAtEndCaps * adjustmentFromCenterAxis;
    float depthOffset = depthOffsetAlongCenterAxis * adjustmentFromCenterAxis * depthAdjustmentForOrthographicProjection;

    if ( (impostorSpaceCoordinate.t <= (-1.0 + displacementFromCurvature)) || (impostorSpaceCoordinate.t >= (1.0 + displacementFromCurvature)))
    {
        gl_FragColor = vec4(1.0);
        gl_FragDepth = 1.0;
    }

//    if ( impostorSpaceCoordinate.t <= (-1.0 + displacementFromCurvature))
 //   {
  //      discard;
  //  }

    // Use a little fudge factor to account for rounding errors when zoomed out on the ball and stick mode
    float calculatedDepth = normalizedDepth - depthOffset + 0.0025;
    gl_FragDepth = calculatedDepth;

    calculatedDepth = calculatedDepth * 3.0;

    vec3 intDepthValue = vec3(calculatedDepth) - stepValues;
    vec4 outputColor = vec4(intDepthValue, 1.0);
    
    gl_FragColor = outputColor;
}
