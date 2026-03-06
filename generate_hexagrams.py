import json
import os

names = ["乾", "坤", "屯", "蒙", "需", "訟", "師", "比", "小畜", "履",
"泰", "否", "同人", "大有", "謙", "豫", "隨", "蠱", "臨", "觀",
"噬嗑", "賁", "剝", "復", "无妄", "大畜", "頤", "大過", "坎", "離",
"咸", "恆", "遯", "大壯", "晉", "明夷", "家人", "睽", "蹇", "解",
"損", "益", "夬", "姤", "萃", "升", "困", "井", "革", "鼎",
"震", "艮", "漸", "歸妹", "豐", "旅", "巽", "兌", "渙", "節",
"中孚", "小過", "既濟", "未濟"]

data = []
for i, name in enumerate(names):
    data.append({
        "id": i + 1,
        "name": name,
        "description": "卦辭待補...",
        "lines": ["初爻待補...", "二爻待補...", "三爻待補...", "四爻待補...", "五爻待補...", "上爻待補..."],
        "greatImage": "大象待補...",
        "smallImages": ["小象待補...", "小象待補...", "小象待補...", "小象待補...", "小象待補...", "小象待補..."],
        "wenYan": "文言待補..." if i < 2 else None
    })

os.makedirs('assets/data', exist_ok=True)
with open('assets/data/hexagrams.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
