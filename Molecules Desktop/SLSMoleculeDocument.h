#import <Cocoa/Cocoa.h>
#import "SLSMolecule.h"
#import "SLSOpenGLRenderer.h"
#import "SLSMoleculeGLView.h"
#import "LeapObjectiveC.h"

@interface SLSMoleculeDocument : NSDocument<SLSGLViewDelegate, LeapListener>
{
    SLSMolecule *molecule;
    SLSOpenGLRenderer *openGLRenderer;
    LeapController *controller;
    LeapFrame *previousLeapFrame;

    BOOL isAutorotating;
    
    NSPoint lastFingerPoint;
    CGFloat startingZoomDistance, previousScale;
    BOOL isRotating;
    BOOL isZooming;
}

@property(readwrite, weak) IBOutlet SLSMoleculeGLView *glView;

- (void)useFingersToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
- (void)useHandsToRotateLikeOniOS:(LeapFrame *)currentLeapFrame;
- (void)useGraspingMotionToScaleAndRotate:(LeapFrame *)currentLeapFrame;

@end
