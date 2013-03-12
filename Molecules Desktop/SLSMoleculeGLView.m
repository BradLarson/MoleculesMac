#import "SLSMoleculeGLView.h"

@implementation SLSMoleculeGLView

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
	[[self openGLContext] update];
}

@end
