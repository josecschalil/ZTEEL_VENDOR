import re

with open('lib/screens/MilestoneScreen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Top bar radius: 36 -> 24
content = re.sub(r"Radius\.circular\(36\)", "Radius.circular(24)", content)

# Empty state tweaks:
# Icon size 56 -> 48, padding 28 -> 20, fontSize 19 -> 17
content = content.replace("size: 56,", "size: 48,")
content = content.replace("padding: const EdgeInsets.all(28),", "padding: const EdgeInsets.all(20),")
content = content.replace("fontSize: 19,", "fontSize: 17,")

# Card padding and radius: 16 -> 14, 16 -> 12
content = content.replace("padding: const EdgeInsets.all(16),", "padding: const EdgeInsets.all(14),")
content = content.replace("borderRadius: BorderRadius.circular(16),", "borderRadius: BorderRadius.circular(12),")

# Textfield heights: 48 -> 44
content = content.replace("height: 48,", "height: 44,")
# Reward type tabs height: 42 -> 38
content = content.replace("height: 42,", "height: 38,")
# Search input height in bottom sheet: 44 -> 40
content = content.replace("height: 44,", "height: 40,")

# Save button height: 46 -> 44, Add button height 44 -> 42
content = content.replace("height: 46,\n      child: ElevatedButton(", "height: 44,\n      child: ElevatedButton(")
content = content.replace("height: 44,\n        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),", "height: 42,\n        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),")
# Also update dashed border painter radius
content = content.replace("borderRadius: 12,\n              dashWidth: 8,", "borderRadius: 10,\n              dashWidth: 8,")

# Border radius of inputs: 10 -> 8
content = content.replace("borderRadius: BorderRadius.circular(10),", "borderRadius: BorderRadius.circular(8),")

# Plus/minus buttons: 34 -> 30
content = content.replace("width: 34,\n                    height: 34,", "width: 30,\n                    height: 30,")

# Save button radius: 14 -> 10
content = content.replace("RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))", "RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))")

with open('lib/screens/MilestoneScreen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Sizing adjusted to be tighter and more professional")
