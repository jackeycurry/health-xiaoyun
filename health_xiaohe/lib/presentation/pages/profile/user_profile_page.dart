import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:get_it/get_it.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  final _genderCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  static const _genderMap = {'male': '男', 'female': '女'};
  static const _catNames = {'personal': '个人信息', 'health': '健康相关', 'habit': '生活习惯', 'preference': '偏好', 'note': '备注'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiClient();
      final token = GetIt.instance<LocalStorage>().getJwtToken() ?? '';
      if (token.isEmpty) return;
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      final resp = await api.dio.get('/api/user/profile');
      if (mounted) setState(() { _data = resp.data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final api = ApiClient();
      final token = GetIt.instance<LocalStorage>().getJwtToken() ?? '';
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      await api.dio.put('/api/user/profile', data: {
        if (_genderCtrl.text.isNotEmpty) 'gender': _genderCtrl.text,
        if (_ageCtrl.text.isNotEmpty) 'age': int.tryParse(_ageCtrl.text),
        if (_heightCtrl.text.isNotEmpty) 'height': int.tryParse(_heightCtrl.text),
        if (_weightCtrl.text.isNotEmpty) 'weight': int.tryParse(_weightCtrl.text),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteMemory(String memoryId) async {
    try {
      final api = ApiClient();
      final token = GetIt.instance<LocalStorage>().getJwtToken() ?? '';
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      await api.dio.delete('/api/user/memories/$memoryId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已忘记'), backgroundColor: AppColors.success),
        );
        _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _genderCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _profile => _data?['profile'] as Map<String, dynamic>?;
  List get _memories => (_data?['memories'] as List?) ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('用户画像', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(padding: const EdgeInsets.all(16), children: [
              _buildBasicInfo(),
              const SizedBox(height: 16),
              _buildHealthSummary(),
              const SizedBox(height: 16),
              _buildRiskTags(),
              const SizedBox(height: 16),
              _buildMemories(),
            ]),
    );
  }

  Widget _buildBasicInfo() {
    final p = _profile;
    final gender = p?['gender'] as String?;
    final age = p?['age'] as int?;
    final height = p?['height'] as int?;
    final weight = p?['weight'] as int?;
    final genderLabel = gender != null ? (_genderMap[gender] ?? gender) : '未填写';

    return _card([
      Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.person, color: Colors.white, size: 30)),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), Text('完善信息以获得更精准的健康建议', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))])),
        TextButton(onPressed: _showEditDialog, child: const Text('编辑')),
      ]),
      const SizedBox(height: 12),
      _chipRow([_chip('性别', genderLabel), _chip('年龄', age != null ? '${age}岁' : '未填写'), _chip('身高', height != null ? '${height}cm' : '未填写'), _chip('体重', weight != null ? '${weight}kg' : '未填写')]),
    ], () {});
  }

  Widget _buildHealthSummary() {
    final summary = _profile?['health_summary'] as String?;
    return _card([
      _header(Icons.health_and_safety, AppColors.primary, '健康概况'),
      const SizedBox(height: 8),
      Text(summary ?? 'AI 将在对话中逐步了解你的健康状况，并自动生成总结', style: TextStyle(fontSize: 14, color: summary != null ? AppColors.textSecondary : AppColors.textTertiary, height: 1.6)),
    ], () {});
  }

  Widget _buildRiskTags() {
    final tags = (_profile?['risk_tags'] as List?) ?? [];
    return _card([
      _header(Icons.warning_amber, AppColors.warning, '健康标签'),
      const SizedBox(height: 12),
      if (tags.isEmpty)
        const Text('暂无标签，AI 将在对话中评估健康风险', style: TextStyle(fontSize: 14, color: AppColors.textTertiary))
      else
        _chipRow(tags.map((t) {
          final s = t.toString();
          return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: _tagColor(s).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(s, style: TextStyle(fontSize: 13, color: _tagColor(s), fontWeight: FontWeight.w500)));
        }).toList()),
    ], () {});
  }

  Widget _buildMemories() {
    final byCat = <String, List>{};
    for (final m in _memories) {
      final cat = (m['category'] as String?) ?? 'note';
      byCat.putIfAbsent(cat, () => []).add(m);
    }
    return _card([
      Row(children: [
        Icon(Icons.psychology, color: AppColors.primaryDark, size: 22),
        const SizedBox(width: 8),
        const Expanded(child: Text('长期记忆', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        if (_memories.isNotEmpty)
          Text('左滑可删除', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ]),
      if (_memories.isEmpty)
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('开始对话后，AI 会自动提取并记住与你相关的重要信息', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)))
      else
        ...byCat.entries.map((e) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_catNames[e.key] ?? e.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                ...e.value.map<Widget>((m) => _buildMemoryRow(m)),
              ]),
            )),
    ], () {});
  }

  Widget _buildMemoryRow(dynamic m) {
    final id = (m['id'] as String?) ?? '';
    final fact = (m['fact'] as String?) ?? '';
    return Dismissible(
      key: ValueKey('mem-$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(left: 8, top: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text('忘记', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('让 AI 忘记？'),
                content: Text('“$fact”'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('确认忘记', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteMemory(id),
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.aiBubbleBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: AppColors.primaryDark)),
            Expanded(child: Text(fact, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5))),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children, VoidCallback onTap) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)));
  }

  Widget _header(IconData icon, Color color, String title) {
    return Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]);
  }

  Widget _chipRow(List<Widget> children) {
    return Wrap(spacing: 12, runSpacing: 8, children: children);
  }

  Widget _chip(String label, String value) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.aiBubbleBg, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('$label：', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))]));
  }

  Color _tagColor(String tag) {
    if (tag.contains('高血压') || tag.contains('风险') || tag.contains('严重')) return AppColors.danger;
    if (tag.contains('关注') || tag.contains('偏高')) return AppColors.warning;
    return AppColors.primaryDark;
  }

  void _showEditDialog() {
    final p = _profile;
    _genderCtrl.text = (p?['gender'] as String?) ?? '';
    _ageCtrl.text = (p?['age'] as int?)?.toString() ?? '';
    _heightCtrl.text = (p?['height'] as int?)?.toString() ?? '';
    _weightCtrl.text = (p?['weight'] as int?)?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('编辑基本信息'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('性别', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _genderChip('male', '男', setLocal),
                    _genderChip('female', '女', setLocal),
                  ],
                ),
                const SizedBox(height: 12),
                _editField('年龄', _ageCtrl, suffix: '岁'),
                _editField('身高', _heightCtrl, suffix: 'cm'),
                _editField('体重', _weightCtrl, suffix: 'kg'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _save(); },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String value, String label, StateSetter setLocal) {
    final selected = _genderCtrl.text == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      onSelected: (_) => setLocal(() => _genderCtrl.text = value),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
