"""Miscellaneous helper functions used by graph plotting code."""


import numpy as np
import matplotlib.pyplot as plt


def log_bins(data, num_bins):
    """Computes bins to use for exponentially-distributed data."""

    _min = np.min(data)
    _max = np.max(data)

    log_min = np.log(_min)
    log_max = np.log(_max)

    log_bins = np.linspace(log_min, log_max, num=num_bins)
    bins = np.exp(log_bins)
    return bins


def order_of_magnitude_bins(data, base=2, min_value=0.1):
    """Computes the smallest set of bin boundaries covering the entire data
    range while also ensuring that each bin covers exactly one order of
    magnitude.
    
    Example:
        >>> order_of_magnitude_bins([3, 87], base=10)
        np.array([1, 10, 100])
    """

    # If we're given a list of series, loop over all series
    if isinstance(data, list):
        _min = np.clip(min([np.min(series) for series in data]), min_value, None)
        _max = np.clip(max([np.max(series) for series in data]), min_value, None)

    # If not then it's just a single series
    else:
        _min = np.clip(np.min(data), min_value, None)
        _max = np.clip(np.max(data), min_value, None)

    log_smallest = np.floor(np.log(_min) / np.log(base))
    log_largest = np.ceil(np.log(_max) / np.log(base))
    log_bins = np.arange(log_smallest, log_largest + 1)

    return np.power(base, log_bins)


def format_bytes(num_bytes: int):
    """Formats a number of bytes in a human-readable format."""

    if num_bytes < 1024:
        return str(num_bytes) + " B"

    elif num_bytes < 1024 ** 2:
        return str(num_bytes / 1024) + " KB"

    elif num_bytes < 1024 ** 3:
        return str(num_bytes / 1024 ** 2) + " MB"

    else:
        return str(num_bytes / 1024 ** 3) + " GB"


def get_cumulative_histogram(series):
    """Computes the cumulative histogram of data."""
    N = series.count()
    x = series_sorted = np.sort(series)
    y = np.arange(N) / N
    return x, y
