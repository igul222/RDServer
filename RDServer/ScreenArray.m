//
//  ScreenArray.m
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScreenArray.h"

#define ALL_ONES 0b11111111
#define ALL_ZEROES 0b00000000
#define PIXEL_LOC(x,y) ((((int)(x))/8)+(bytesPerRow*(y)))
#define RECT_SIZE(x) ((x).size.width * (x).size.height)

static inline unsigned char leading_ones(const unsigned char ones) {
    switch (ones) {
        case 0:
            return 0b00000000;
        case 1:
            return 0b10000000;
        case 2:
            return 0b11000000;
        case 3:
            return 0b11100000;
        case 4:
            return 0b11110000;
        case 5:
            return 0b11111000;
        case 6:
            return 0b11111100;
        case 7:
            return 0b11111110;
        default:
            return 0b11111111;
    }
}

static inline unsigned char leading_zeroes(const unsigned char zeroes) {
    switch (zeroes) {
        case 0:
            return 0b11111111;
        case 1:
            return 0b01111111;
        case 2:
            return 0b00111111;
        case 3:
            return 0b00011111;
        case 4:
            return 0b00001111;
        case 5:
            return 0b00000111;
        case 6:
            return 0b00000011;
        case 7:
            return 0b00000001;
        default:
            return 0b00000000;
    }
}

static inline unsigned char one_at(const int location) {
    return 0b100000000 >> location;
}

static inline unsigned char bit_at(const unsigned char byte,
                                   const int location) {
    return (byte & one_at(location));
}

static inline void fill_row(unsigned char *array,
                            const int start_bit,
                            int length,
                            const BOOL value) {
    int byte = start_bit / 8;
    
    // write the first byte
    if(value)
        array[byte] = array[byte] | leading_zeroes(start_bit % 8);
    else
        array[byte] = array[byte] & leading_ones(start_bit % 8);
    
    length -= (8 - (start_bit%8));
    byte++;
    
    // write the bytes in the middle
    while (length >= 8) {
        array[byte] = (value ? ALL_ONES : ALL_ZEROES);
        length -= 8;
        byte++;
    }
    
    // write the end byte
    if(value)
        array[byte] = array[byte] | leading_ones(length);
    else
        array[byte] = array[byte] & leading_zeroes(length);
}

static void fill_rect(unsigned char *array,
                      const int bytesPerRow,
                      const CGRect rect, 
                      const BOOL value) {
    
    int width = (int)rect.size.width;
    int ylimit = (int)(rect.origin.y + rect.size.height);
    
    for(int y = (int)rect.origin.y; y < ylimit; y++) {
        fill_row(array, (bytesPerRow*y*8)+rect.origin.x, width, value);
    }
}

static int find_next_bit(const unsigned char *array,
                         const int array_length,
                         const int bit_offset,
                         BOOL look_for_set_bit,
                         BOOL return_negative_on_not_found) {
    
    int byte_offset = bit_offset/8; //16000
    unsigned char byte;
    if(look_for_set_bit) // thought! is it really supposed to be array[bit_offset]? byte offset, right?!?!
        byte = array[byte_offset] & leading_zeroes(bit_offset % 8);
    else
        byte = array[byte_offset] | leading_ones(bit_offset % 8);
    
    if(look_for_set_bit) {
        while (!byte && (byte_offset < array_length)) {
            byte_offset++;
            byte = array[byte_offset];
        }   
    } else {
        while ((byte == ALL_ONES) && (byte_offset < array_length)) {
            byte_offset++;
            byte = array[byte_offset];
        }
    }
    
    if(byte_offset == array_length)
        return (return_negative_on_not_found ? -1 : byte_offset * 8);
    
    int int_byte = (int)(look_for_set_bit ? byte : ~byte);
    int msb;
    asm("bsrl %1,%0" 
        : "=r"(msb) 
        : "r"(int_byte));
    msb = 7 - msb;
    
    return (byte_offset * 8) + msb;
}

@interface ScreenArray ()
@end

@implementation ScreenArray

#pragma mark - Init and dealloc

- (id)initWithSize:(RDScreenRes)size {
    self = [super init];
    if (self) {
        @synchronized(self) {
            resolution = size;
            // divide by eight and round up
            bytesPerRow = (int)(resolution.width / 8) + (resolution.width % 8 == 0 ? 0 : 1);
            arrayLength = (int)(bytesPerRow * resolution.height);
            array = malloc(arrayLength);
            // we don't just write ALL_ONES to the array because we want the padding bits at the end of each row to be 0.
            fill_rect(array, bytesPerRow, CGRectMake(0, 0, resolution.width, resolution.height), YES);
        }
    }
    return self;
}

-(void)dealloc {
    @synchronized(self) {
        free(array);
    }
    [super dealloc];
}

#pragma mark - Operations

-(void)fillRects:(CGRect *)rectArray count:(CGRectCount)count {
    @synchronized(self) {
        for (int i=0; i<count; i++) {
            fill_rect(array, bytesPerRow, rectArray[i], YES);
        }
    }
}

-(RectArray)dirtyRects {
    RectArray result;
    result.count = 0;
    result.capacity = 5;
    result.array = malloc(sizeof(CGRect)*result.capacity);
    
    @synchronized(self) {
        
        int bits_per_row = bytesPerRow * 8;
        
        int bit_offset = 0;
        int rect_beginning = 0;
        
        while ((rect_beginning = find_next_bit(array, arrayLength, bit_offset, YES, YES)) != -1) {
            
            int rect_origin_x = (rect_beginning % bits_per_row);
            // rect_row_end = ceil(rect_beginning / bits_per_row)
            int rect_row_end = ((rect_beginning + bits_per_row - 1) / bits_per_row) * bytesPerRow;
            if(rect_origin_x % bits_per_row == 0)
                rect_row_end += bytesPerRow;
            
            int rect_end_bit = find_next_bit(array, 
                                             rect_row_end, // location of the end of the row
                                             rect_beginning, 
                                             NO,
                                             NO);
            int rect_width = rect_end_bit - rect_beginning;
            
            int rect_height = 1;
            int row_end;
            while ((row_end = rect_row_end + ((rect_height-1) * bytesPerRow)) < arrayLength && 
                   find_next_bit(array, 
                                 row_end, 
                                 rect_beginning + ((rect_height-1) * bits_per_row),
                                 NO,
                                 NO
                                 ) - ((rect_height-1)*bits_per_row) == rect_end_bit) {
                       rect_height++;
                   }
            
            CGRect rect = CGRectMake(rect_origin_x, rect_beginning / bits_per_row, rect_width, rect_height);
            fill_rect(array, bytesPerRow, rect, NO);
            
            result.count = result.count + 1;
            if(result.count > result.capacity) {
                result.capacity += 5;
                result.array = realloc(result.array, sizeof(CGRect)*result.capacity);
            }
            result.array[result.count - 1] = rect;
            
        }
    }
    
    if(result.count >= 2) {
        for(int i=0;i<result.count-1;i++) {
            CGRect unionRect = CGRectUnion(result.array[0], result.array[1]);
            
            CGFloat rectSizeRatio = RECT_SIZE(unionRect)/(RECT_SIZE(result.array[0]) + RECT_SIZE(result.array[1]));
            if(rectSizeRatio >= 1.5) {
                result.array[0] = CGRectZero;
                result.array[1] = unionRect;
            }
        }
    }
    
    return result;
}

-(NSUInteger)height {
    return resolution.height;
}

@end
