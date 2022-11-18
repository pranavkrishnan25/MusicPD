# MusicPD

## Aspects of Application

- **Baseline Measurements (one time procedure when first getting app)**
    - Baseline Cadence (CMPedometer)
    - Step Length (CMPedometer)
- **Symptom Detection**
    - Gait ✅
    - Dyskinesia
    - Tremors
        - *apple watch readings would be required
    - Bradykinesia
- **Treatment Options**
    - Metronome (auditory/sensory)
        - Vibrational
        - Beat
    - Songs
        - Personalized Playlist
            - Call Spotify Connect API request to play song off app, as long as Spotify is running in background.
            - Tempo/BPM (Baseline Cadence)
            - Danceability

## Logic/Reasoning

- Parkinson’s patients have issues walking
    - Rhythmic Auditory Cueing Therapy
        - provides external stimulation to cue beats during movement
        - Parkinson’s patients often lose inherent balance and internal tempo capabilities
        - By providing external stimulation we can compensate for the internal imbalance
        - Specialization based on baseline testing to configure music for individual patients music taste for therapy
