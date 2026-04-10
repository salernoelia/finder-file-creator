import Foundation

struct FileTemplate: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var ext: String
    var content: String
}
