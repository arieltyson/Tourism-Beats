protocol MusicServiceProtocol {
    func fetchTopSong(countryCode: String) async throws -> AppSong
}
