"""Helper functions for plotting data to matplotlib axes."""


import numpy as np
import matplotlib.pyplot as plt

from .util import order_of_magnitude_bins, format_bytes, get_cumulative_histogram


def plot_orders_of_magnitude_histogram(
    ax, series, series_labels, bucket_naming_func, base=2, xlim=None, normalise=True
):
    """Plots a histogram where the series is binned according to
    bins that are uniformly distributed in log space."""

    num_series = len(series)

    all_bars_width = 0.8
    per_bar_width = all_bars_width / num_series

    bins = order_of_magnitude_bins(series, base=base)
    log_bins = np.log(bins) / np.log(base)

    # Label for each bin
    # bin_labels = [format_bytes(int(bins[i])) for i in range(1, len(bins))]
    bin_labels = [
        bucket_naming_func(bins[i], bins[i + 1]) for i in range(len(bins) - 1)
    ]

    # The central positions of the bar groups
    x = np.arange(log_bins[0], log_bins[0] + len(bins) - 1)

    # Loop over each series
    for i, (s, name) in enumerate(zip(series, series_labels)):

        #  Compute the histogram for this data series
        heights, _ = np.histogram(s, bins=bins)

        # # Normalise to correct for the differences in series' lengths
        if normalise:
            heights_corrected = heights / np.sum(heights)
        else:
            heights_corrected = heights

        # Put the bar in the right place for this series
        x_shifted = x - (all_bars_width - per_bar_width) / 2 + i * per_bar_width

        # Plot the series' histogram results
        ax.bar(x_shifted, heights_corrected, per_bar_width, label=name)

    #  Set the tick labels
    ax.set_xticks(x)
    ax.set_xticklabels(bin_labels, rotation=45)
    ax.minorticks_off()

    if xlim:
        x_min, x_max = xlim
        log_x_min = np.log(x_min) / np.log(base)
        log_x_max = np.log(x_max) / np.log(base)
        ax.set_xlim((log_x_min, log_x_max))

    ax.legend()


def plot_double_cdf(ax, series1, series2, series_labels):
    """Plots the cumulative distribution functions of series1
    and series2 on the same graph."""

    series1_total, y = get_cumulative_histogram(series1)
    series2 = np.sort(series2)
    max_val = series1_total[-1]

    # Force them both to finish at exactly 100%
    series1_total = np.append(series1_total, max_val)
    series2 = np.append(series2, max_val)
    y = np.append(y, 1)

    ax.plot(series1_total, 100 * y, series2, 100 * y, label=series_labels)
