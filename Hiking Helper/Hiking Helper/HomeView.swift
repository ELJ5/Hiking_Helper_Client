//
//  HomeView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            HStack {
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
            
            HStack{
                
                VStack{
                    Text("Progress")
                    Text("75%")                    //need progress value based of to do list marked
                    Circle()
                        .trim(from: 0, to: 0.75) // Fills progress % of the circle
                        .stroke(.green, lineWidth: 10)
                        .frame(width: 125, height: 125)
                        .rotationEffect(.degrees(-90))
                        .padding()
                }
                
                VStack{
                    Text("CheckList")
                    
                    RoundedRectangle(cornerRadius:25)
                        .frame(width: 150, height:150)
                }
                
            }
            
            VStack{
                Text("Nearby Hikes")
                //Add interactive map with hikes nearby
                Image(systemName: "globe")
                    .frame(width:250, height:400)
                    .imageScale(.large)
                
            }
        }
        
        //add avatar and game features below
    }
}

#Preview {
    HomeView()
}
