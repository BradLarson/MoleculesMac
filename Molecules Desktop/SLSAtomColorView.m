#import "SLSAtomColorView.h"

void dataProviderReleaseCallback (void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation SLSAtomColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setAtomColorRed:(CGFloat)redComponent green:(CGFloat)greenComponent blue:(CGFloat)blueComponent;
{
    CGFloat lightDirection[3] = {0.312757, 0.248372, 0.916785};

    // 62 x 62 for view
    NSInteger pixelWidthOfImage = round(self.bounds.size.width);
    NSInteger pixelHeightOfImage = round(self.bounds.size.height);
    NSUInteger totalBytesForImage = pixelWidthOfImage * pixelHeightOfImage * 4;
    unsigned char *sphereImageBytes = (unsigned char *)malloc(totalBytesForImage);

    // Generate pixels for image
    
    for (unsigned int currentColumnInTexture = 0; currentColumnInTexture < pixelHeightOfImage; currentColumnInTexture++)
    {
        float normalizedYLocation = -1.0 + 2.0 * (float)(pixelHeightOfImage - currentColumnInTexture) / (float)pixelWidthOfImage;
        for (unsigned int currentRowInTexture = 0; currentRowInTexture < pixelWidthOfImage; currentRowInTexture++)
        {
            float normalizedXLocation = -1.0 + 2.0 * (float)currentRowInTexture / (float)pixelWidthOfImage;
            unsigned char alphaByte = 0;
            unsigned char finalSphereColor[3] = {0,0,0};
            
            float distanceFromCenter = sqrt(normalizedXLocation * normalizedXLocation + normalizedYLocation * normalizedYLocation);
            float currentSphereDepth = 0.0;
            float lightingNormalX = normalizedXLocation, lightingNormalY = normalizedYLocation;
            
            if (distanceFromCenter <= 1.0)
            {
                // First, calculate the depth of the sphere at this point
                currentSphereDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);
                
                alphaByte = 255;
            }
            else
            {
                float normalizationFactor = sqrt(normalizedXLocation * normalizedXLocation + normalizedYLocation * normalizedYLocation);
                lightingNormalX = lightingNormalX / normalizationFactor;
                lightingNormalY = lightingNormalY / normalizationFactor;
                alphaByte = 0;
            }
            
            // Then, do the ambient lighting factor
            float ambientLightingIntensityFactor = lightingNormalX * lightDirection[0] + lightingNormalY * lightDirection[1] + currentSphereDepth * lightDirection[2];
            if (ambientLightingIntensityFactor < 0.0)
            {
                ambientLightingIntensityFactor = 0.0;
            }
            else if (ambientLightingIntensityFactor > 1.0)
            {
                ambientLightingIntensityFactor = 1.0;
            }

//            float lightingIntensity = MIN(0.1 + ambientLightingIntensityFactor, 1.0);
            float lightingIntensity = ambientLightingIntensityFactor;
            
            finalSphereColor[0] = round(redComponent * lightingIntensity * 255.0);
            finalSphereColor[1] = round(greenComponent * lightingIntensity * 255.0);
            finalSphereColor[2] = round(blueComponent * lightingIntensity * 255.0);

            // Specular lighting
            float specularLightingIntensityFactor = pow(ambientLightingIntensityFactor, 60.0) * 0.6;
            finalSphereColor[0] = MIN((CGFloat)finalSphereColor[0] + (specularLightingIntensityFactor * (255.0 - (CGFloat)finalSphereColor[0])), 255);
            finalSphereColor[1] = MIN((CGFloat)finalSphereColor[1] + (specularLightingIntensityFactor * (255.0 - (CGFloat)finalSphereColor[1])), 255);
            finalSphereColor[2] = MIN((CGFloat)finalSphereColor[2] + (specularLightingIntensityFactor * (255.0 - (CGFloat)finalSphereColor[2])), 255);

            sphereImageBytes[currentColumnInTexture * pixelWidthOfImage * 4 + (currentRowInTexture * 4)] = finalSphereColor[0];
            sphereImageBytes[currentColumnInTexture * pixelWidthOfImage * 4 + (currentRowInTexture * 4) + 1] = finalSphereColor[1];
            sphereImageBytes[currentColumnInTexture * pixelWidthOfImage * 4 + (currentRowInTexture * 4) + 2] = finalSphereColor[2];
            sphereImageBytes[currentColumnInTexture * pixelWidthOfImage * 4 + (currentRowInTexture * 4) + 3] = alphaByte;
            /*
             float lightingIntensity = 0.2 + 1.3 * clamp(dot(lightPosition, normal), 0.0, 1.0) * ambientOcclusionIntensity.r;
             finalSphereColor *= lightingIntensity;
             
             // Per fragment specular lighting
             lightingIntensity  = clamp(dot(lightPosition, normal), 0.0, 1.0);
             lightingIntensity  = pow(lightingIntensity, 60.0) * ambientOcclusionIntensity.r * 1.2;
             finalSphereColor += vec3(0.4, 0.4, 0.4) * lightingIntensity + vec3(1.0, 1.0, 1.0) * 0.2 * ambientOcclusionIntensity.r;
             */
            
        }
    }

    // Create NSImage from this
    CGDataProviderRef dataProvider;
    dataProvider = CGDataProviderCreateWithData(NULL, sphereImageBytes, totalBytesForImage, dataProviderReleaseCallback);

    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate(pixelWidthOfImage, pixelHeightOfImage, 8, 32, 4 * pixelWidthOfImage, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);

// Capture image with current device orientation
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:cgImageFromBytes size:NSZeroSize];
    CGImageRelease(cgImageFromBytes);
    
    self.image = finalImage;
}

@end
