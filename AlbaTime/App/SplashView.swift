//
//  SplashView.swift
//  AlbaTime
//
//  Created by 이준희 on 12/29/25.
//
import SwiftUI

struct SplashView: View {
    
    
    @State private var isAppear: Bool = false
    @State private var size: Double = 0.7
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            
            if isAppear {
                MainTabView()
            } else {
                VStack (spacing: 20) {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                } //:VStack
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0)) {
                        size = 1.0
                        opacity = 1.0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            isAppear = true
                        } //Dis
                    } //ANI
                } //opa
            }
        } //:ZStack
    }
}

#Preview {
    SplashView()
}

