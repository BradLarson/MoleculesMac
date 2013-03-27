#import "SLSMolecule.h"

@interface SLSMolecule (SDF)

- (BOOL)readFromSDFData:(NSData *)fileData;

@end
