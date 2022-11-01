//
//  ContentView.swift
//  MusicPD
//
//  Created by Yash Patel on 5/30/22.
//

import SwiftUI
import CoreMotion
import SocketIO
import AVFoundation
import SpotifyWebAPI
import Combine

struct SensorSample : Codable {
    var z: Double
    var y: Double
    var x: Double
}

struct ContentView: View {
    
    private var motion = CMMotionManager()
//    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    private var samplingRate = 64.0
    private var samplingWindow = 256 // Samples
    private var samplingStep = 32 // Samples
    
    
    @State private var x = Double.zero
    @State private var y = Double.zero
    @State private var z = Double.zero
    
    @State private var cadence = Int.zero
    @State private var FoG = Int.zero
    
    @State private var SensorData = [SensorSample]()
    @State private var cancellables: Set<AnyCancellable> = []

    let socketManager = SocketManager(socketURL: URL(string: "http://192.168.4.26:3000")!, config: [.log(true), .compress])
    
    let spotify = Spotify()
    
    init() {
        
        let socket = socketManager.defaultSocket
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        
        socket.connect()
        
        spotify.authorize()

    
    }
    
    var body: some View {
        VStack {
            Text("X: \(Int(x))")
            Text("Y: \(Int(y))")
            Text("Z: \(Int(z))")
            Text("Cadence: \(cadence)")
            Text("FoG: \(FoG)")
        }.onAppear(perform: {
            
            if CMPedometer.isStepCountingAvailable() {
                pedometer.startUpdates(from: Date()) { pedometerData, error in
                    guard let pedometerData = pedometerData, error == nil else { return }

                    DispatchQueue.main.async {
                        if pedometerData.currentCadence?.intValue != nil {
                            cadence = Int(pedometerData.currentCadence!.doubleValue * 60)
                        }
                    }
                }

            }
            
            // Assuming dataset does not account for influence of gravity, so use self.motion.isAccelerometerAvailable
            // if dataset does account for gravity, use self.motion.isDeviceMotionAvailable
            
            if self.motion.isAccelerometerAvailable {

                // Assuming dataset does not account for influence of gravity, so use self.motion.accelerometerUpdateInterval, and self.motion.startAccelerometerUpdates()
                // if dataset does account for gravity, use self.motion.deviceMotionUpdateInterval, and self.motion.startDeviceMotionUpdates()
                
                self.motion.accelerometerUpdateInterval = 1.0 / samplingRate
                self.motion.startAccelerometerUpdates()

                let timer = Timer(fire:Date(), interval: (1.0 / samplingRate), repeats: true, block: {(timer) in
                    
                    // Assuming dataset does not account for influence of gravity, so use self.motion.accelerometerData
                    // if dataset does account for gravity, use self.motion.deviceMotion
                    
                    if let data = self.motion.accelerometerData {
                        
                        // multiply values by 1000 because ios accelerometer values are in units of G, but dataset is in mG
                        // Assuming dataset does not account for influence of gravity, so use data.acceleration.x
                        // if dataset does account for gravity, use data.userAcceleration.x
                        
                        self.x = round(1000 * data.acceleration.x)
                        self.y = round(1000 * data.acceleration.y)
                        self.z = round(1000 * data.acceleration.z)
                        
                        
                        SensorData.append(SensorSample(z: self.z, y: self.y, x: self.x))


                        if((SensorData.count > samplingWindow) && ((SensorData.count - samplingWindow) % samplingStep == 0)) {
                            do {
                                
                                SensorData = Array(SensorData[(SensorData.endIndex - samplingWindow) ..< SensorData.endIndex])
                                
                                let jsonEncoder = JSONEncoder()
                                let jsonData = try jsonEncoder.encode(SensorData)

                                socketManager.defaultSocket.emit("sensor update", jsonData)

                                SensorData = []

                            } catch {
                                print("JSONEncoder error:", error)
                            }

                        }
                    }

                })
                
                RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
                
                socketManager.defaultSocket.on("FoG Detection") {data, ack in
                    if let prediction = data[0] as? Int {
                        self.FoG = prediction
                        
                        if (self.FoG == 1) {
                            
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            
                            let playbackRequest = PlaybackRequest("spotify:track:6jvqaaUtBmcnxQnf5XKzFo")

                            spotify.api.play(playbackRequest)
                                .sink(receiveCompletion: { completion in
                                    print(completion)
                                })
                                .store(in: &spotify.cancellables)
                            
//                            if let player = player, player.isPlaying {
                                // stop playback
//                                player.stop()
//                            } else {
                                // set up player, and play
//                            let urlString = Bundle.main.path(forResource: "beep", ofType: "mp3")
                            
//                            do {
//                                try AVAudioSession.sharedInstance().setMode(.default)
//                                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
//                                try AVAudioSession.sharedInstance().setCategory(.playback)
                                
//                                guard let urlString = urlString else {
//                                    return
//                                }
                                    
//                                    player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: urlString))
//
//                                    guard let player = player else {
//                                        return
//                                    }

//                                    player.play()
                                    
                                    
//                                } catch {
//                                    print("AUDIO ERROR!")
//                                }
//
                                
                                
                                
//                            }
                            


                        }

                    }

                }
                
            }
        })
        .onOpenURL(perform: handleURL(_:))
    }
    
    
    func handleURL(_ url: URL) {
            
            // **Always** validate URLs; they offer a potential attack vector into
            // your app.
        guard url.scheme == Spotify.loginCallbackURL.scheme else {
                print("not handling URL: unexpected scheme: '\(url)'")
                return
            }
            
            print("received redirect from Spotify: '\(url)'")

            
            // Complete the authorization process by requesting the access and
            // refresh tokens.
            spotify.api.authorizationManager.requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                // This value must be the same as the one used to create the
                // authorization URL. Otherwise, an error will be thrown.
                state: spotify.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                // Whether the request succeeded or not, we need to remove the
                // activity indicator.
                
                /*
                 After the access and refresh tokens are retrieved,
                 `SpotifyAPI.authorizationManagerDidChange` will emit a signal,
                 causing `Spotify.authorizationManagerDidChange()` to be called,
                 which will dismiss the loginView if the app was successfully
                 authorized by setting the @Published `Spotify.isAuthorized`
                 property to `true`.
                 The only thing we need to do here is handle the error and show it
                 to the user if one was received.
                 */
                if case .failure(let error) = completion {
                    print("couldn't retrieve access and refresh tokens:\n\(error)")
                    let alertTitle: String
                    if let authError = error as? SpotifyAuthorizationError,
                       authError.accessWasDenied {
                        alertTitle = "You Denied The Authorization Request :("
                    }
                    else {
                        alertTitle =
                            "Couldn't Authorization With Your Account"
                    }
                    print(alertTitle)
                }
            })
            .store(in: &cancellables)
            
            // MARK: IMPORTANT: generate a new value for the state parameter after
            // MARK: each authorization request. This ensures an incoming redirect
            // MARK: from Spotify was the result of a request made by this app, and
            // MARK: and not an attacker.
            self.spotify.authorizationState = String.randomURLSafe(length: 128)
            
        }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

