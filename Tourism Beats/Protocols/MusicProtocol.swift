protocol MusicProtocol: Sendable {
    func fetchTopSong(countryCode: String) async throws -> AppSong
}
