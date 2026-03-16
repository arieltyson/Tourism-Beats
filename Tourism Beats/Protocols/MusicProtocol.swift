protocol MusicProtocol: Sendable {
    func fetchTopSong(for city: CityModel) async throws -> AppSong
}
