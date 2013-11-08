//
//  MNGModalProtocol.h
//  MNGModal
//
//  Created by Paperless Post on 11/1/13.
//
//

#import <Foundation/Foundation.h>

@protocol MNGModalProtocol <NSObject>

- (void)tapDetectedOutsideModal:(UITapGestureRecognizer *)tapGestureRecognizer;

@end
