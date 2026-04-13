//
//  CoreBrightnessHeaders.h
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

#ifndef CoreBrightnessHeaders_h
#define CoreBrightnessHeaders_h

#import <Foundation/Foundation.h>

// MARK: - Night Shift (Blue Light) Status Data

typedef struct {
    BOOL active;
    BOOL enabled;
    BOOL sunSchedulePermitted;
    int mode;               // 0 = off, 1 = sun schedule, 2 = custom schedule
    struct {
        int hour;
        int minute;
    } schedule_start;
    struct {
        int hour;
        int minute;
    } schedule_end;
    unsigned long long disableFlags;
} CBBlueLightStatus;

// MARK: - CBBlueLightClient (Night Shift)

@interface CBBlueLightClient : NSObject

- (id)init;

/// Get the current Night Shift status
- (BOOL)getBlueLightStatus:(CBBlueLightStatus *)status;

/// Enable or disable Night Shift
- (BOOL)setEnabled:(BOOL)enabled;

/// Set the Night Shift color temperature strength (0.0 - 1.0)
- (BOOL)setStrength:(float)strength commit:(BOOL)commit;

/// Get the current strength
- (BOOL)getStrength:(float *)strength;

/// Set a notification block for status changes
- (void)setStatusNotificationBlock:(void (^)(void))block;

@end

// MARK: - CBTrueToneClient (True Tone / Color Adaptation)

@interface CBTrueToneClient : NSObject

- (id)init;

/// Check if True Tone is supported on this hardware
- (BOOL)supported;

/// Check if True Tone is currently enabled
- (BOOL)enabled;

/// Enable or disable True Tone
- (BOOL)setEnabled:(BOOL)enabled;

/// Set a notification block for status changes
- (void)setStatusNotificationBlock:(void (^)(void))block;

@end

#endif /* CoreBrightnessHeaders_h */
