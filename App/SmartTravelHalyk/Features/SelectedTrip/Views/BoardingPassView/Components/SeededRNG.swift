struct SeededRNG {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
        if state == 0 { state = 12345 }
    }

    mutating func next(min: Int, max: Int) -> Int {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return min + Int(state % UInt64(max - min + 1))
    }
}
