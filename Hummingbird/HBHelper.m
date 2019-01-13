//
//  HBHelper.m
//
//  Created by Sven A. Schmidt on 10/06/2018.
//

#import "HBHelper.h"


MaskComparison compareMasks(int mask1, int mask2) {
    if (mask1 == mask2) {
        return equal;
    } else {
        int xor = mask1 ^ mask2;
        if (xor & mask1) {
            if (xor & mask2) {
                return disjoint;
            } else {
                return wider;
            }
        } else {
            return smaller;
        }
    }
}

