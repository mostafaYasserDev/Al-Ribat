import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Squircle icon badge inspired by Apple iOS & Telegram Settings.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
    this.iconSize = 17,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.14) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// Muted section header above a [SettingsGroupCard].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Optional footer caption below a [SettingsGroupCard].
class SettingsSectionFooter extends StatelessWidget {
  const SettingsSectionFooter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12.5,
          height: 1.4,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
        ),
      ),
    );
  }
}

/// Inset grouped card with iOS/Telegram hairline dividers indented past the icon.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
    this.dividerIndent = 58,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final borderColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06);
    final dividerColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.09 : 0.08);

    final visibleChildren = children;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.6),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.028),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < visibleChildren.length; i++) ...[
            visibleChildren[i],
            if (i < visibleChildren.length - 1)
              Divider(
                height: 0.6,
                thickness: 0.6,
                indent: dividerIndent,
                color: dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

/// Tactile pressable wrapper that subtly scales down on tap like iOS controls.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.onTap == null) return;
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 95),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Clean navigation/action tile inside a [SettingsGroupCard].
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingValue,
    this.trailingWidget,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final Widget? trailingWidget;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SettingsIconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget!,
              ] else if (trailingValue != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    trailingValue!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, color: muted, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean switch tile inside a [SettingsGroupCard].
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
      highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SettingsIconBadge(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// iOS-style sliding segmented control with RTL-aware animated pill.
class AnimatedSegmentedControl<T> extends StatelessWidget {
  const AnimatedSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF0A101D)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final pillColor = isDark ? const Color(0xFF1D2C46) : Colors.white;
    final selectedIndex = options
        .indexWhere((o) => o.value == selected)
        .clamp(0, options.length - 1);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                start: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: options.map((option) {
                  final isSelected = option.value == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isSelected) return;
                        HapticFeedback.selectionClick();
                        onChanged(option.value);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 13.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.62),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (option.icon != null) ...[
                                Icon(
                                  option.icon,
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small status pill badge (e.g. "مفعّل" / "غير مفعّل").
class SettingsStatusPill extends StatelessWidget {
  const SettingsStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
      ),
    );
  }
}

/// Frosted translucent SliverAppBar for sub-pages and main settings.
class FrostedSettingsSliverAppBar extends StatelessWidget {
  const FrostedSettingsSliverAppBar({
    super.key,
    required this.title,
    this.large = false,
  });

  final String title;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: large ? 104 : null,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg.withValues(alpha: 0.78),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: large
              ? FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 14,
                    end: 20,
                  ),
                  title: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  centerTitle: false,
                )
              : Container(color: Colors.transparent),
        ),
      ),
      title: large
          ? null
          : Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
      centerTitle: !large,
    );
  }
}
