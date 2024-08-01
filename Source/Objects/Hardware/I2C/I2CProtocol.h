//
//  I2CProtocol.h
//  Orca
//
//  Created by Mark Howe on 8/1/24.
//

#ifndef I2CProtocol_h
#define I2CProtocol_h

@protocol I2CProtocol
- (id <I2CProtocol>) getI2CMaster;
- (id) readI2CData;

@end

#endif /* I2CProtocol_h */
