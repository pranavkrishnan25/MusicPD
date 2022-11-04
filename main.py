import os
import json
# import uuid
from flask import Flask
from flask_socketio import SocketIO, emit
from dotenv import load_dotenv
import sensormotion as sm
import numpy as np

cadences = []


load_dotenv()
FLASK_SECRET_KEY = os.getenv('FLASK_SECRET_KEY')

app = Flask(__name__)
app.config['SECRET_KEY'] = FLASK_SECRET_KEY
socketio = SocketIO(app, async_mode="eventlet")


@socketio.on('connect')
def on_connect():
    # emit('my response', {'data': 'Connected'})
    print("client connected.")


@socketio.on('sensor update')
def calculate_gait(json_raw):

    data = json.loads(json_raw)

    axis = "z"
    axis_data = []
    timestamps = []

    for sample in data:
        axis_data.append(sample[axis])
        timestamps.append((sample["timestamp"] - data[0]["timestamp"]) * 1000)

    axis_data = np.array(axis_data)
    timestamps = np.array(timestamps)

    b, a = sm.signal.build_filter(frequency=10,
                                  sample_rate=100,
                                  filter_type='low',
                                  filter_order=4)

    axis_data_filtered = sm.signal.filter_signal(b, a, signal=axis_data)

    peak_times, peak_values = sm.peak.find_peaks(time=timestamps, signal=axis_data_filtered,
                                                 peak_type='valley',
                                                 min_val=0.6, min_dist=30,
                                                 plot=False)

    cadence = sm.gait.cadence(
        time=timestamps, peak_times=peak_times, time_units='ms')
    step_mean, step_sd, step_cov = sm.gait.step_time(peak_times=peak_times)

    print(cadence)
    # print(step_mean)
    # print(step_sd)
    # print(step_cov)

    cadences.append(cadence)

    if len(cadences) == 6:
        print("average cadence:", sum(cadences) / len(cadences))
        cadences.pop(0)


if __name__ == '__main__':
    socketio.run(app, host="0.0.0.0")
