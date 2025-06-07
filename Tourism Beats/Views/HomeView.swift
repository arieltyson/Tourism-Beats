import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EarthView()
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    VStack {
                        Text("Tourism Beats")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .italic()
                        Text("an immersive tourist experience")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .italic()
                    }
                    .padding(.top, 50)

                    Spacer()

                    NavigationLink(destination: WorldView()) {
                        Text("Choose a City")
                            .font(.title)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }

                    Spacer()
                }
                .padding()
            }
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
