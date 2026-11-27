//
//  UserInfoKeys.swift
//  
//
//  Created by Nigel Brooke on 2023-04-26.
//  Copyright (c) 2022 Steamclock Software, Ltd. All rights reserved.
//

import Foundation

/// Keys SteamcLog itself adds to `LogEntry.userInfo`, alongside whatever the app passes in.
public enum UserInfoKeys {
    @usableFromInline static let extraInfo = "steamclogExtraInfo"
    @usableFromInline static let detailedLogURLs = "steamclogDetailedLogURLs"

    /// The `Error` passed to `error(_:_:)` or `forwardedLog`. The Sentry destination reports it with `capture(error:)`.
    public static let error = "steamclogError"

    /// Not app attributes, so destinations shouldn't forward them as such.
    static let all: Set<String> = [extraInfo, detailedLogURLs, error]
}
