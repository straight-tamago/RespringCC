//
//  Overwrite.swift
//  RespringCC
//
//  Created by mini on 2023/02/03.
//

import SwiftUI

func OverwriteData(TargetFilePath: String, OverwriteFileData: Data) -> String {
    let fd = open(TargetFilePath, O_RDONLY | O_CLOEXEC)
    defer { close(fd) }

    let originalSize = lseek(fd, 0, SEEK_END)
    guard originalSize >= OverwriteFileData.count else {
      return "(Error) FileSize too big\n"+String(originalSize)+" > "+String(OverwriteFileData.count)
    }
    lseek(fd, 0, SEEK_SET)

    let Map = mmap(nil, OverwriteFileData.count, PROT_READ, MAP_SHARED, fd, 0)
    if Map == MAP_FAILED {
        return "mmap Error"
    }
    guard mlock(Map, OverwriteFileData.count) == 0 else {
        return "mlock Error"
    }
    for chunkOff in stride(from: 0, to: OverwriteFileData.count, by: 0x4000) {
        let dataChunk = OverwriteFileData[chunkOff..<min(OverwriteFileData.count, chunkOff + 0x3fff)]
        var overwroteOne = false
        for _ in 0..<2 {
            let overwriteSucceeded = dataChunk.withUnsafeBytes { dataChunkBytes in
                return unaligned_copy_switch_race(
                    fd, Int64(chunkOff), dataChunkBytes.baseAddress, dataChunkBytes.count)
            }
            if overwriteSucceeded {
                overwroteOne = true
                break
            }
            sleep(1)
        }
        guard overwroteOne else {
            return "unknown Error"
        }
    }
    return "Success"
}
