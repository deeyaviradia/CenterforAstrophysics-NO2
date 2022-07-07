import h5py
import numpy as np
import sys
import os
import json
from datetime import datetime, date
from tqdm import tqdm


def progress(count, total, status='', info=""):
    bar_len = 100
    filled_len = int(round(bar_len * count / float(total)))

    percents = round(100.0 * count / float(total), 1)
    bar = 'O' * filled_len + '.' * (bar_len - filled_len)

    _ = "{0} [{1}] {2}%".format(info, bar, percents)
    print(_, end='\r')


def json_from_file(fnm):
    r = None
    with open(fnm) as json_file:
        r = json.load(json_file)
    return r


def load_ground_stations(fnm):
    return json_from_file(fnm)


def load_omi_data(fnm, data_field):
    with h5py.File(fnm) as f:
        # Read dataset.
        dset = f[data_field]
        data = dset[:]
        # Handle fill value.
        data[data == dset.fillvalue] = np.nan
        data = np.ma.masked_where(np.isnan(data), data)
        return data


def read_station_data(station_id, date, type=["NO2"], time="13:00"):
    try:
        r = {}
        fnm = "{0}/{1}/{2}.json".format(STATION_FOLDER, station_id, date)
        station_data = json_from_file(fnm)
        for d in station_data["data"]["tabularData"]["bodyContent"]:
            if d["from date"][-5:] == time:
                for t in type:
                    r[t] = d[t]
                break
        return r
    except Exception as ex:
        return None


########################################################################################################################
OMI_DATA_FOLDER = "data/OMI"
GROUND_STATIONS = "data/Indian_station_list_OMIxy.json"
DATA_FIELD_NAME = "HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2"
STATION_FOLDER = "data/cpcb"
PROCESSED_DATA = "data/processed_data-17-22.json"

ground_stations = load_ground_stations(GROUND_STATIONS)
ground_measure_item = ["NO2"]
ground_measure_time = "13:00"

stations_data = {}
fnm = None
omi_file_count = len(os.listdir(OMI_DATA_FOLDER))
current_count = 0

for file in os.listdir(OMI_DATA_FOLDER):
    if file.endswith(".he5"):
        fnm = os.path.join(OMI_DATA_FOLDER, file)
        omi_data = load_omi_data(fnm, DATA_FIELD_NAME)  # NO2
        # OMI-Aura_ L3-OMNO2d_ 2021m0311_ v003-2021m0421t134756.he5
        fnm_list = fnm.split("_")
        yr, mm, dd = fnm_list[2][:4], fnm_list[2][5:7], fnm_list[2][7:9]
        omi_time = fnm_list[3][-10:][:6]

        for station in ground_stations:
            if station["station_id"] not in stations_data:
                stations_data[station["station_id"]] = station.copy()

            st = stations_data[station["station_id"]]
            ground_data = read_station_data(station["station_id"],
                                            "{0}-{1}-{2}".format(dd, mm, yr),
                                            ground_measure_item,
                                            ground_measure_time)
            if "date" in st:
                st["date"].append("{0}/{1}/{2}".format(yr, mm, dd))
                st["OMI_NO2"].append(str(omi_data[station["OMI_y"]][station["OMI_x"]]))
                # st["time"].append(omi_time)
                for item in ground_measure_item:
                    if ground_data:
                        st[item].append(ground_data[item])
                    else:
                        st[item].append(None)
            else:
                st["date"] = ["{0}/{1}/{2}".format(yr, mm, dd)]
                st["OMI_NO2"] = [str(omi_data[station["OMI_y"]][station["OMI_x"]])]
                # st["time"] = [omi_time]
                for item in ground_measure_item:
                    if ground_data:
                        st[item] = [ground_data[item]]
                    else:
                        st[item] = [None]
        # stations_data[st["station_id"]] = st
        current_count += 1
        progress(current_count, omi_file_count, "", "{0}/{1}/{2}".format(mm, dd, yr))
        # if current_count > 10:
        #     break

if stations_data:
    with open(PROCESSED_DATA, "w") as json_file:
        json_file.write(json.dumps(stations_data))
