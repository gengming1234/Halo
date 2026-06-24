import UIKit

struct LiveRoom {
    let id: String
    let title: String
    let hostName: String
    let viewerCount: Int
    let coverColor: UIColor

    static let mockData: [LiveRoom] = [
        LiveRoom(id: "1", title: "今日穿搭分享🌸", hostName: "小红", viewerCount: 12300, coverColor: .systemPink),
        LiveRoom(id: "2", title: "护肤品大测评",   hostName: "美美",  viewerCount: 8800,  coverColor: .systemPurple),
        LiveRoom(id: "3", title: "美食探店vlog",   hostName: "吃货君", viewerCount: 23100, coverColor: .systemOrange),
        LiveRoom(id: "4", title: "健身打卡第30天", hostName: "运动达人", viewerCount: 5600, coverColor: .systemGreen),
        LiveRoom(id: "5", title: "旅行日记·云南",  hostName: "流浪者",  viewerCount: 31000, coverColor: .systemBlue),
    ]
}
