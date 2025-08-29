import json
from datetime import datetime

from zhdate import ZhDate  # type: ignore

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

NUMS = "〇一二三四五六七八九十"

ZODIACS = "鼠牛虎兔龙蛇马羊猴鸡狗猪"


def main():
    lunar_date = ZhDate.from_datetime(datetime.now())
    lunar_year = format_lunar_year(lunar_date.lunar_year - 1900 + 36)
    lunar_month = format_lunar_month(lunar_date.lunar_month, lunar_date.leap_month)
    lunar_day = format_lunar_day(lunar_date.lunar_day)
    zodiac = ZODIACS[(lunar_date.lunar_year - 1900) % 12]

    msg = {
        "text": "{}月{}".format(lunar_month, lunar_day),
        "imagesymbol": "calendar",
        "menus": [
            {
                "text": "{}年 {}月{}".format(lunar_year, lunar_month, lunar_day),
                "badge": "{}年".format(zodiac),
                "subtext": next_festival(lunar_date),
                "click": "/usr/bin/open https://zh.wikipedia.org/wiki/{}月{}".format(
                    lunar_month, lunar_day
                ),
            }
        ],
    }

    print(json.dumps(msg))


def format_lunar_year(num: int) -> str:
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
        lunar_month += NUMS[num]
    else:
        lunar_month += "十{}".format(NUMS[num - 10])

    return lunar_month


def format_lunar_day(num: int) -> str:
    if num <= 10:
        lunar_day = "初{}".format(NUMS[num])
    elif num < 20:
        lunar_day = "十{}".format(NUMS[num - 10])
    elif num == 20:
        lunar_day = "二十"
    elif num < 30:
        lunar_day = "廿{}".format(NUMS[num - 20])
    else:
        lunar_day = "三十"

    return lunar_day


def next_festival(lunar_date: ZhDate) -> str:
    for month in LUNAR_FESTIVALS:
        if lunar_date.lunar_month > month:
            continue
        for day in LUNAR_FESTIVALS[month]:
            if lunar_date.lunar_day > day:
                continue
            if lunar_date.lunar_month == month and lunar_date.lunar_day == day:
                return "今天是：{}".format(LUNAR_FESTIVALS[month][day])
            else:
                return "下一个节日是：{}月{} {}".format(
                    format_lunar_month(month),
                    format_lunar_day(day),
                    LUNAR_FESTIVALS[month][day],
                )
    return ""


if __name__ == "__main__":
    main()
