part of '../add_activity_sheet.dart';

mixin _AppearanceFields on _SheetStateCore {
  List<Widget> _buildAppearance(BuildContext context) {
    return [
      Text(
        'الشكل (أيقونة ولون)',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _activityIcons.length,
          itemBuilder: (context, index) {
            final iconName = _activityIcons[index];
            final isSelected = _selectedIcon == iconName;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = iconName),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.2,
                          )
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  AppIcons.getIconData(iconName),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _activityColors.length,
          itemBuilder: (context, index) {
            final colorHex = _activityColors[index];
            final isSelected = _selectedColor == colorHex;
            final c = AppIcons.parseColor(colorHex) ?? Colors.grey;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorHex),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
