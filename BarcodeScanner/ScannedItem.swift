// ScannedItem.swift
import Foundation

struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let code: String
    var name: String
    var quantity: Int
}
