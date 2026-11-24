part of 'independent_activities_card.dart';

const _onGradient = TextStyle(
  color: Color(0xFFF2F6FC),
  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 8, color: Colors.black38)],
);

TextStyle _cardTitleStyle(BuildContext context, bool light) {
  if (light) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF142018),
              fontWeight: FontWeight.w700,
            ) ??
        const TextStyle(color: Color(0xFF142018), fontWeight: FontWeight.w700);
  }
  return Theme.of(context).textTheme.titleMedium?.merge(_onGradient) ??
      _onGradient;
}

TextStyle _cardBodyStyle(BuildContext context, bool light) {
  if (light) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF4A5568),
            ) ??
        const TextStyle(color: Color(0xFF4A5568));
  }
  return Theme.of(context).textTheme.bodySmall?.merge(_onGradient) ??
      _onGradient;
}
