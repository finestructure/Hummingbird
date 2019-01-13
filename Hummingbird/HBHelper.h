//
//  HBHelper.h
//
//  Created by Sven A. Schmidt on 10/06/2018.
//

#ifndef HBHelper_h
#define HBHelper_h

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    equal,
    wider,
    smaller,
    disjoint
} MaskComparison;


MaskComparison compareMasks(int mask1, int mask2);


#endif /* EMRHelper_h */
