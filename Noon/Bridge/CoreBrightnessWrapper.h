//
//  CoreBrightnessWrapper.h
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Error domain for CoreBrightness wrapper errors
extern NSString * const CBWrapperErrorDomain;

/// Error codes for CoreBrightness operations
typedef NS_ENUM(NSInteger, CBWrapperErrorCode) {
    CBWrapperErrorFrameworkNotLoaded = 1000,
    CBWrapperErrorClientNotAvailable = 1001,
    CBWrapperErrorOperationFailed    = 1002,
    CBWrapperErrorNotSupported       = 1003,
};

@interface CoreBrightnessWrapper : NSObject

/// Shared singleton instance
+ (instancetype)shared;

/// Whether the CoreBrightness framework was successfully loaded
@property (nonatomic, readonly) BOOL isFrameworkLoaded;

/// Whether True Tone is supported on this hardware
@property (nonatomic, readonly) BOOL isTrueToneSupported;

// MARK: - Night Shift (Blue Light)

/// Get the current Night Shift enabled state
- (BOOL)isNightShiftEnabledWithError:(NSError * _Nullable * _Nullable)error NS_SWIFT_NOTHROW NS_SWIFT_NAME(isNightShiftEnabled(error:));

/// Enable or disable Night Shift
- (BOOL)setNightShiftEnabled:(BOOL)enabled error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NOTHROW NS_SWIFT_NAME(setNightShiftEnabled(_:error:));

/// Get the current Night Shift strength (0.0 - 1.0)
- (float)nightShiftStrengthWithError:(NSError * _Nullable * _Nullable)error NS_SWIFT_NOTHROW NS_SWIFT_NAME(nightShiftStrength(error:));

// MARK: - True Tone (Color Adaptation)

/// Get the current True Tone enabled state
- (BOOL)isTrueToneEnabledWithError:(NSError * _Nullable * _Nullable)error NS_SWIFT_NOTHROW NS_SWIFT_NAME(isTrueToneEnabled(error:));

/// Enable or disable True Tone
- (BOOL)setTrueToneEnabled:(BOOL)enabled error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NOTHROW NS_SWIFT_NAME(setTrueToneEnabled(_:error:));

// MARK: - Lifecycle

/// Attempt to reload the CoreBrightness framework (e.g. after system update)
- (BOOL)reloadFramework;

@end

NS_ASSUME_NONNULL_END
