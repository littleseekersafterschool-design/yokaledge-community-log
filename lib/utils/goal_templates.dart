class GoalTemplate {
  final String title;
  final String description;
  final String category;
  final String icon;
  final String color;

  const GoalTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
  });
}

class GoalTemplates {
  static const String afterSchool = '学童保育テンプレート';
  static const String nursery = '保育園テンプレート';
  static const String dayService = '放課後等デイサービステンプレート';
  static const String custom = 'カスタム';

  static const List<String> templateNames = [
    afterSchool,
    nursery,
    dayService,
    custom,
  ];

  static List<GoalTemplate> getTemplate(String name) {
    switch (name) {
      case afterSchool:
        return afterSchoolGoals;
      case nursery:
        return nurseryGoals;
      case dayService:
        return dayServiceGoals;
      default:
        return [];
    }
  }

  static const List<GoalTemplate> afterSchoolGoals = [
    GoalTemplate(
      title: '主体性の尊重',
      description: 'こどもが自分で決める場面を支えられたか',
      category: '主体性',
      icon: 'seedling',
      color: 'green',
    ),
    GoalTemplate(
      title: '安全の見守り',
      description: '安全を意識して見守れたか',
      category: '安全',
      icon: 'shield',
      color: 'blue',
    ),
    GoalTemplate(
      title: '関係性の支援',
      description: 'こども同士の関係性を支えられたか',
      category: '関係性',
      icon: 'heart',
      color: 'orange',
    ),
    GoalTemplate(
      title: '遊び環境づくり',
      description: '遊びの環境を整えられたか',
      category: '環境',
      icon: 'play',
      color: 'yellow',
    ),
    GoalTemplate(
      title: 'スタッフ連携',
      description: 'スタッフ間で情報共有できたか',
      category: 'チーム連携',
      icon: 'handshake',
      color: 'purple',
    ),
  ];

  static const List<GoalTemplate> nurseryGoals = [
    GoalTemplate(
      title: '子どもの気持ちに寄り添う',
      description: '子どもの感情に共感し受け止められたか',
      category: '保育',
      icon: 'heart',
      color: 'pink',
    ),
    GoalTemplate(
      title: '安全な保育環境',
      description: '安全な環境で保育できたか',
      category: '安全',
      icon: 'shield',
      color: 'blue',
    ),
    GoalTemplate(
      title: '生活リズムの支援',
      description: '子どもの生活リズムを大切にできたか',
      category: '保育',
      icon: 'sun',
      color: 'orange',
    ),
    GoalTemplate(
      title: '保護者との連携',
      description: '保護者と十分なコミュニケーションがとれたか',
      category: 'チーム連携',
      icon: 'chat',
      color: 'green',
    ),
    GoalTemplate(
      title: '遊びを通じた学び',
      description: '遊びの中で子どもの学びを促せたか',
      category: '環境',
      icon: 'play',
      color: 'yellow',
    ),
  ];

  static const List<GoalTemplate> dayServiceGoals = [
    GoalTemplate(
      title: '個別支援計画の実行',
      description: '一人ひとりの支援計画に沿った活動ができたか',
      category: '保育',
      icon: 'book',
      color: 'blue',
    ),
    GoalTemplate(
      title: '安心できる居場所づくり',
      description: '子どもが安心して過ごせる環境をつくれたか',
      category: '環境',
      icon: 'heart',
      color: 'green',
    ),
    GoalTemplate(
      title: 'コミュニケーション支援',
      description: '子ども同士のコミュニケーションを支援できたか',
      category: '関係性',
      icon: 'chat',
      color: 'orange',
    ),
    GoalTemplate(
      title: '自立に向けた支援',
      description: '生活スキルの習得を支援できたか',
      category: '主体性',
      icon: 'seedling',
      color: 'purple',
    ),
    GoalTemplate(
      title: 'チーム支援体制',
      description: 'スタッフ間で情報を共有し連携できたか',
      category: 'チーム連携',
      icon: 'handshake',
      color: 'teal',
    ),
  ];
}
