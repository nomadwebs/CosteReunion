//
//  MeetingRoomBackground.swift
//  CosteReunion
//
//  Foto de sala de reuniones oscurecida para que el texto se lea.
//

import SwiftUI

/// Foto de sala de reuniones oscurecida para que el texto se lea.
/// Si no has añadido la imagen "meetingRoom" a Assets, usa un degradado.
struct MeetingRoomBackground: View {
    var body: some View {
        ZStack {
            if let photo = UIImage(named: "meetingRoom") {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [.indigo, .black],
                               startPoint: .top, endPoint: .bottom)
            }
            Color.black.opacity(0.55)
        }
        .ignoresSafeArea()
    }
}
