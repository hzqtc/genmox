import json
from datetime import datetime

from zhdate import ZhDate  # type: ignore

import solar_terms

LUNAR_FESTIVALS = {
    1: {
        1: "春节",
        15: "元宵节",
    },
    5: {
        5: "端午节",
    },
    7: {
        7: "七夕节",
    },
    8: {
        15: "中秋节",
    },
    9: {
        9: "重阳节",
    },
    12: {
        8: "腊八节",
    },
}

ZH_NUMS = "〇一二三四五六七八九十"

ZODIACS = "鼠牛虎兔龙蛇马羊猴鸡狗猪"

ZH_HOURS = "子丑丑寅寅卯卯辰辰巳巳午午未未申申酉酉戌戌亥亥子"


def main():
    now = datetime.now()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    lunar_date = ZhDate.from_datetime(today)

    lunar_year = format_lunar_year(lunar_date.lunar_year)
    lunar_month = format_lunar_month(lunar_date.lunar_month, lunar_date.leap_month)
    lunar_day = format_lunar_day(lunar_date.lunar_day)
    zodiac = ZODIACS[(lunar_date.lunar_year - 1900) % 12]

    festival_date, festival = next_festival(lunar_date)
    festival_month = format_lunar_month(
        festival_date.lunar_month, festival_date.leap_month
    )
    festival_day = format_lunar_day(festival_date.lunar_day)
    festival_text = (
        "今天是：" if festival_date == lunar_date else "下一个节日是："
    ) + festival
    festival_subtext = (
        f"{festival_date - lunar_date}天后" if festival_date - lunar_date > 0 else ""
    )

    solar_term_date, solar_term = solar_terms.next_solar_term(today)
    solar_term_lunar_date = ZhDate.from_datetime(
        solar_term_date.replace(hour=0, minute=0, second=0, microsecond=0)
    )
    solar_term_month = format_lunar_month(
        solar_term_lunar_date.lunar_month, solar_term_lunar_date.leap_month
    )
    solar_term_day = format_lunar_day(solar_term_lunar_date.lunar_day)
    solar_term_text = (
        "今天是：" if solar_term_date == today else "下一个节气是："
    ) + solar_term
    solar_term_subtext = (
        f"{solar_term_lunar_date - lunar_date}天后"
        if solar_term_lunar_date - lunar_date > 0
        else ""
    )

    msg = {
        "text": "{}月{}".format(lunar_month, lunar_day),
        "imagesymbol": "calendar",
        "menus": [
            {
                "text": f"今天是：{lunar_year}年 {lunar_month}月{lunar_day}",
                "badge": "{}年".format(zodiac),
                "subtext": chinese_time(now),
                "click": f"/usr/bin/open https://zh.wikipedia.org/wiki/{lunar_month}月{lunar_day}",
            },
            {
                "text": festival_text,
                "badge": f"{festival_month}月{festival_day}",
                "subtext": festival_subtext,
                "click": f"/usr/bin/open https://zh.wikipedia.org/wiki/{festival}",
            },
            {
                "text": solar_term_text,
                "badge": f"{solar_term_month}月{solar_term_day}",
                "subtext": solar_term_subtext,
                "click": f"/usr/bin/open https://zh.wikipedia.org/wiki/{solar_term}",
            },
        ],
    }

    print(json.dumps(msg))


def format_lunar_year(num: int) -> str:
    num = num - 1900 + 36
    tian = "甲乙丙丁戊己庚辛壬癸"
    di = "子丑寅卯辰巳午未申酉戌亥"
    return "{}{}".format(tian[num % 10], di[num % 12])


def format_lunar_month(num: int, leap: bool = False) -> str:
    if leap:
        lunar_month = "闰"
    else:
        lunar_month = ""

    if num == 1:
        lunar_month += "正"
    elif num == 12:
        lunar_month += "腊"
    elif num <= 10:
        lunar_month += ZH_NUMS[num]
    else:
        lunar_month += "十{}".format(ZH_NUMS[num - 10])

    return lunar_month


def format_lunar_day(num: int) -> str:
    if num <= 10:
        lunar_day = "初{}".format(ZH_NUMS[num])
    elif num < 20:
        lunar_day = "十{}".format(ZH_NUMS[num - 10])
    elif num == 20:
        lunar_day = "二十"
    elif num < 30:
        lunar_day = "廿{}".format(ZH_NUMS[num - 20])
    else:
        lunar_day = "三十"

    return lunar_day


def chinese_time(dt: datetime) -> str:
    chinese_hour = ZH_HOURS[dt.hour]
    minute_passed = dt.minute
    # A Chinese hour is 2 hours
    if chinese_hour == ZH_HOURS[(dt.hour - 1) % 24]:
        minute_passed += 60
    quarters = minute_passed // 15 + 1
    return f"{chinese_hour}时{ZH_NUMS[quarters]}刻"


def next_festival(lunar_date: ZhDate) -> tuple[ZhDate, str]:
    while (
        lunar_date.lunar_month not in LUNAR_FESTIVALS
        or lunar_date.lunar_day not in LUNAR_FESTIVALS[lunar_date.lunar_month]
    ):
        lunar_date += 1
    return lunar_date, LUNAR_FESTIVALS[lunar_date.lunar_month][lunar_date.lunar_day]


if __name__ == "__main__":
    main()
