#import "SLSDocumentController.h"
#import "SLSApplicationDelegate.h"

@implementation SLSDocumentController

- (void)removeDocument:(NSDocument *)document
{
    [super removeDocument:document];
    
    if ([[self documents] count] < 1)
    {
//        [(SLSApplicationDelegate *)[[NSApplication sharedApplication] delegate] showInitialHelp];
    }
}
@end
