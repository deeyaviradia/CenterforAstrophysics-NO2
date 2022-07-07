import h5py
import numpy as np
import sys
import os
import json

st = {
    "state": "Madhya Pradesh",
    "city": "Mandideep",
    "station": "Sector-D Industrial Area, Mandideep - MPPCB",
    "station_id": "site_1403",
    "lat": "23.108440",
    "long": "77.511428",
    "name": "Sector-D Industrial Area, Mandideep - MPPCB"
}


def json_from_file(fnm):
    r = None
    with open(fnm) as json_file:
        r = json.load(json_file)
    return r


def get_coordinates(lat, long, dimensions):
    # https://hdfeos.org/examples/matlab5.php

    # The geographic projection, which is used by OMI Column Amount O3 grid, maps meridians to equally spaced vertical
    # straight lines, and circles of latitude to evenly spread horizontal straight lines [1] . This implies that we can
    # precisely interpolate all longitude and latitude values if we know the followings:
    #
    # leftX, rightX: the range of longitude
    # numX: the number of points in X dimension
    # offsetX: offset related to Pixel Registration
    # upperY, lowerY: the range of latitude
    # numY: the number of points in Y dimension
    # offsetY: offset related to Pixel Registration

    # data_dims(2) (1440) and data_dims(1) (720) are the values for numX and numY, respectively. Also, -180 and -90
    # represents coordinates of upper left corner (UpperLeftPointMtrs) and lower right corner (LowerRightMtrs)
    # respectively in DMS format [3].

    offset_y = 0.5
    offset_x = 0.5
    scale_x = 360 / dimensions[0]
    scale_y = 180 / dimensions[1]

    x = ((float(long) + 180) / scale_x) - offset_x
    y = ((float(lat) + 90) / scale_y) - offset_y
    return round(x), round(y)


def map_site_latlong_to_OMI_xy(fnm, dim):
    st_list = json_from_file(fnm)
    _ = []
    for st in st_list:
        st["OMI_x"], st["OMI_y"] = get_coordinates(st["lat"], st["long"], dim)
        _.append(st)
    with open(fnm.replace(".json", "_OMIxy.json"), "w") as f:
        f.write(json.dumps(_))


##################################################################################################################
# https://hdfeos.org/software/h5py.php
# https://github.com/gkuhl/omi/blob/master/omi/he5.py
# https://appliedsciences.nasa.gov/sites/default/files/2020-11/HighResAQ_Part3a.pdf

with h5py.File("data/OMI-Aura_L3-OMNO2d_2021m1101_v003-2021m1220t132902.he5") as f:
    DATAFIELD_NAME = "HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2"

DIMENSIONS = "HDFEOS/GRIDS/ColumnAmountNO2"
LAT = "HDFEOS/GRIDS/ColumnAmountNO2/lat"
LONG = "HDFEOS/GRIDS/ColumnAmountNO2/lon"

# List available datasets.
print(f.keys())
# Get the dimensions
dim = (f[DIMENSIONS].attrs["NumberOfLongitudesInGrid"][0],
       f[DIMENSIONS].attrs["NumberOfLatitudesInGrid"][0])

# Read dataset.
dset = f[DATAFIELD_NAME]
data = dset[:]

# Handle fill value.
data[data == dset.fillvalue] = np.nan
data = np.ma.masked_where(np.isnan(data), data)

# Get the attributes of the node
# list(dset.attrs.keys())

# Get attributes needed for the plot.
# String attributes actually come in as the bytes type and should
# be decoded to UTF-8 (python3).
# title = dset.attrs['Title'].decode()
# units = dset.attrs['Units'].decode()
# print(title)
# print(units)

x, y = get_coordinates(st["lat"], st["long"], dim)
print(data[y][x])

map_site_latlong_to_OMI_xy("data/Indian_station_list.json", dim)
# https://hdfeos.org/examples/matlab5.php
