import 'package:flutter/material.dart';
import 'package:hotel_booking/theme/app_colors.dart';
import 'package:hotel_booking/theme/app_theme.dart';

/// Horizontal step tracker used by the check-in and check-out flows.
/// Replaces the three side-by-side desktop columns with a mobile stepper.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final leftStep = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: leftStep < currentStep
                  ? AppColors.primary
                  : AppColors.border,
            ),
          );
        }

        final step = index ~/ 2;
        final isDone = step < currentStep;
        final isActive = step == currentStep;

        return _StepDot(
          index: step,
          label: steps[step],
          isDone: isDone,
          isActive: isActive,
          onTap: onStepTapped == null ? null : () => onStepTapped!(step),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isActive,
    this.onTap,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = isDone || isActive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 74,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer that keeps the running total and primary action in reach.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.secondaryAction,
    this.enabled = true,
    this.completed = false,
  });

  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? actionIcon;
  final Widget? secondaryAction;
  final bool enabled;
  final bool completed;

  ButtonStyle get _buttonStyle => FilledButton.styleFrom(
    backgroundColor: completed ? AppColors.successDark : AppColors.primary,
    disabledBackgroundColor: completed
        ? AppColors.successDark
        : AppColors.primary.withValues(alpha: 0.45),
    disabledForegroundColor: Colors.white,
    minimumSize: const Size(0, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(horizontal: 18),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          if (secondaryAction != null) ...[
            secondaryAction!,
            const SizedBox(width: 8),
          ],
          actionIcon == null
              ? FilledButton(
                  onPressed: enabled ? onAction : null,
                  style: _buttonStyle,
                  child: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : FilledButton.icon(
                  onPressed: enabled ? onAction : null,
                  style: _buttonStyle,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ],
      ),
    );
  }
}
