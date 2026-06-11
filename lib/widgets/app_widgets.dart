import 'package:flutter/material.dart';
import 'package:hospitalmanagement_flutter/features/home/dashboard.dart';
import 'package:hospitalmanagement_flutter/theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.info,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color, Color) _colors() => switch (type) {
    AppBadgeType.critico => (AppTheme.red100, AppTheme.red900),
    AppBadgeType.atencao => (AppTheme.amber100, AppTheme.amber900),
    AppBadgeType.normal => (AppTheme.green100, AppTheme.green900),
    AppBadgeType.info => (AppTheme.blue100, AppTheme.blue800),
    AppBadgeType.ia => (AppTheme.purple50, AppTheme.purple900),
    AppBadgeType.coral => (AppTheme.coral50, AppTheme.coral900),
  };
}

enum AppBadgeType { critico, atencao, normal, info, ia, coral }

AppBadgeType badgeTypeFromStatus(String status) => switch (status) {
  'critico' => AppBadgeType.critico,
  'atencao' => AppBadgeType.atencao,
  'normal' => AppBadgeType.normal,
  'ia' => AppBadgeType.ia,
  _ => AppBadgeType.info,
};

class AlertCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final AppBadgeType tipo;
  final String badgeLabel;
  final List<AlertaAcao> acoes;
  final double? progressoPercent;

  const AlertCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.badgeLabel,
    this.acoes = const [],
    this.progressoPercent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _bgBorder();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        border: Border.all(color: colors.$2, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AppBadge(label: badgeLabel, type: tipo),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (progressoPercent != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressoPercent,
                backgroundColor: Colors.grey.shade200,
                color: _progressColor(),
                minHeight: 4,
              ),
            ),
          ],
          if (acoes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: acoes
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _AcaoBtn(acao: a),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot() {
    final color = switch (tipo) {
      AppBadgeType.critico => AppTheme.red400,
      AppBadgeType.atencao => AppTheme.amber400,
      AppBadgeType.normal => AppTheme.green600,
      AppBadgeType.ia => AppTheme.purple600,
      AppBadgeType.coral => AppTheme.coral600,
      AppBadgeType.info => AppTheme.blue600,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _progressColor() => switch (tipo) {
    AppBadgeType.critico => AppTheme.red400,
    AppBadgeType.atencao => AppTheme.amber400,
    AppBadgeType.ia => AppTheme.purple600,
    _ => AppTheme.blue600,
  };

  (Color, Color) _bgBorder() => switch (tipo) {
    AppBadgeType.critico => (AppTheme.red50, AppTheme.red200),
    AppBadgeType.atencao => (AppTheme.amber50, AppTheme.amber100),
    AppBadgeType.normal => (AppTheme.green50, AppTheme.green100),
    AppBadgeType.ia => (AppTheme.purple50, AppTheme.purple200),
    AppBadgeType.coral => (AppTheme.coral50, AppTheme.coral200),
    AppBadgeType.info => (AppTheme.blue50, AppTheme.blue100),
  };
}

class AlertaAcao {
  final String label;
  final bool primaria;
  final VoidCallback? onTap;

  const AlertaAcao({required this.label, this.primaria = false, this.onTap});
}

class _AcaoBtn extends StatelessWidget {
  final AlertaAcao acao;

  const _AcaoBtn({required this.acao});

  @override
  Widget build(BuildContext context) {
    if (acao.primaria) {
      return GestureDetector(
        onTap: acao.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.blue600,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            acao.label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: acao.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Text(
          acao.label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ),
    );
  }
}

class SectionDivider extends StatelessWidget {
  final String label;

  const SectionDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 0.5, color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(thickness: 0.5, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool carregando;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.carregando,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (carregando)
          Container(
            color: Colors.white.withOpacity(0.7),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.purple600),
            ),
          ),
      ],
    );
  }
}

class AiBadge extends StatelessWidget {
  const AiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.purple50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'IA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.purple800,
        ),
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color? cor;

  const ScoreBar({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = score / maxScore;
    final color =
        cor ??
        (pct >= 0.8
            ? AppTheme.green600
            : pct >= 0.6
            ? AppTheme.amber400
            : AppTheme.red400);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: pct,
        backgroundColor: Colors.grey.shade200,
        color: color,
        minHeight: 6,
      ),
    );
  }
}

//login, splash, matricula e cadastro
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppTheme.purple800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.purple200,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.purple50,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.suffixIcon,
    this.onSuffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.purple50, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? IconButton(icon: Icon(suffixIcon, color: Colors.white70), onPressed: onSuffixPressed)
                : null,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}


