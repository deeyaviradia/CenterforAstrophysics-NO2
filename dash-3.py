import dash
import pandas
from dash import dcc, html, Input, Output, callback_context as ctx
import plotly
import plotly.express as px
import plotly.graph_objects as go
import statsmodels.api as sm
from plotly.subplots import make_subplots
import pandas as pd
import json
import numpy as np
import datetime
import math

app = dash.Dash(__name__)


def derive_row(v):
    v += 1
    r = v / 2
    r = r
    if r < 0:
        r = 0
    else:
        r += 0.1
    return round(r)


def derive_column(v):
    if (v + 1) % 2 == 0:
        return 2
    return 1


def json_from_file(fnm):
    r = None
    with open(fnm) as json_file:
        r = json.load(json_file)
    return r


def load_json_stations_into_df(fnm):
    _df = pd.read_json(fnm, orient="index")
    return _df


def get_graph(df_source):
    _fig = go.Figure(data=go.Scattergeo(
        # locationmode='country names',
        lon=df_source['long'],
        lat=df_source['lat'],
        text=df_source['name'],
        # locations=df_source['station_id'],
        mode='markers',
        marker=dict(
            size=2,
            opacity=0.8,
            reversescale=True,
            autocolorscale=False,
            symbol='square',
            line=dict(
                width=1,
                color='rgba(102, 102, 102)'
            ),
            colorscale='Blues',
            cmin=0,
            cmax=df_source['state'].count(),
            colorbar_title="Ground Stations"
        )), layout=map_layout)

    _fig.update_layout(
        title='Ground based Indian pollution measuring stations',
        geo=dict(
            scope='asia',
            projection_scale=2.5,  # Zoom factor
            center={"lat": 20.5937, "lon": 78.9629},  # center lat/lon for India
            showland=True,
            landcolor="rgb(250, 250, 250)",
            subunitcolor="rgb(217, 217, 217)",
            countrycolor="rgb(217, 217, 217)",
            countrywidth=0.5,
            subunitwidth=0.5
        ),

    )
    return _fig


def get_graph_new(df_source, lat, lon, zoom=3.25):
    px.set_mapbox_access_token(
        "pk.eyJ1IjoiYWp2aXJhZGlhIiwiYSI6ImNsNGE4ZmFpaDE5eDMzZGxyZzN6aWt4a2YifQ.ZTBqHQnspJ6UJoH_OO16Pw")
    df_source.sort_values(by=["state", "city", 'station_id'], inplace=True)
    _fig = px.scatter_mapbox(df_source, lat="lat", lon="long",  # color="peak_hour", size=2,
                             size=[3 for _ in df_source["index"]],
                             size_max=9,
                             text="station_id",
                             labels="station_id",
                             color="station_id",
                             animation_group="state",
                             title="Ground based Indian pollution measuring stations",
                             # center={"lat": 23.10844, "lon": 78.9629},
                             center={"lat": lat, "lon": lon},
                             mapbox_style="basic",  # "open-street-map",
                             width=1000,
                             height=600,
                             zoom=zoom)

    return _fig


def get_scatter_graph(site_id, agg_type):
    _j = df.query("station_id == @site_id")[agg_type].to_dict()
    _df = pd.DataFrame(list(_j.values())[0])
    _df.reset_index(inplace=True)
    g = px.scatter(_df,
                   x="index",
                   y="NO2",
                   height=600)
    return g


def get_scatter_graph(d: pd.DataFrame, agg_type):
    _df = None
    site_lst = list(d["station_id"])
    for site_id in site_lst:
        _site_df = d.query("station_id == @site_id")
        _j = _site_df[agg_type].to_dict()
        temp_df = pd.DataFrame(list(_j.values())[0])
        temp_df.reset_index(inplace=True)
        temp_df["site_id"] = site_id
        temp_df["state"] = _site_df["state"].values[0]
        temp_df["city"] = _site_df["city"].values[0]
        temp_df["name"] = _site_df["station"].values[0]
        temp_df["data_coverage"] = _site_df["data_coverage"].values[0]

        if isinstance(_df, pd.DataFrame):
            _df = pd.concat([_df, temp_df])
        else:
            _df = temp_df.copy(deep=True)

    g = px.scatter(_df,
                   x="index",
                   y="OMI_NO2",
                   color="state",
                   hover_name="site_id",
                   hover_data=_df.columns,
                   facet_col="site_id",
                   facet_col_wrap=4,
                   # trendline='ols',
                   # trendline_color_override='darkblue',
                   size_max=75,
                   height=1000,
                   labels={"index": agg_type})
    return g


