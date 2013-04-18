#import "SLSMoleculeGLView.h"

@implementation SLSMoleculeGLView

@synthesize renderingDelegate = _renderingDelegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    
    return self;
}

-(void)awakeFromNib
{
	NSOpenGLPixelFormatAttribute requestedAttrib[5];
	requestedAttrib[0]=NSOpenGLPFADoubleBuffer;
	requestedAttrib[1]=NSOpenGLPFADepthSize;
	requestedAttrib[2]=24;
	requestedAttrib[3]=NSOpenGLPFAAccelerated;
	requestedAttrib[4]=0;
	NSOpenGLPixelFormat *pixelFormat=[[NSOpenGLPixelFormat alloc] initWithAttributes:requestedAttrib];
	if(pixelFormat!=nil)
	{
		self.pixelFormat = pixelFormat;
	}
	else
	{
		NSLog(@"Error: No appropriate pixel format found");
	}    
}

- (void)drawRect:(NSRect)dirtyRect;
{
    [self.renderingDelegate translateModelByScreenDisplacementInX:0.0 inY:0.0];
}

- (void)reshape;
{
//	[[self openGLContext] update];
    [self.renderingDelegate resizeView];
}

- (void)viewDidEndLiveResize;
{
    [self.renderingDelegate translateModelByScreenDisplacementInX:0.0 inY:0.0];
//    [self.renderingDelegate resizeView];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	// Move to new view area
	
    //	[delegate shouldMoveToNewLocationInMicronsForX:round(layoutCoordinateForLocationInView.x * 1000.0) forY:round(layoutCoordinateForLocationInView.y * 1000.0)];
	lastMovementPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
}

- (void)mouseDragged:(NSEvent *)theEvent;
{
    // Use shift for zooming, regular drag for rotation
	NSPoint currentMovementPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if ([theEvent modifierFlags] & NSShiftKeyMask)
    {
        [self.renderingDelegate scaleModelByFactor:(1.0 + 3.0 * (currentMovementPosition.y - lastMovementPosition.y) / self.frame.size.height)];
    }
    else if ([theEvent modifierFlags] & NSCommandKeyMask)
    {
        [self.renderingDelegate translateModelByScreenDisplacementInX:(currentMovementPosition.x - lastMovementPosition.x) inY:(currentMovementPosition.y - lastMovementPosition.y)];
    }
    else
    {
        [self.renderingDelegate rotateModelFromScreenDisplacementInX:(currentMovementPosition.x - lastMovementPosition.x) inY:(lastMovementPosition.y - currentMovementPosition.y)];
    }
    
    lastMovementPosition = currentMovementPosition;
}

- (void)mouseUp:(NSEvent *)theEvent;
{
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	// Show the zoom options in a menu here
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    [self.renderingDelegate scaleModelByFactor:(1.0 + [theEvent deltaY] / 40.0)];
}

@end
