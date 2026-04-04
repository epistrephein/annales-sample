#!/usr/bin/env python3

from pathlib import Path
import yaml
import matplotlib.pyplot as plt
import numpy as np

BASE_DIR = Path(__file__).resolve().parent
INPUT_FILE = BASE_DIR.parent / "metrics" / "metrics.yml"
OUTPUT_DIR = BASE_DIR / "png"

COLORS = {
    "primary": "tab:blue",
    "secondary": "tab:orange",
}


def load_data(path):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def ensure_output_dir(path):
    path.mkdir(parents=True, exist_ok=True)


def sorted_table_names(data):
    return sorted(data.keys())


def extract_totals(data, tables):
    return [data[table].get("total", 0) for table in tables]


def extract_yearly_series(data, tables):
    all_years = sorted(
        {int(year) for table in tables for year in data[table].get("yearly", {}).keys()}
    )

    series = {}
    for table in tables:
        yearly = {int(k): v for k, v in data[table].get("yearly", {}).items()}
        series[table] = [yearly.get(year, 0) for year in all_years]

    return all_years, series


def extract_monthly_series(data, tables, start_year=None, end_year=None):
    all_months = sorted(
        {
            (int(year), int(month))
            for table in tables
            for year, months in data[table].get("monthly", {}).items()
            for month in months.keys()
            if (start_year is None or int(year) >= start_year)
            and (end_year is None or int(year) <= end_year)
        }
    )

    labels = [f"{year}-{month:02d}" for year, month in all_months]

    series = {}
    for table in tables:
        monthly = {
            (int(year), int(month)): count
            for year, months in data[table].get("monthly", {}).items()
            for month, count in months.items()
            if (start_year is None or int(year) >= start_year)
            and (end_year is None or int(year) <= end_year)
        }
        series[table] = [monthly.get((year, month), 0) for year, month in all_months]

    return labels, series


def plot_totals(data, tables, output_path):
    values = extract_totals(data, tables)

    plt.figure(figsize=(8, 6))
    x = np.arange(len(tables))

    plt.bar(
        x,
        values,
        color=[COLORS["primary"], COLORS["secondary"]],
    )

    plt.xticks(x, tables)
    plt.ylabel("Entries")
    plt.title("Total entries per table")
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()


def plot_grouped_bars(
    labels, series, tables, title, ylabel, output_path, y_max=None, y_step=None
):
    x = np.arange(len(labels))
    width = 0.38

    fig_width = max(14, len(labels) * 0.35)
    plt.figure(figsize=(fig_width, 6))

    plt.bar(
        x - width / 2,
        series[tables[0]],
        width,
        label=tables[0],
        color=COLORS["primary"],
    )
    plt.bar(
        x + width / 2,
        series[tables[1]],
        width,
        label=tables[1],
        color=COLORS["secondary"],
    )

    plt.xticks(x, labels, rotation=45, ha="right")

    if y_max is not None:
        plt.ylim(0, y_max)
    if y_step is not None:
        plt.yticks(np.arange(0, y_max + 1, y_step))

    plt.ylabel(ylabel)
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()


def main():
    data = load_data(INPUT_FILE)
    tables = sorted_table_names(data)

    if len(tables) != 2:
        raise ValueError(
            f"Expected exactly 2 tables in YAML, found {len(tables)}: {tables}"
        )

    ensure_output_dir(OUTPUT_DIR)

    # Total chart
    plot_totals(data, tables, OUTPUT_DIR / "totals.png")

    # Yearly chart
    years, yearly_series = extract_yearly_series(data, tables)
    plot_grouped_bars(
        labels=[str(year) for year in years],
        series=yearly_series,
        tables=tables,
        title="Yearly entries per table",
        ylabel="Entries",
        output_path=OUTPUT_DIR / "yearly.png",
    )

    # Monthly chart: 2017-2021
    months_1, monthly_series_1 = extract_monthly_series(
        data, tables, start_year=2017, end_year=2021
    )
    plot_grouped_bars(
        labels=months_1,
        series=monthly_series_1,
        tables=tables,
        title="Monthly entries per table (2017-2021)",
        ylabel="Entries",
        output_path=OUTPUT_DIR / "monthly-2017-2021.png",
        y_max=4500,
        y_step=500,
    )

    # Monthly chart: 2022-2026
    months_2, monthly_series_2 = extract_monthly_series(
        data, tables, start_year=2022, end_year=2026
    )
    plot_grouped_bars(
        labels=months_2,
        series=monthly_series_2,
        tables=tables,
        title="Monthly entries per table (2022-2026)",
        ylabel="Entries",
        output_path=OUTPUT_DIR / "monthly-2022-2026.png",
        y_max=4500,
        y_step=500,
    )

    print(f"Charts written to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