def map_agg_to_date(d, agg_type):
    if agg_type == "agg_week":
        return datetime.datetime.strptime(d + '-1', "%Y-%W-%w")
    if agg_type == "agg_quarter":
        year = d[:4]
        qtr = d[-1:]
        return "{0}-{1:02d}-01".format(year, (int(qtr) - 1) * 3 + 1)
    if agg_type == "agg_month":
        return "{0}-01".format(d)


def get_all_sites_graph_ver1(d: pd.DataFrame, agg_type, chart_type, poly_degree):
    no_of_sites = 1
    _df = None
    _d = []

    site_lst = list(d["station_id"])

    _site_df = d.query("station_id == @site_lst")
    _j = _site_df[agg_type].to_dict()
    __df = None
    for idx in range(0, len(site_lst)):
        __temp_df = pd.DataFrame(_site_df[agg_type].values[idx])
        __temp_df["site_id"] = site_lst[idx]
        # __temp_df.reset_index(inplace=True)
        if __df is None:
            __df = __temp_df.copy(deep=True)
        else:
            __df = pd.concat([__df, __temp_df])

    __df.reset_index(inplace=True)
    __df = __df.rename(columns={'index': 'dates'})

    site_df = __df

    _fig = px.scatter(site_df,
                      x="OMI_NO2",
                      y="NO2",
                      color="site_id",
                      height=900)

    try:
        if "All Selected Sites - Ground NO2 Vs OMI NO2" in chart_type:
            site_df.sort_values(by=['dates'], inplace=True)
            if not poly_degree:
                poly_degree = "1"
            site_df["smooth"] = np.polyval(
                np.polyfit(site_df["OMI_NO2"], site_df["NO2"], int(poly_degree)),
                site_df["OMI_NO2"])

            model = sm.OLS(site_df["NO2"], sm.add_constant(site_df["OMI_NO2"])).fit()
            # p = model.get_prediction()

            trace = go.Scatter(x=site_df["OMI_NO2"], y=model.predict(),
                               line={"width": 1, "color": "Blue"}, name="OLS")
            results = model.summary()
            r_sqd = model.rsquared
            m = float(results.tables[1].data[2][1])
            c = float(results.tables[1].data[1][1])

            _fig.add_trace(trace, row=1, col=1)

            _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=1, col=1)
            x_text = "OMI NO2 (molecules/cm<sup>2</sup>)<BR>y=({0:.3e})x+({1})<BR>R-Squared : {2:.4f}".format(m,
                                                                                                              c,
                                                                                                              r_sqd)
            _fig.update_xaxes(title_text=x_text, row=1, col=1)

    except Exception as ex:
        print(ex)

    _fig.update_layout(height=100 + (no_of_sites * 250),
                       width=1600,
                       showlegend=True)

    return _fig


