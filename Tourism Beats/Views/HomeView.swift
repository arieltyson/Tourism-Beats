import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            EarthView()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("Tourism Beats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .italic()
                    .foregroundColor(.white)
                Text("an immersive tourist experience")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.white)

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
