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
        SLS3DPoint atomCoordinate;
        SLSAtomType processedAtomType;
        BOOL detectedAtomCoordinates = YES;
        
		[xyzFileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
		currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
		NSString *currentLine = [xyzFileContents substringWithRange:currentRange];
        
        double scannedNumber = 0.0;
        NSScanner *theScanner = [[NSScanner alloc] initWithString:currentLine];
        BOOL scanResult = [theScanner scanDouble:&scannedNumber];
        if (!scanResult)
        {
            NSString *atomElement;
            // Go back and grab the atom
            BOOL scanResult = [theScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&atomElement];
//            atomElement = [[atomElement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
            
            if ([atomElement isEqualToString:@"C"])
            {
                processedAtomType = CARBON;
            }
            else if ([atomElement isEqualToString:@"H"])
            {
                processedAtomType = HYDROGEN;
            }
            else if ([atomElement isEqualToString:@"O"])
            {
                processedAtomType = OXYGEN;
            }
            else if ([atomElement isEqualToString:@"N"])
            {
                processedAtomType = NITROGEN;
            }
            else if ([atomElement isEqualToString:@"S"])
            {
                processedAtomType = SULFUR;
            }
            else if ([atomElement isEqualToString:@"P"])
            {
                processedAtomType = PHOSPHOROUS;
            }
            else if ([atomElement isEqualToString:@"FE"])
            {
                processedAtomType = IRON;
            }
            else if ([atomElement isEqualToString:@"SI"])
            {
                processedAtomType = SILICON;
            }
            else if ([atomElement isEqualToString:@"F"])
            {
                processedAtomType = FLUORINE;
            }
            else if ([atomElement isEqualToString:@"CL"])
            {
                processedAtomType = CHLORINE;
            }
            else if ([atomElement isEqualToString:@"BR"])
            {
                processedAtomType = BROMINE;
            }
            else if ([atomElement isEqualToString:@"I"])
            {
                processedAtomType = IODINE;
            }
            else if ([atomElement isEqualToString:@"CA"])
            {
                processedAtomType = CALCIUM;
            }
            else if ([atomElement isEqualToString:@"ZN"])
            {
                processedAtomType = ZINC;
            }
            else if ([atomElement isEqualToString:@"CD"])
            {
                processedAtomType = CADMIUM;
            }
            else if ([atomElement isEqualToString:@"NA"])
            {
                processedAtomType = SODIUM;
            }
            else if ([atomElement isEqualToString:@"MG"])
            {
                processedAtomType = MAGNESIUM;
            }
            else
            {
                processedAtomType = UNKNOWN;
            }            
        }
        else
        {
            // Atom was specified in the first number
            NSInteger atomNumber = round(scannedNumber);
            
            switch(atomNumber)
            {
                case 1: processedAtomType = HYDROGEN; break;
                case 6: processedAtomType = CARBON; break;
                case 7: processedAtomType = NITROGEN; break;
                case 8: processedAtomType = OXYGEN; break;
                case 9: processedAtomType = FLUORINE; break;
                case 11: processedAtomType = SODIUM; break;
                case 12: processedAtomType = MAGNESIUM; break;
                case 14: processedAtomType = SILICON; break;
                case 15: processedAtomType = PHOSPHOROUS; break;
                case 16: processedAtomType = SULFUR; break;
                case 17: processedAtomType = CHLORINE; break;
                case 20: processedAtomType = CALCIUM; break;
                case 26: processedAtomType = IRON; break;
                case 30: processedAtomType = ZINC; break;
                case 35: processedAtomType = BROMINE; break;
                case 48: processedAtomType = CADMIUM; break;
                case 53: processedAtomType = IODINE; break;
                default: processedAtomType = UNKNOWN; break;
            }
        }
        
        
        NSInteger locationAfterFirstNumber = [theScanner scanLocation];
        
        scanResult = [theScanner scanDouble:&scannedNumber];
        if (!scanResult)
        {
            detectedAtomCoordinates = NO;
        }
        double firstNumber = scannedNumber;


        scanResult = [theScanner scanDouble:&scannedNumber];
        if (!scanResult)
        {
            detectedAtomCoordinates = NO;
        }

        double secondNumber = scannedNumber;
        scanResult = [theScanner scanDouble:&scannedNumber];
        double thirdNumber = scannedNumber;
        if (!scanResult)
        {
            detectedAtomCoordinates = NO;
        }
        
        if (detectedAtomCoordinates)
        {
            atomCoordinate.x = firstNumber;
            atomCoordinate.y = secondNumber;
            atomCoordinate.z = thirdNumber;
            
            [self addAtomToDatabase:processedAtomType atPoint:atomCoordinate structureNumber:1 residueKey:UNKNOWNRESIDUE];
            
            tallyForCenterOfMassInX += atomCoordinate.x;
            if (minimumXPosition > atomCoordinate.x)
            {
                minimumXPosition = atomCoordinate.x;
            }
            if (maximumXPosition < atomCoordinate.x)
            {
                maximumXPosition = atomCoordinate.x;
            }
            
            tallyForCenterOfMassInY += atomCoordinate.y;
            if (minimumYPosition > atomCoordinate.y)
            {
                minimumYPosition = atomCoordinate.y;
            }
            if (maximumYPosition < atomCoordinate.y)
            {
                maximumYPosition = atomCoordinate.y;
            }
            
            tallyForCenterOfMassInZ += atomCoordinate.z;
            if (minimumZPosition > atomCoordinate.z)
            {
                minimumZPosition = atomCoordinate.z;
            }
            if (maximumZPosition < atomCoordinate.z)
            {
                maximumZPosition = atomCoordinate.z;
            }
        }
    }

	if (numberOfAtoms > 0)
	{
		centerOfMassInX = tallyForCenterOfMassInX / (float)numberOfAtoms;
		centerOfMassInY = tallyForCenterOfMassInY / (float)numberOfAtoms;
		centerOfMassInZ = tallyForCenterOfMassInZ / (float)numberOfAtoms;
		scaleAdjustmentForX = 1.5 / (maximumXPosition - minimumXPosition);
		scaleAdjustmentForY = 1.5 / (maximumYPosition - minimumYPosition);
		scaleAdjustmentForZ = (1.5 * 1.25) / (maximumZPosition - minimumZPosition);
		if (scaleAdjustmentForY < scaleAdjustmentForX)
		{
			scaleAdjustmentForX = scaleAdjustmentForY;
		}
		if (scaleAdjustmentForZ < scaleAdjustmentForX)
		{
			scaleAdjustmentForX = scaleAdjustmentForZ;
		}
	}
    
	
    if (title == nil)
	{
		title = [filename copy];
	}
    
    compound = [title copy];
    
    return YES;
}

@end