def get_all_sites_graph(d: pd.DataFrame, agg_type, chart_type, poly_degree, r_sqr):
    no_of_sites = 1
    _df = None
    _d = []

    r_squared_threshold = 0
    if r_sqr:
        r_squared_threshold = int(r_sqr) / 100

    site_lst = list(d["station_id"])

    _site_df = d.query("station_id == @site_lst")
    _j = _site_df[agg_type].to_dict()
    __df = None
    for idx in range(0, len(site_lst)):
        __temp_df = pd.DataFrame(_site_df[agg_type].values[idx])
        __temp_df["site_id"] = site_lst[idx]
        # __temp_df.reset_index(inplace=True)

        r_sqr = 0
        try:
            model = sm.OLS(__temp_df["NO2"], sm.add_constant(__temp_df["OMI_NO2"])).fit()
            r_sqr = model.rsquared
        except Exception as ex:
            pass

        __temp_df["r_sqr"] = r_sqr
        if r_sqr >= r_squared_threshold:
            if __df is None:
                __df = __temp_df.copy(deep=True)
            else:
                __df = pd.concat([__df, __temp_df])

    __temp_data = {
        "OMI_NO2": [0.0],
        "NO2": [0.0],
        "site_id": [""]
    }
    __temp_data_pd = pandas.DataFrame(__temp_data)
    _fig = px.scatter(__temp_data_pd, x="OMI_NO2",
                      y="NO2", color="site_id", height=900)

    try:
        __df.reset_index(inplace=True)
        __df = __df.rename(columns={'index': 'dates'})

        site_df = __df

        _fig = px.scatter(site_df,
                          x="OMI_NO2",
                          y="NO2",
                          color="site_id",
                          height=900)

        if "All Selected Sites - Ground NO2 Vs OMI NO2" in chart_type:
            site_df.sort_values(by=['site_id', 'dates'], inplace=True)
            if not poly_degree:
                poly_degree = "1"
            site_df["smooth"] = np.polyval(
                np.polyfit(site_df["OMI_NO2"], site_df["NO2"], int(poly_degree)),
                site_df["OMI_NO2"])

            model = sm.OLS(site_df["NO2"], sm.add_constant(site_df["OMI_NO2"])).fit()
            # p = model.get_prediction()

            trace = go.Scatter(x=site_df["OMI_NO2"], y=model.predict(),
                               line={"width": 1, "color": "Blue"}, name="OLS")
            results = model.summary()
            r_sqd = model.rsquared
            m = float(results.tables[1].data[2][1])
            c = float(results.tables[1].data[1][1])

            _fig.add_trace(trace, row=1, col=1)

            _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=1, col=1)
            x_text = "OMI NO2 (molecules/cm<sup>2</sup>)<BR>y=({0:.3e})x+({1})<BR>R-Squared : {2:.4f}".format(m,
                                                                                                              c,
                                                                                                              r_sqd)
            _fig.update_xaxes(title_text=x_text, row=1, col=1)

    except Exception as ex:
        print(ex)

    _fig.update_layout(height=100 + (no_of_sites * 250),
                       width=1600,
                       showlegend=True)

    return _fig


def get_r_squared_data(d: pd.DataFrame, agg_type, chart_type, poly_degree, r_sqr):
    d.sort_values(by=["state", "city", "station_id"], inplace=True)
    _df = None
    _d = []

    r_squared_sites = []
    r_squared_threshold = 0
    if r_sqr:
        r_squared_threshold = int(r_sqr) / 100
    site_lst = list(d["station_id"])
    no_of_sites = len(site_lst)
    for idx in range(0, no_of_sites):
        site_df = _d[idx]


