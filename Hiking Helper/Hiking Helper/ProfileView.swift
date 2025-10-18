//
//  ProfileView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "star.fill") // Your icon make into profile image
                    .font(.title)
                    .foregroundColor(.green)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                
                Spacer()
                Image(systemName: "star.fill") // Your icon make into profile image
                    .font(.title)
                    .foregroundColor(.yellow)
                    .padding(.trailing, 10)
                    .padding(.top, 10)
            }
            Spacer()
        }
        VStack{
            Image(systemName:"globe")   //user image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width:225, height:225)
            Text("Username1234")
                .font(.largeTitle)
                
        }
        
    }
}

#Preview {
    ProfileView()
}
