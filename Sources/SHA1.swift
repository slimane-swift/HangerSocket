// Originally based on CryptoSwift by Marcin Krzyżanowski <marcin.krzyzanowski@gmail.com>
// Copyright (C) 2014 Marcin Krzyżanowski <marcin.krzyzanowski@gmail.com>
// This software is provided 'as-is', without any express or implied warranty.
//
// In no event will the authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
// - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
// - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
// - This notice may not be removed or altered from any source or binary distribution.

func rotateLeft(_ value: UInt8, count: UInt8) -> UInt8 {
    return ((value << count) & 0xFF) | (value >> (8 - count))
}

func rotateLeft(_ value: UInt16, count: UInt16) -> UInt16 {
    return ((value << count) & 0xFFFF) | (value >> (16 - count))
}

func rotateLeft(_ value: UInt32, count: UInt32) -> UInt32 {
    return ((value << count) & 0xFFFFFFFF) | (value >> (32 - count))
}

func rotateLeft(_ value: UInt64, count: UInt64) -> UInt64 {
    return (value << count) | (value >> (64 - count))
}

func rotateRight(_ value: UInt16, count: UInt16) -> UInt16 {
    return (value >> count) | (value << (16 - count))
}

func rotateRight(_ value: UInt32, count: UInt32) -> UInt32 {
    return (value >> count) | (value << (32 - count))
}

func rotateRight(_ value: UInt64, count: UInt64) -> UInt64 {
    return ((value >> count) | (value << (64 - count)))
}

func reverseBytes(_ value: UInt32) -> UInt32 {
    return ((value & 0x000000FF) << 24) | ((value & 0x0000FF00) << 8) | ((value & 0x00FF0000) >> 8)  | ((value & 0xFF000000) >> 24);
}

func arrayOfBytes<T>(_ value: T, length: Int? = nil) -> [UInt8] {
    let totalBytes = length ?? sizeof(T)

    let valuePointer = UnsafeMutablePointer<T>(allocatingCapacity: 1)
    valuePointer.pointee = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(valuePointer)
    var bytes = [UInt8](repeating: 0, count: totalBytes)
    for j in 0..<min(sizeof(T),totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }

    valuePointer.deinitialize(count: 1)
    valuePointer.deallocateCapacity(1)

    return bytes
}

func toUInt32Array(_ slice: ArraySlice<UInt8>) -> Array<UInt32> {
    var result = Array<UInt32>()
    result.reserveCapacity(16)
    for idx in stride(from: slice.startIndex, to: slice.endIndex, by: sizeof(UInt32)) {
        let val1:UInt32 = (UInt32(slice[idx.advanced(by: 3)]) << 24)
        let val2:UInt32 = (UInt32(slice[idx.advanced(by: 2)]) << 16)
        let val3:UInt32 = (UInt32(slice[idx.advanced(by: 1)]) << 8)
        let val4:UInt32 = UInt32(slice[idx])
        let val:UInt32 = val1 | val2 | val3 | val4
        result.append(val)
    }

    return result
}

let size: Int = 20 // 160 / 8
let h: [UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]

func sha1(_ data: Data) -> Data {
    let len = 64
    let originalMessage = data.bytes
    var tmpMessage = data.bytes

    // Step 1. Append Padding Bits
    tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message

    // append "0" bit until message length in bits ≡ 448 (mod 512)
    var msgLength = tmpMessage.count
    var counter = 0

    while msgLength % len != (len - 8) {
        counter += 1
        msgLength += 1
    }

    tmpMessage += Array<UInt8>(repeating: 0, count: counter)
    // hash values
    var hh = h

    // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
    tmpMessage += arrayOfBytes(originalMessage.count * 8, length: 64 / 8)

    // Process the message in successive 512-bit chunks:
    let chunkSizeBytes = 512 / 8 // 64
    for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
        // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
        // Extend the sixteen 32-bit words into eighty 32-bit words:
        var M:[UInt32] = [UInt32](repeating: 0, count: 80)
        for x in 0..<M.count {
            switch (x) {
            case 0...15:
                let start = chunk.startIndex + (x * sizeofValue(M[x]))
                let end = start + sizeofValue(M[x])
                let le = toUInt32Array(chunk[start..<end])[0]
                M[x] = le.bigEndian
                break
            default:
                M[x] = rotateLeft(M[x-3] ^ M[x-8] ^ M[x-14] ^ M[x-16], count: 1)
                break
            }
        }

        var A = hh[0]
        var B = hh[1]
        var C = hh[2]
        var D = hh[3]
        var E = hh[4]

        // Main loop
        for j in 0...79 {
            var f: UInt32 = 0;
            var k: UInt32 = 0

            switch (j) {
            case 0...19:
                f = (B & C) | ((~B) & D)
                k = 0x5A827999
                break
            case 20...39:
                f = B ^ C ^ D
                k = 0x6ED9EBA1
                break
            case 40...59:
                f = (B & C) | (B & D) | (C & D)
                k = 0x8F1BBCDC
                break
            case 60...79:
                f = B ^ C ^ D
                k = 0xCA62C1D6
                break
            default:
                break
            }

            let temp = (rotateLeft(A, count:5) &+ f &+ E &+ M[j] &+ k) & 0xffffffff
            E = D
            D = C
            C = rotateLeft(B, count: 30)
            B = A
            A = temp
        }

        hh[0] = (hh[0] &+ A) & 0xffffffff
        hh[1] = (hh[1] &+ B) & 0xffffffff
        hh[2] = (hh[2] &+ C) & 0xffffffff
        hh[3] = (hh[3] &+ D) & 0xffffffff
        hh[4] = (hh[4] &+ E) & 0xffffffff
    }

    // Produce the final hash value (big-endian) as a 160 bit number:
    var result = [UInt8]()
    result.reserveCapacity(hh.count / 4)

    hh.forEach {
        let item = $0.bigEndian
        result += [UInt8(item & 0xff), UInt8((item >> 8) & 0xff), UInt8((item >> 16) & 0xff), UInt8((item >> 24) & 0xff)]
    }

    return Data(result)
}

struct BytesSequence: Sequence {
    let chunkSize: Int
    let data: [UInt8]

    func makeIterator() -> AnyIterator<ArraySlice<UInt8>> {
        var offset: Int = 0

        return AnyIterator {
            var end: Int
            if self.chunkSize < self.data.count - offset {
              end = self.chunkSize
            } else {
              end = self.data.count - offset
            }
            let result = self.data[offset ..< offset + end]
            offset += result.count
            return result.count > 0 ? result : nil
        }
    }
}
