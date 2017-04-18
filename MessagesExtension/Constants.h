//
//  Constants.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/5/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface Constants : NSObject

+ (NSUserDefaults*) sharedUserDefaults;

+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

+ (NSArray*) getPHAssetCollectionSubtypes;

+ (NSString*) getDocumentsDirectory;
+ (NSString*) getSendFormatUsingCurrentDate;

+ (PHImageRequestOptions*) getPhotoRequestOptions;
+ (PHVideoRequestOptions*) getVideoRequestOptions;

+ (NSString*) generateEncryptionKey;

@end