def get_scatter_graph_manually_old(d: pd.DataFrame, agg_type, chart_type, poly_degree, r_sqr):
    d.sort_values(by=["state", "city", "station_id"], inplace=True)
    _df = None
    _d = []

    r_squared_sites = []
    r_squared_threshold = 0
    if r_sqr:
        r_squared_threshold = int(r_sqr) / 100

    site_lst = list(d["station_id"])
    no_of_sites = len(site_lst)
    if "All Selected Sites - Ground NO2 Vs OMI NO2" in chart_type:
        return get_all_sites_graph(d, agg_type, chart_type, poly_degree, r_sqr)

    sub_chart_titles = []
    for site_id in site_lst:
        _site_df = d.query("station_id == @site_id")
        _j = _site_df[agg_type].to_dict()
        temp_df = pd.DataFrame(list(_j.values())[0])
        temp_df.reset_index(inplace=True)
        temp_df["site_id"] = site_id
        temp_df["name"] = _site_df["name"].values[0]
        temp_df["state"] = _site_df["state"].values[0]
        temp_df["city"] = _site_df["city"].values[0]
        temp_df["name"] = _site_df["station"].values[0]
        temp_df["data_coverage"] = _site_df["data_coverage"].values[0]

        model = sm.OLS(temp_df["NO2"], sm.add_constant(temp_df["OMI_NO2"])).fit()
        temp_df["r_sqr"] = model.rsquared

        if len(temp_df["data_coverage"]) > 0:
            temp_df['date'] = temp_df.apply(lambda x: map_agg_to_date(x["index"], agg_type), axis=1)
        else:
            temp_df['date'] = temp_df["data_coverage"]

        if __df is None:
            if model.rsquared >= r_squared_threshold:
                __df = temp_df.copy(deep=True)
        else:
            if model.rsquared >= r_squared_threshold:
                __df = pd.concat([__df, temp_df])

        sub_chart_titles.append(
            "<BR><B>{0}</B><BR>{3}<BR>{2} - {1}".format(site_id,
                                                        _site_df["state"].values[0],
                                                        _site_df["city"].values[0],
                                                        _site_df["name"].values[0]))

        _d.append(temp_df)

        if isinstance(_df, pd.DataFrame):
            _df = pd.concat([_df, temp_df])
        else:
            _df = temp_df.copy(deep=True)

    row_spec = [{"secondary_y": True}, {"secondary_y": True}]
    sub_plots_spec = [row_spec for i in range(0, math.ceil(no_of_sites / 2.0))]

    _fig = make_subplots(rows=math.ceil(no_of_sites / 2.0), cols=2,
                         subplot_titles=tuple(sub_chart_titles),
                         specs=sub_plots_spec)

    cols = plotly.colors.DEFAULT_PLOTLY_COLORS
    for idx in range(0, no_of_sites):
        site_df = _d[idx]

        row = derive_row(idx)
        col = derive_column(idx)
        if len(site_df["date"]) > 0:
            try:
                if "OMI NO2 Vs Time" in chart_type:
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["OMI_NO2"], name="{0} OMI_NO2".format(site_lst[idx]),
                                   # line={"width": 1, "color": cols[2]}),
                                   line={"width": 1}),
                        row=row, col=col,
                        secondary_y=False)
                    _fig.update_xaxes(title_text="Time", row=row, col=col)
                    _fig.update_yaxes(title_text="OMI NO2 (molecules/cm<sup>2</sup>)", row=row, col=col,
                                      secondary_y=False)

                if "(Ground NO2 + OMI NO2) Vs Time" in chart_type:
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["NO2"], name="{0} NO2".format(site_lst[idx]),
                                   line={"width": 1, "color": cols[1]}),
                        # line={"width": 1}),
                        row=row, col=col,
                        secondary_y=False)
                    _fig.update_yaxes(title_text="NO2", row=row, col=col, secondary_y=False)
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["OMI_NO2"], name="{0} OMI_NO2".format(site_lst[idx]),
                                   line={"width": 1, "color": cols[2]}),
                        row=row, col=col,
                        secondary_y=True)
                    _fig.update_xaxes(title_text="Time", row=row, col=col)
                    _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=row, col=col,
                                      secondary_y=False)
                    _fig.update_yaxes(title_text="OMI_NO2 (molecules/cm<sup>2</sup>)", row=row, col=col,
                                      secondary_y=True)

                if "Ground NO2 Vs OMI NO2" in chart_type:
                    site_df.sort_values(by=['OMI_NO2', 'NO2'], inplace=True)
                    if not poly_degree:
                        poly_degree = "1"
                    site_df["smooth"] = np.polyval(
                        np.polyfit(site_df["OMI_NO2"], site_df["NO2"], int(poly_degree)),
                        site_df["OMI_NO2"])

                    model = sm.OLS(site_df["NO2"], sm.add_constant(site_df["OMI_NO2"])).fit()
                    p = model.get_prediction()

                    trace = go.Scatter(x=site_df["OMI_NO2"], y=model.predict(),
                                       line={"width": 1, "color": cols[4]}, name="OLS")
                    results = model.summary()
                    r_sqd = model.rsquared
                    m = float(results.tables[1].data[2][1])
                    c = float(results.tables[1].data[1][1])

                    if r_sqd >= r_squared_threshold:
                        r_squared_sites.append((site_lst[idx], r_sqd))

                    _fig.add_trace(
                        go.Scatter(x=site_df["OMI_NO2"], y=site_df["NO2"], name="{0} NO2".format(site_lst[idx]),
                                   # line={"width": 1, "color": cols[1]},
                                   line={"width": 1},
                                   mode="markers",
                                   ),
                        row=row, col=col,
                        secondary_y=False)

                    _fig.add_trace(trace, row=row, col=col)

                    _fig.add_trace(go.Scatter(x=site_df["OMI_NO2"], y=site_df["smooth"], name="Smooth",
                                              line=dict(color="Black")),
                                   row=row, col=col,
                                   secondary_y=False)

                    _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=row, col=col)
                    x_text = "OMI NO2 (molecules/cm<sup>2</sup>)<BR>y=({0:.3e})x+({1})<BR>R-Squared : {2:.4f}".format(m,
                                                                                                                      c,
                                                                                                                      r_sqd)
                    _fig.update_xaxes(title_text=x_text, row=row, col=col)

            except Exception as ex:
                print(ex)

    print("r_squared_sites: {0}".format(r_squared_sites))

    _fig.update_layout(height=100 + (no_of_sites * 250),
                       width=1600,
                       showlegend=True)
    return _fig


