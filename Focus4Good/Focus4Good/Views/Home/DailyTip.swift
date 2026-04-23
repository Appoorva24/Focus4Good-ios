// DailyTip.swift
// Defines the DailyTip model used in DummyData

import Foundation

struct DailyTip: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var isActive: Bool
}
