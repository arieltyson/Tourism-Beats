protocol MusicProtocol {
    func fetchTopSong(countryCode: String) async throws -> AppSong
}
