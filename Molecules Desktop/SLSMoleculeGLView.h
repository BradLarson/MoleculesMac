#import <Cocoa/Cocoa.h>

@protocol SLSGLViewDelegate <NSObject>

- (void)resizeView;
- (void)rotateModelFromScreenDisplacementInX:(float)xRotation inY:(float)yRotation;
- (void)scaleModelByFactor:(float)scaleFactor;
- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;

@end

@interface SLSMoleculeGLView : NSOpenGLView
{
    NSPoint lastMovementPosition;
}
@property(readwrite, weak) id<SLSGLViewDelegate>renderingDelegate;

@end