def get_scatter_graph_manually(d: pd.DataFrame, agg_type, chart_type, poly_degree, r_sqr):
    d.sort_values(by=["state", "city", "station_id"], inplace=True)
    _df = None
    _d = []

    r_squared_sites = []
    r_squared_threshold = 0
    if r_sqr:
        r_squared_threshold = int(r_sqr) / 100

    site_lst = list(d["station_id"])
    no_of_sites = len(site_lst)
    if "All Selected Sites - Ground NO2 Vs OMI NO2" in chart_type:
        return get_all_sites_graph(d, agg_type, chart_type, poly_degree, r_sqr)

    sub_chart_titles = []
    for site_id in site_lst:
        _site_df = d.query("station_id == @site_id")
        _j = _site_df[agg_type].to_dict()
        temp_df = pd.DataFrame(list(_j.values())[0])
        temp_df.reset_index(inplace=True)
        temp_df["site_id"] = site_id
        temp_df["name"] = _site_df["name"].values[0]
        temp_df["state"] = _site_df["state"].values[0]
        temp_df["city"] = _site_df["city"].values[0]
        temp_df["name"] = _site_df["station"].values[0]
        temp_df["data_coverage"] = _site_df["data_coverage"].values[0]

        # model = sm.OLS(temp_df["NO2"], sm.add_constant(temp_df["OMI_NO2"])).fit()
        # temp_df["r_sqr"] = model.rsquared

        r_sqr = 0
        try:
            model = sm.OLS(temp_df["NO2"], sm.add_constant(temp_df["OMI_NO2"])).fit()
            r_sqr = model.rsquared
        except Exception as ex:
            pass

        temp_df["r_sqr"] = r_sqr

        if len(temp_df["data_coverage"]) > 0:
            temp_df['date'] = temp_df.apply(lambda x: map_agg_to_date(x["index"], agg_type), axis=1)
        else:
            temp_df['date'] = temp_df["data_coverage"]

        if r_sqr >= r_squared_threshold:
            _d.append(temp_df)
            if isinstance(_df, pd.DataFrame):
                _df = pd.concat([_df, temp_df])
            else:
                _df = temp_df.copy(deep=True)

            sub_chart_titles.append(
                "<BR><B>{0}</B><BR>{3}<BR>{2} - {1}".format(site_id,
                                                            _site_df["state"].values[0],
                                                            _site_df["city"].values[0],
                                                            _site_df["name"].values[0]))

    site_lst = []
    no_of_sites = 0
    if _df is not None:
        site_lst = list(sorted(_df["site_id"].unique()))
        no_of_sites = len(site_lst)

    row_spec = [{"secondary_y": True}, {"secondary_y": True}]
    sub_plots_spec = [row_spec for i in range(0, math.ceil(no_of_sites / 2.0))]

    if no_of_sites > 0:
        _fig = make_subplots(rows=math.ceil(no_of_sites / 2.0), cols=2,
                             subplot_titles=tuple(sub_chart_titles),
                             specs=sub_plots_spec)
    else:
        _fig = make_subplots(rows=1, cols=2)

    cols = plotly.colors.DEFAULT_PLOTLY_COLORS
    for idx in range(0, no_of_sites):
        site_df = _d[idx]

        row = derive_row(idx)
        col = derive_column(idx)
        if len(site_df["date"]) > 0:
            try:
                if "OMI NO2 Vs Time" in chart_type:
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["OMI_NO2"], name="{0} OMI_NO2".format(site_lst[idx]),
                                   # line={"width": 1, "color": cols[2]}),
                                   line={"width": 1}),
                        row=row, col=col,
                        secondary_y=False)
                    _fig.update_xaxes(title_text="Time", row=row, col=col)
                    _fig.update_yaxes(title_text="OMI NO2 (molecules/cm<sup>2</sup>)", row=row, col=col,
                                      secondary_y=False)

                if "(Ground NO2 + OMI NO2) Vs Time" in chart_type:
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["NO2"], name="{0} NO2".format(site_lst[idx]),
                                   line={"width": 1, "color": cols[1]}),
                        # line={"width": 1}),
                        row=row, col=col,
                        secondary_y=False)
                    _fig.update_yaxes(title_text="NO2", row=row, col=col, secondary_y=False)
                    _fig.add_trace(
                        go.Scatter(x=site_df["date"], y=site_df["OMI_NO2"], name="{0} OMI_NO2".format(site_lst[idx]),
                                   line={"width": 1, "color": cols[2]}),
                        row=row, col=col,
                        secondary_y=True)
                    _fig.update_xaxes(title_text="Time", row=row, col=col)
                    _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=row, col=col,
                                      secondary_y=False)
                    _fig.update_yaxes(title_text="OMI_NO2 (molecules/cm<sup>2</sup>)", row=row, col=col,
                                      secondary_y=True)

                if "Ground NO2 Vs OMI NO2" in chart_type:
                    site_df.sort_values(by=['OMI_NO2', 'NO2'], inplace=True)
                    if not poly_degree:
                        poly_degree = "1"
                    site_df["smooth"] = np.polyval(
                        np.polyfit(site_df["OMI_NO2"], site_df["NO2"], int(poly_degree)),
                        site_df["OMI_NO2"])

                    model = sm.OLS(site_df["NO2"], sm.add_constant(site_df["OMI_NO2"])).fit()
                    p = model.get_prediction()

                    trace = go.Scatter(x=site_df["OMI_NO2"], y=model.predict(),
                                       line={"width": 1, "color": cols[4]}, name="OLS")
                    results = model.summary()
                    r_sqd = model.rsquared
                    m = float(results.tables[1].data[2][1])
                    c = float(results.tables[1].data[1][1])

                    if r_sqd >= r_squared_threshold:
                        r_squared_sites.append((site_lst[idx], r_sqd))

                    _fig.add_trace(
                        go.Scatter(x=site_df["OMI_NO2"], y=site_df["NO2"], name="{0} NO2".format(site_lst[idx]),
                                   # line={"width": 1, "color": cols[1]},
                                   line={"width": 1},
                                   mode="markers",
                                   ),
                        row=row, col=col,
                        secondary_y=False)

                    _fig.add_trace(trace, row=row, col=col)

                    _fig.add_trace(go.Scatter(x=site_df["OMI_NO2"], y=site_df["smooth"], name="Smooth",
                                              line=dict(color="Black")),
                                   row=row, col=col,
                                   secondary_y=False)

                    _fig.update_yaxes(title_text="Ground NO2 (µg/m<sup>3</sup>)", row=row, col=col)
                    x_text = "OMI NO2 (molecules/cm<sup>2</sup>)<BR>y=({0:.3e})x+({1})<BR>R-Squared : {2:.4f}".format(m,
                                                                                                                      c,
                                                                                                                      r_sqd)
                    _fig.update_xaxes(title_text=x_text, row=row, col=col)

            except Exception as ex:
                print(ex)

    print("r_squared_sites: {0}".format(r_squared_sites))

    _fig.update_layout(height=100 + (no_of_sites * 250),
                       width=1600,
                       showlegend=True)
    return _fig


