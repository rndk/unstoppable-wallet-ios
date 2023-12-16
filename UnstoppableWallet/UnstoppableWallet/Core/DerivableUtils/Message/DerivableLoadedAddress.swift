//
//  DerivableLoadedAddress.swift
//  UnstoppableWallet
//
//  Created by rmnn on 14.12.2023.
//  Copyright © 2023 Grouvi. All rights reserved.
//

import Foundation

public typealias DerivableAccountKeysFromLookups = DerivableLoadedAddresses

public struct DerivableLoadedAddresses {
    var readonly: [PublicKey]
    var writable: [PublicKey]

    public init(readonly: [PublicKey], writable: [PublicKey]) {
        self.readonly = readonly
        self.writable = writable
    }
}

public struct DerivableMessageAccountKeys {
    public var staticAccountKeys: [PublicKey]
    public var accountKeysFromLookups: DerivableAccountKeysFromLookups?

    public init(
        staticAccountKeys: [PublicKey],
        accountKeysFromLookups: DerivableAccountKeysFromLookups? = nil
    ) {
        self.staticAccountKeys = staticAccountKeys
        self.accountKeysFromLookups = accountKeysFromLookups
    }

    public var keySegments: [[PublicKey]] {
        var keySegments = [staticAccountKeys]
        if let accountKeysFromLookups = accountKeysFromLookups {
            keySegments.append(accountKeysFromLookups.writable)
            keySegments.append(accountKeysFromLookups.readonly)
        }

        return keySegments
    }

    public subscript(index: Int) -> PublicKey? {
        var index = index

        for keySegment in keySegments {
            if index < keySegment.count {
                return keySegment[index]
            } else {
                index -= keySegment.count
            }
        }
        return nil
    }

    public var count: Int {
        keySegments.reduce([], +).count
    }

    public func compileInstructions(
        instructions: [TransactionInstruction]
    ) throws -> [DerivableMessageCompiledInstruction] {
        if count > UInt8.max {
            throw DerivableVersionedMessageError.other("Account index overflow encountered during compilation")
        }
        var keyIndexMap: [String: Int] = [:]
        keySegments
            .reduce([], +)
            .enumerated()
            .forEach { index, key in
                keyIndexMap[key.base58EncodedString] = index
            }

        func findKeyIndex(key: PublicKey) throws -> Int {
            if let keyIndex = keyIndexMap[key.base58EncodedString] {
                return keyIndex
            }
            throw DerivableVersionedMessageError.other("Encountered an unknown instruction account key during compilation")
        }

        return try instructions.map { (instruction: TransactionInstruction) in
            try .init(
                programIdIndex: UInt8(findKeyIndex(key: instruction.programId)),
                accountKeyIndexes: instruction.keys.map { meta in try UInt8(findKeyIndex(key: meta.publicKey)) },
                data: instruction.data
            )
        }
    }
}
