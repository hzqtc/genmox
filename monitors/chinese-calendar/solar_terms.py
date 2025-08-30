from datetime import datetime, timedelta

import ephem  # type: ignore

# 24节气的名称（按顺序）
SOLAR_TERM_NAMES = [
    "小寒",
    "大寒",
    "立春",
    "雨水",
    "惊蛰",
    "春分",
    "清明",
    "谷雨",
    "立夏",
    "小满",
    "芒种",
    "夏至",
    "小暑",
    "大暑",
    "立秋",
    "处暑",
    "白露",
    "秋分",
    "寒露",
    "霜降",
    "立冬",
    "小雪",
    "大雪",
    "冬至",
]


def angle_diff(a: float, b: float) -> float:
    d = (a - b) % 360
    return min(d, 360 - d)


def solar_longitude(date) -> float:
    sun = ephem.Sun(date)
    lon_heliocentric_deg = float(sun.hlong) * 180.0 / ephem.pi
    lon_geocentric = (lon_heliocentric_deg + 180.0) % 360.0
    return lon_geocentric


def find_solar_term(year) -> dict:
    """计算指定年份24节气并返回北京时间"""
    target_longitudes = [(i * 15 + 285) % 360 for i in range(24)]
    results_utc = {}
    start_date = datetime(year, 1, 1)
    end_date = datetime(year + 1, 1, 1)

    date = start_date
    for idx, term in enumerate(SOLAR_TERM_NAMES):
        target = target_longitudes[idx]

        # Rough search by day
        date = date.replace(hour=0, minute=0)
        step = timedelta(days=1)
        while date < end_date:
            if angle_diff(solar_longitude(date), target) < 5:
                break
            date += step

        # Refine search by hour
        date = max(date - timedelta(days=1), start_date)
        step = timedelta(hours=1)
        while date < end_date:
            if angle_diff(solar_longitude(date), target) < 0.5:
                break
            date += step

        # Finally search by minute
        step = timedelta(minutes=1)
        min_diff = 1e9
        for i in range(60):
            d = date + i * step
            diff = angle_diff(solar_longitude(d), target)
            if diff < min_diff:
                min_diff = diff
                date = d

        results_utc[term] = date

    # Convert to local time
    local_now = datetime.now().astimezone()
    offset = local_now.utcoffset()
    results_local = {}
    for term, dt_utc in results_utc.items():
        dt_local = dt_utc + offset  # type: ignore
        results_local[term] = dt_local

    return results_local


def next_solar_term() -> str:
    now = datetime.now()
    solar_terms = find_solar_term(now.year)
    for term, dt in solar_terms.items():
        if dt == now:
            return f"今天是：{term}"
        elif dt > now:
            return f"下一个节气是：{dt.month}/{dt.day} {term}"
    return ""
