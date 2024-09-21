//
//  MusicServiceProtocol.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import Foundation
import MusicKit

protocol MusicServiceProtocol {
    func fetchPopularSong(for city: String) async throws -> Song
}
