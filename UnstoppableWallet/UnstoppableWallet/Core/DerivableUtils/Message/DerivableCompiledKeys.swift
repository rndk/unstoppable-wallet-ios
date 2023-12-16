import Foundation

public struct DerivableCompiledKeyMeta {
    public var isSigner: Bool
    public var isWritable: Bool
    public var isInvoked: Bool

    public init(isSigner: Bool, isWritable: Bool, isInvoked: Bool) {
        self.isSigner = isSigner
        self.isWritable = isWritable
        self.isInvoked = isInvoked
    }
}

public typealias DerivableKeyMetaMap = [String: DerivableCompiledKeyMeta]

public struct DerivableCompiledKeys {
    public var payer: PublicKey
    public var keyMetaMap: DerivableKeyMetaMap

    public init(payer: PublicKey, keyMetaMap: [String: DerivableCompiledKeyMeta]) {
        self.payer = payer
        self.keyMetaMap = keyMetaMap
    }

  public mutating func extractTableLookup(lookupTable: DerivableAddressLookupTableAccount) throws -> (DerivableMessageAddressTableLookup, DerivableAccountKeysFromLookups)? {
        let (writableIndexes, drainedWritableKeys) = try drainKeysFoundInLookupTable(
            lookupTableEntries: lookupTable.state.addresses
        ) { keyMeta in
            !keyMeta.isSigner && !keyMeta.isInvoked && keyMeta.isWritable
        }

        let (readonlyIndexes, drainedReadonlyKeys) = try drainKeysFoundInLookupTable(
            lookupTableEntries: lookupTable.state.addresses
        ) { keyMeta in
            !keyMeta.isSigner && !keyMeta.isInvoked && !keyMeta.isWritable
        }

        if writableIndexes.count == 0, readonlyIndexes.count == 0 {
            return nil
        }

        return (
            .init(
                accountKey: lookupTable.key,
                writableIndexes: writableIndexes,
                readonlyIndexes: readonlyIndexes
            ),
            .init(
                readonly: drainedReadonlyKeys,
                writable: drainedWritableKeys
            )
        )
    }

    internal mutating func drainKeysFoundInLookupTable(
        lookupTableEntries: [PublicKey],
        keyMetaFilter: (DerivableCompiledKeyMeta) -> Bool
    ) throws -> ([UInt8], [PublicKey]) {
        var lookupTableIndexes: [UInt8] = []
        var drainedKeys: [PublicKey] = []

        for (address, keyMeta) in keyMetaMap {
            if keyMetaFilter(keyMeta) {
                let key = try PublicKey(string: address)
                let lookupTableIndex = lookupTableEntries.firstIndex(of: key)
                if let lookupTableIndex = lookupTableIndex {
                    lookupTableIndexes.append(UInt8(lookupTableIndex))
                    drainedKeys.append(key)
                    keyMetaMap.removeValue(forKey: address)
                }
            }
        }

        return (lookupTableIndexes, drainedKeys)
    }

    func getMessageComponents() -> (DerivableMessageHeader, [PublicKey]) {
        let writableSigners = keyMetaMap.filter { _, meta in
            meta.isSigner && meta.isWritable
        }

        let readonlySigners = keyMetaMap.filter { _, meta in
            meta.isSigner && !meta.isWritable
        }

        let writableNonSigners = keyMetaMap.filter { _, meta in
            !meta.isSigner && meta.isWritable
        }

        let readonlyNonSigners = keyMetaMap.filter { _, meta in
            !meta.isSigner && !meta.isWritable
        }

        let header: DerivableMessageHeader = .init(
            numRequiredSignatures: writableSigners.count + readonlySigners.count,
            numReadonlySignedAccounts: readonlySigners.count,
            numReadonlyUnsignedAccounts: readonlyNonSigners.count
        )

        var staticAccountKeys: [PublicKey] = []
        staticAccountKeys.append(contentsOf: writableSigners.map(\.key).map { try! PublicKey(string: $0) })
        staticAccountKeys.append(contentsOf: readonlySigners.map(\.key).map { try! PublicKey(string: $0) })
        staticAccountKeys.append(contentsOf: writableNonSigners.map(\.key).map { try! PublicKey(string: $0) })
        staticAccountKeys.append(contentsOf: readonlyNonSigners.map(\.key).map { try! PublicKey(string: $0) })

        return (header, staticAccountKeys)
    }

    static func compile(instructions: [TransactionInstruction], payer: PublicKey) -> Self {
        var keyMetaMap: DerivableKeyMetaMap = .init()
        var getOrInsertDefault: (PublicKey, (inout DerivableCompiledKeyMeta) -> Void) -> DerivableCompiledKeyMeta = { pubKey, callback in
            let address = pubKey.base58EncodedString
            if var keyMeta = keyMetaMap[address] {
                callback(&keyMeta)
                keyMetaMap[address] = keyMeta
                return keyMeta
            } else {
                var keyMeta = DerivableCompiledKeyMeta(
                    isSigner: false,
                    isWritable: false,
                    isInvoked: false
                )
                callback(&keyMeta)
                keyMetaMap[address] = keyMeta
                return keyMeta
            }
        }

        _ = getOrInsertDefault(payer) { meta in
            meta.isSigner = true
            meta.isWritable = true
        }

        for ix in instructions {
            _ = getOrInsertDefault(ix.programId) { meta in meta.isInvoked = true }
            for accountMeta in ix.keys {
                _ = getOrInsertDefault(accountMeta.publicKey) { meta in
                    meta.isSigner = meta.isSigner || accountMeta.isSigner
                    meta.isWritable = meta.isWritable || accountMeta.isWritable
                }
            }
        }

        return .init(payer: payer, keyMetaMap: keyMetaMap)
    }
}
