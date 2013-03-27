#import "SLSMolecule+XYZ.h"

@implementation SLSMolecule (XYZ)

- (BOOL)readFromXYZData:(NSData *)fileData;
{
    NSMutableDictionary *atomCoordinates = [[NSMutableDictionary alloc] init];
    stillCountingAtomsInFirstStructure = YES;
    
	numberOfAtoms = 0;
    numberOfBonds = 0;
    numberOfStructures = 1;
    
	float tallyForCenterOfMassInX = 0.0f, tallyForCenterOfMassInY = 0.0f, tallyForCenterOfMassInZ = 0.0f;
	minimumXPosition = 1000.0f;
	maximumXPosition = 0.0f;
	minimumYPosition = 1000.0f;
	maximumYPosition = 0.0f;
	minimumZPosition = 1000.0f;
	maximumZPosition = 0.0f;
    
	// Load the file into a string for processing
	NSString *xyzFileContents = [[NSString alloc] initWithData:fileData encoding:NSASCIIStringEncoding];
    
    NSUInteger atomSerialNumber = 1;
	NSUInteger length = [xyzFileContents length];
	NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
	NSRange currentRange;
	
    BOOL hasReachedAtoms = NO, hasReachedBonds = NO;
    
	while (lineEnd < length)
	{
		[xyzFileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
		currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
		NSString *currentLine = [xyzFileContents substringWithRange:currentRange];
        
        if ([currentLine length] > 67)
        {
            double scannedNumber = 0.0;
            NSScanner *theScanner = [[NSScanner alloc] initWithString:currentLine];
            BOOL scanResult = [theScanner scanDouble:&scannedNumber];
            

        }
    }
    
    
}

@end
