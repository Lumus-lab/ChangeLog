class YarrowChange {
  final int changeIndex;
  final int before;
  final int left;
  final int right;
  final int hang;
  final int leftRemainder;
  final int rightRemainder;
  final int removed;
  final int after;

  const YarrowChange({
    required this.changeIndex,
    required this.before,
    required this.left,
    required this.right,
    required this.hang,
    required this.leftRemainder,
    required this.rightRemainder,
    required this.removed,
    required this.after,
  });

  factory YarrowChange.fromJson(Map<String, dynamic> json) {
    return YarrowChange(
      changeIndex: json['changeIndex'] as int,
      before: json['before'] as int,
      left: json['left'] as int,
      right: json['right'] as int,
      hang: json['hang'] as int,
      leftRemainder: json['leftRemainder'] as int,
      rightRemainder: json['rightRemainder'] as int,
      removed: json['removed'] as int,
      after: json['after'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'changeIndex': changeIndex,
    'before': before,
    'left': left,
    'right': right,
    'hang': hang,
    'leftRemainder': leftRemainder,
    'rightRemainder': rightRemainder,
    'removed': removed,
    'after': after,
  };
}

class YarrowLineDetail {
  final int position;
  final List<YarrowChange> changes;

  const YarrowLineDetail({required this.position, required this.changes});

  int get inferredValue {
    if (changes.length != 3) {
      throw StateError('A yarrow line must contain exactly three changes.');
    }
    final after = changes.last.after;
    if (after % 4 != 0) {
      throw StateError('Final yarrow stalk count must be divisible by 4.');
    }
    return after ~/ 4;
  }

  factory YarrowLineDetail.fromJson(Map<String, dynamic> json) {
    final changesJson = json['changes'] as List<dynamic>;
    return YarrowLineDetail(
      position: json['position'] as int,
      changes: changesJson
          .map((item) => YarrowChange.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position,
    'changes': changes.map((change) => change.toJson()).toList(),
  };
}

class YarrowSimulationDetail {
  final String type;
  final int version;
  final List<YarrowLineDetail> lines;

  const YarrowSimulationDetail({
    this.type = 'yarrow',
    this.version = 1,
    required this.lines,
  });

  List<int> get inferredLineValues =>
      lines.map((line) => line.inferredValue).toList();

  factory YarrowSimulationDetail.fromJson(Map<String, dynamic> json) {
    final linesJson = json['lines'] as List<dynamic>;
    return YarrowSimulationDetail(
      type: json['type'] as String? ?? 'yarrow',
      version: json['version'] as int? ?? 1,
      lines: linesJson
          .map(
            (item) => YarrowLineDetail.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'version': version,
    'lines': lines.map((line) => line.toJson()).toList(),
  };
}

class YarrowSimulationResult {
  final List<int> lines;
  final YarrowSimulationDetail detail;

  const YarrowSimulationResult({required this.lines, required this.detail});
}
