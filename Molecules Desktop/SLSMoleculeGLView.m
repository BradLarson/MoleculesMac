#import "SLSMoleculeGLView.h"

@implementation SLSMoleculeGLView

@synthesize renderingDelegate = _renderingDelegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(void)awakeFromNib
{
	
	NSOpenGLPixelFormatAttribute requestedAttrib[3];
	requestedAttrib[0]=NSOpenGLPFADoubleBuffer;
	requestedAttrib[1]=NSOpenGLPFAAccelerated;
	requestedAttrib[2]=0;
	NSOpenGLPixelFormat *pixelFormat=[[NSOpenGLPixelFormat alloc] initWithAttributes:requestedAttrib];
	if(pixelFormat!=nil)
	{
		self.pixelFormat = pixelFormat;
	}
	else
	{
		NSLog(@"Error: No appropriate pixel format found");
	}
	
    //	[self initializeOpenGLLayer];
}

- (void)reshape;
{
//	[[self openGLContext] update];
    [self.renderingDelegate resizeView];
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
	// Keep tracking mouse as you move the view area
//	[self mouseDown:theEvent];
	NSPoint currentMovementPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    [self.renderingDelegate rotateModelFromScreenDisplacementInX:(currentMovementPosition.x - lastMovementPosition.x) inY:(lastMovementPosition.y - currentMovementPosition.y)];
    lastMovementPosition = currentMovementPosition;
}

- (void)mouseUp:(NSEvent *)theEvent;
{
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	// Show the zoom options in a menu here
}



@end
