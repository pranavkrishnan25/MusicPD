import os
import json
from flask import Flask, request
from flask_socketio import SocketIO, emit
from dotenv import load_dotenv
import numpy as np
import tensorflow as tf
import pandas as pd


def load_model(model_path):

    # Load the TFLite model and allocate tensors.
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    # Get input and output tensors.
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    return interpreter, input_details, output_details


interpreter, input_details, output_details = load_model(
    model_path="models/baseline_model.tflite")


load_dotenv()

FLASK_SECRET_KEY = os.getenv('FLASK_SECRET_KEY')


app = Flask(__name__)

app.config['SECRET_KEY'] = FLASK_SECRET_KEY

socketio = SocketIO(app, async_mode="eventlet")


def predict(input):

    interpreter.set_tensor(input_details[0]['index'], input.reshape(
        1, 256, 3).astype(np.float32))

    interpreter.invoke()

    output_data = interpreter.get_tensor(output_details[0]['index'])
    return output_data


@socketio.on('connect')
def on_connect():

    # emit('my response', {'data': 'Connected'})
    print("client connected.")


@socketio.on('sensor update')
def calculate_gait(json_raw):

    data = json.loads(json_raw)
    df = pd.json_normalize(data)

    model_input = df.to_numpy()

    prediction = predict(model_input)[0, 0]

    optimal_threshold = 0.251

    if prediction >= optimal_threshold:
        emit('FoG Detection', 1)
    else:
        emit('FoG Detection', 0)


if __name__ == '__main__':

    socketio.run(app, host="0.0.0.0", port="3000")
    print(request.host_url)
