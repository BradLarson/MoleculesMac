//
//  Shader.vsh
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

attribute mediump vec2 inputImpostorSpaceCoordinate;

varying mediump vec2 impostorSpaceCoordinate;
varying mediump vec2 depthLookupCoordinate;

void main()
{
    impostorSpaceCoordinate = inputImpostorSpaceCoordinate;
    depthLookupCoordinate = (inputImpostorSpaceCoordinate / 2.0) + 0.5;

    gl_Position = vec4(impostorSpaceCoordinate, 0.0, 1.0);
}
