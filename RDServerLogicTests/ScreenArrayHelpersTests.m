//
//  RDServerLogicTests.m
//  RDServerLogicTests
//
//  Created by Ishaan Gulrajani on 8/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScreenArrayHelpersTests.h"
#include "../RDServer/ScreenArrayHelpers.m"

@implementation ScreenArrayHelpersTests

-(void)testOneAt {
    STAssertEquals(one_at(0), (unsigned char)0b10000000, @"one_at(0) failed!");
    STAssertEquals(one_at(1), (unsigned char)0b01000000, @"one_at(1) failed!");
    STAssertEquals(one_at(2), (unsigned char)0b00100000, @"one_at(2) failed!");
    STAssertEquals(one_at(3), (unsigned char)0b00010000, @"one_at(3) failed!");
    STAssertEquals(one_at(4), (unsigned char)0b00001000, @"one_at(4) failed!");
    STAssertEquals(one_at(5), (unsigned char)0b00000100, @"one_at(5) failed!");
    STAssertEquals(one_at(6), (unsigned char)0b00000010, @"one_at(6) failed!");
    STAssertEquals(one_at(7), (unsigned char)0b00000001, @"one_at(7) failed!");
}

-(void)testBitAt {
    unsigned char byte = 0b10101001;
    STAssertTrue(bit_at(byte, 0), @"bit_at(0) failed!");
    STAssertFalse(bit_at(byte, 1), @"bit_at(1) failed!");
    STAssertTrue(bit_at(byte, 2), @"bit_at(2) failed!");
    STAssertFalse(bit_at(byte, 3), @"bit_at(3) failed!");
    STAssertTrue(bit_at(byte, 4), @"bit_at(4) failed!");
    STAssertFalse(bit_at(byte, 5), @"bit_at(5) failed!");
    STAssertFalse(bit_at(byte, 6), @"bit_at(6) failed!");
    STAssertTrue(bit_at(byte, 7), @"bit_at(7) failed!");
}

-(void)testFillRow {
    unsigned char array[4];
    unsigned char reference[4] = {
        0b00000000,
        0b00111111,
        0b11111000,
        0b00000000
    };
    
    fill_row(array, 10, 11, YES);
    
    for(int i = 0; i < 4; i++)
        STAssertEquals(array[i], reference[i], @"fill_row failed! bit %i: %x != %x", i, array[i], reference[i]);
}

-(void)testFillRect {
    unsigned char array[12];
    unsigned char reference[12] = {
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00000000,
        0b00111111,
        0b11111000,
        0b00000000,
        0b00000000,
        0b00111111,
        0b11111000,
        0b00000000
    };
    
    fill_rect(array, 4, CGRectMake(10, 1, 11, 2), YES);
    
    for(int i = 0; i < 12; i++)
        STAssertEquals(array[i], reference[i], @"fill_rect failed! bit %i: %x != %x", i, array[i], reference[i]);
}

@end