@app.callback(
    Output("graph2", "figure"),
    [Input('graph1', 'selectedData'),
     Input('agg_dd', 'value'),
     Input('state_dd', 'value'),
     Input('chart_dd', 'value'),
     Input('poly_dd', 'value'),
     Input('R_sqr_dd', 'value')])
def show_selected(select_data, agg_type, state_value, chart_type, poly_degree, r_sqr):
    d = df
    if select_data:
        selected_stations = [x['text'] for x in select_data['points']]
        d = df.query("station_id in @selected_stations")

    if state_value:
        d = d.query("state in @state_value")

    if agg_type and (state_value or select_data) and chart_type:
        return get_scatter_graph_manually(d, agg_type, chart_type, poly_degree, r_sqr)

    return px.bar(d, x="state", barmode="group", color="state", text_auto='.2s', hover_name="state", height=300)


@app.callback(
    Output("graph1", "figure"),
    [Input('state_dd', 'value'),
     Input('graph2', 'clickData'),
     Input('graph2', 'figure')])
def state_based_figure(state_value, graph2_selected_value, graph2_figure):
    lat = 23.10844
    lon = 78.9629
    zoom = 3.25
    _id = ctx.triggered if not None else 'No clicks yet'
    if _id is not None:
        if "graph2" in _id[0]['prop_id']:
            try:
                idx = graph2_selected_value["points"][0]["curveNumber"]
                site_name = graph2_figure['data'][idx]['name']
                site_name = site_name[:-4]
                _df = df.query("station_id == @site_name")
                lat = _df["lat"].values[0]
                lon = _df["long"].values[0]
                zoom = 11
                print("idx: {0}\nname: {1}\nlat: {2}\nlon:{3}".format(idx, site_name, lat, lon))
            except Exception as ex:
                pass
    df_state = df
    if state_value:
        df_state = df.query("state == @state_value")
    return get_graph_new(df_state, lat, lon, zoom)


