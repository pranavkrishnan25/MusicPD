import os

import json

# import pdkit

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

    start_time = data[0]["timestamp"]

    for sample in data:
        sample["timestamp"] -= start_time

    filename = "sensor_data.json"

    if os.path.exists(filename):

        os.remove(filename)

    with open(filename, 'w') as f:

        json.dump(data, f)


if __name__ == '__main__':

    socketio.run(app, host="0.0.0.0")
