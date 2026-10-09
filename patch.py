import re

with open('lib/screens/categoryItemsScreen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace(
    'const SliverToBoxAdapter(\n                child: SizedBox(height: 110),\n              ),',
    'SliverToBoxAdapter(\n                child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.65),\n              ),'
)

code = code.replace(
    'color: _K.textSecondary, // Slate color',
    'color: const Color(0xFF475569), // Strict slate-600'
)

code = code.replace(
    'cursorColor: _K.textSecondary, // Matches app theme',
    'cursorColor: const Color(0xFF475569), // Strict slate-600'
)

with open('lib/screens/categoryItemsScreen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Bug fixed and color updated")