@app.callback(
    Output("subChartsH3", "children"),
    [Input('chart_dd', 'value')])
def update_subchart_header(chart_value):
    if chart_value:
        return chart_value
    else:
        return ""


########################################################################################################################
fnm = "data/processed_data_agg-17-22.json"
# df = load_json_stations_into_df("data/Indian_station_list.json")
# df = load_json_stations_into_df("data/processed_data_agg-17-22-288-5102.json")
df = load_json_stations_into_df(fnm)
df.reset_index(inplace=True)  # make site_ids as a column from index and have the index as sequential numbers
map_layout = {"height": 500, "width": 800}

fig = get_graph(df)

# a = get_scatter_graph("site_288", "agg_week")
states_dd_options = [dict(label=x, value=x) for x in df.sort_values(by="state")["state"].unique()]
agg_type_dd_options = [
    {"label": "Weekly", "value": "agg_week"},
    {"label": "Monthly", "value": "agg_month"},
    {"label": "Quarter", "value": "agg_quarter"},
    {"label": "Yearly", "value": "agg_year"}]
chart_type_dd_options = [
    {"label": "OMI NO2 Vs Time", "value": "OMI NO2 Vs Time"},
    {"label": "(Ground NO2 + OMI NO2) Vs Time", "value": "(Ground NO2 + OMI NO2) Vs Time"},
    {"label": "Ground NO2 Vs OMI NO2", "value": "Ground NO2 Vs OMI NO2"},
    {"label": "All Selected Sites - Ground NO2 Vs OMI NO2", "value": "All Selected Sites - Ground NO2 Vs OMI NO2"}]
poly_type_dd_options = [
    {"label": "1", "value": "1"},
    {"label": "2", "value": "2"},
    {"label": "3", "value": "3"},
    {"label": "4", "value": "4"},
    {"label": "5", "value": "5"},
    {"label": "6", "value": "6"},
    {"label": "7", "value": "7"}]
R_squared_dd_options = [
    {"label": "0", "value": "0"},
    {"label": "5", "value": "5"},
    {"label": "10", "value": "10"},
    {"label": "15", "value": "15"},
    {"label": "20", "value": "20"},
    {"label": "25", "value": "25"},
    {"label": "30", "value": "30"},
    {"label": "35", "value": "35"},
    {"label": "40", "value": "40"},
    {"label": "45", "value": "45"},
    {"label": "50", "value": "50"}]

app.layout = html.Div(id="main", children=[

    html.Div(id="header", children=[
        html.H1(children=["India - NO",
                          html.Sub("2"),
                          " Analysis"]),
    ], className="banner"),

    html.Div(id="filters", children=[
        html.Div(id="col1", children=[
            html.Br(), html.Br(), html.Br(),
            html.Br(), html.Br(),

            dcc.Dropdown(id="agg_dd", options=agg_type_dd_options,
                         multi=False,
                         placeholder='Select a aggregation...'),
            html.Br(),
            dcc.Dropdown(id="state_dd", options=states_dd_options,
                         multi=True,
                         placeholder='Select a State...'),
            html.Br(),
            dcc.Dropdown(id="chart_dd", options=chart_type_dd_options,
                         multi=False,
                         placeholder='Select a Chart Type...'),
            html.Br(),
            dcc.Dropdown(id="poly_dd", options=poly_type_dd_options,
                         multi=False,
                         placeholder='Select a degree of Polynomial...'),
            html.Br(),
            dcc.Dropdown(id="R_sqr_dd", options=R_squared_dd_options,
                         multi=False,
                         placeholder='Select R-squared filter...'),
            html.Br()
        ], className="four columns"),
        html.Div(id="col2", children=[
            dcc.Graph(
                id='graph1',
                figure=fig
            )], className="eight columns")
    ], className="row"),

    html.Div(id="temp1", children=[
        html.Div(id='subChartsH3', style={'display': 'inline'})
        # html.H3(children=[
        #     html.Div(id='subChartsH3', style={'display': 'inline'})
        # ]),
    ]),

    html.Div(children=[dcc.Graph(id="graph2", )], className="row")
])

if __name__ == '__main__':
    app.run_server(debug=True)
