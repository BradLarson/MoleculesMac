#import <Cocoa/Cocoa.h>
#import "SLSMolecule.h"
#import "SLSOpenGLRenderer.h"
#import "SLSMoleculeGLView.h"

@interface SLSMoleculeDocument : NSDocument<SLSGLViewDelegate>
{
    SLSMolecule *molecule;
    SLSOpenGLRenderer *openGLRenderer;
    
    BOOL isAutorotating;
}

@property(readwrite, assign) IBOutlet SLSMoleculeGLView *glView;

@end
