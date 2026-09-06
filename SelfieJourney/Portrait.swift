import Foundation
import SwiftData
import UIKit

/// One quiet moment in a growing, private collection.
@Model
final class Portrait {
    var id: UUID
    var imageRevision: UUID = UUID()
    var date: Date
    @Attribute(.externalStorage) var imageData: Data
    var note: String
    var poseRawValue: String = "classic"

    init(date: Date = Date(), imageData: Data, note: String = "", pose: PortraitPose = .classic) {
        id = UUID()
        self.date = date
        self.imageData = imageData
        self.note = note
        self.poseRawValue = pose.rawValue
    }

    var image: UIImage? {
        UIImage(data: imageData)
    }
}
