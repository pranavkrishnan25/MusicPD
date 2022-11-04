import numpy as np
import pdkit

filename = "mpower.json"

gait_timeseries = pdkit.GaitTimeSeries().load_data(filename, format_file="mpower")

gait_processor = pdkit.GaitProcessor(duration=gait_timeseries.td[-1])
gait_features = gait_processor.gait(gait_timeseries.mag_sum_acc)

print(gait_features)
