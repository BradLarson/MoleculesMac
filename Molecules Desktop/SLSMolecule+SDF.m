#import "SLSMolecule+SDF.h"


@implementation SLSMolecule (SDF)

- (BOOL)readFromSDFData:(NSData *)fileData;
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
	NSString *sdfFileContents = [[NSString alloc] initWithData:fileData encoding:NSASCIIStringEncoding];
    
    NSRange locationOfHTMLTag = [sdfFileContents rangeOfString:@"<html"];
	if (locationOfHTMLTag.location != NSNotFound)
    {
        // Error in download
		return NO;
    }
    
    NSUInteger atomSerialNumber = 1;
	NSUInteger length = [sdfFileContents length];
	NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
	NSRange currentRange;
	
    BOOL hasReachedAtoms = NO, hasReachedBonds = NO;
    
	while (lineEnd < length) 
	{
//		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[sdfFileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
		currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
		NSString *currentLine = [sdfFileContents substringWithRange:currentRange];
        
        if ([currentLine length] > 67)
        {
            // Atoms
            hasReachedAtoms = YES;
            
            SLS3DPoint atomCoordinate;
            
            atomCoordinate.x = [[currentLine substringWithRange:NSMakeRange(0, 10)] floatValue];
            atomCoordinate.y = [[currentLine substringWithRange:NSMakeRange(10, 10)] floatValue];
            atomCoordinate.z = [[currentLine substringWithRange:NSMakeRange(20, 10)] floatValue];
            if (stillCountingAtomsInFirstStructure)
            {
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
            
            NSString *atomElement = [[currentLine substringWithRange:NSMakeRange(31, 3)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            [atomCoordinates setObject:[NSValue valueWithBytes:&atomCoordinate objCType:@encode(SLS3DPoint)] forKey:[NSNumber numberWithInteger:atomSerialNumber]];
            atomSerialNumber++;
            
            SLSAtomType processedAtomType;
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
            else if ([[atomElement uppercaseString] isEqualToString:@"FE"])
            {
                processedAtomType = IRON;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"SI"])
            {
                processedAtomType = SILICON;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"F"])
            {
                processedAtomType = FLUORINE;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"CL"])
            {
                processedAtomType = CHLORINE;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"BR"])
            {
                processedAtomType = BROMINE;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"I"])
            {
                processedAtomType = IODINE;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"CA"])
            {
                processedAtomType = CALCIUM;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"ZN"])
            {
                processedAtomType = ZINC;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"CD"])
            {
                processedAtomType = CADMIUM;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"NA"])
            {
                processedAtomType = SODIUM;
            }
            else if ([[atomElement uppercaseString] isEqualToString:@"MG"])
            {
                processedAtomType = MAGNESIUM;
            }
            else 
            {
                processedAtomType = UNKNOWN;
            }

            [self addAtomToDatabase:processedAtomType atPoint:atomCoordinate structureNumber:1 residueKey:UNKNOWNRESIDUE];
        }
        else if (([currentLine length] > 20) && (hasReachedAtoms))
        {
            hasReachedBonds = YES;
            // Bonds
            
            NSUInteger indexForFirstAtom  = [[currentLine substringWithRange:NSMakeRange(0, 3)] intValue];
            NSUInteger indexForSecondAtom  = [[currentLine substringWithRange:NSMakeRange(3, 3)] intValue];

            NSValue *startValue = [atomCoordinates objectForKey:[NSNumber numberWithInteger:indexForFirstAtom]];
            NSValue *endValue = [atomCoordinates objectForKey:[NSNumber numberWithInteger:indexForSecondAtom]];

            [self addBondToDatabaseWithStartPoint:startValue endPoint:endValue bondType:SINGLEBOND structureNumber:1 residueKey:UNKNOWNRESIDUE];
        }
        else if (([currentLine length] < 15) && (hasReachedBonds))
        {
            lineEnd = length + 1;
            break;
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
