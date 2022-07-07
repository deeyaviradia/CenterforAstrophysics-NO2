import h5py
import numpy as np
import pandas as pd
import sys
import os
import json
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.dates as dates


def json_from_file(fnm):
    r = None
    with open(fnm) as json_file:
        r = json.load(json_file)
    return r


def get_data_coverage_percentage(data):
    df = pd.DataFrame(data["NO2"])
    percent_missing = df.isnull().sum() * 100 / len(df)
    return 100 - percent_missing[0]


def get_sites_with_fill_percentage_dict(data):
    ret = []
    for site_id, site_data in data.items():
        ret.append([site_id, get_data_coverage_percentage(site_data)])
    return ret


def get_sites_with_fill_percentage(data, percentage):
    d = get_sites_with_fill_percentage_dict(data)
    sites_with_coverage = filter(lambda x: x[1] >= percentage, d)
    return list(sites_with_coverage)


def save_json_to_file(fnm, json_data):
    with open(fnm, "w") as json_file:
        json_file.write(json.dumps(json_data))


def agg_it(site_list, json_data):
    s = {}
    for site in site_list:
        s[site] = agg_json(json_data[site])
    return s


def agg_json(json_data):
    df = pd.DataFrame({"date": json_data["date"],
                       "NO2": json_data["NO2"],
                       "OMI_NO2": json_data["OMI_NO2"]
                       })
    df.dropna(inplace=True)

    df['date'] = pd.to_datetime(df['date'])  # converting string into date value
    df['NO2'] = pd.to_numeric(df['NO2'])  # converting string into float value
    df['OMI_NO2'] = pd.to_numeric(df['OMI_NO2']) / 10 ** 29  # converting string into float value
    df = df[df['OMI_NO2'] > -10]  # filtering out filler values for OMI NO2
    df.sort_values(by=["date"], inplace=True)
    df["year"] = df['date'].dt.strftime('%Y')
    df["month"] = df['date'].dt.strftime('%Y-%m')
    df["week"] = df['date'].dt.strftime('%Y-%U')
    df["quarter"] = df['date'].dt.to_period('Q').dt.strftime('%Y-Q%q')

    json_data["data_coverage"] = get_data_coverage_percentage(json_data)
    json_data["agg_year"] = agg_on(df, "year")
    json_data["agg_quarter"] = agg_on(df, "quarter")
    json_data["agg_month"] = agg_on(df, "month")
    json_data["agg_week"] = agg_on(df, "week")
    return json_data


def agg_on(_df, agg_type):
    _df_agg = _df.groupby([agg_type]).agg(
        NO2=pd.NamedAgg(column="NO2", aggfunc="mean"),
        OMI_NO2=pd.NamedAgg(column="OMI_NO2", aggfunc="mean"))

    # j_df = pd.DataFrame(json.loads(j_str))
    return _df_agg.to_dict()


########################################################################################################################
OMI_DATA_FOLDER = "data/OMI"
GROUND_siteS = "data/Indian_site_list_OMIxy.json"
DATA_FIELD_NAME = "HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2"
site_FOLDER = "data/cpcb"
PROCESSED_DATA = "data/processed_data-17-22.json"
AGGREGATE_DATA = "data/processed_data_agg-17-22.json"

json_data = json_from_file(PROCESSED_DATA)
k = json_data.keys()
print(list(k))

# agg 1 site
j = agg_it(['site_288', 'site_5102'], json_data)
save_json_to_file(AGGREGATE_DATA.replace(".json", "-288-5102.json"), j)

# agg all sites
# site_dict = agg_it(list(json_data.keys()), json_data)
# save_json_to_file(AGGREGATE_DATA, site_dict)
