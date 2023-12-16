infix operator ~<<: BitwiseShiftPrecedence

// FIXME: Make framework-only once tests support it
public func ~<< (lhs: UInt32, rhs: Int) -> UInt32 {
    (lhs << UInt32(rhs)) | (lhs >> UInt32(32 - rhs))
}
