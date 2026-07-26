//
//  StableID.swift
//  LCVI DECA Study App
//
//  Deterministic UUIDs so seeding the bundled content twice never creates
//  duplicates, and so exports stay stable across installs.
//

import CryptoKit
import Foundation

extension UUID {
    static func stable(_ seed: String) -> UUID {
        let digest = Array(Insecure.MD5.hash(data: Data(seed.utf8)))
        return UUID(uuid: (
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]
        ))
    }
}
