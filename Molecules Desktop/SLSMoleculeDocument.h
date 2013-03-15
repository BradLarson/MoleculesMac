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

    BOOL isAutorotating;
    
    NSPoint lastFingerPoint;
    CGFloat startingZoomDistance, previousScale;
    BOOL isRotating;
    BOOL isZooming;
}

@property(readwrite, assign) IBOutlet SLSMoleculeGLView *glView;

@end
