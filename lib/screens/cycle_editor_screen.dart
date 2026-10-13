import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cycle_model.dart';
import '../providers/cycle_provider.dart';
import '../utils/app_toast.dart';

class CycleEditorScreen extends StatefulWidget {
  final bool isInitialSetup;

  const CycleEditorScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<CycleEditorScreen> createState() => _CycleEditorScreenState();
}

class _DayItemDraft {
  final String id;
  final TextEditingController titleController;
  final TextEditingController notesController;
  bool isRest;

  _DayItemDraft({
    required this.id,
    String title = '',
    String notes = '',
    this.isRest = false,
  })  : titleController = TextEditingController(text: title),
        notesController = TextEditingController(text: notes);

  void dispose() {
    titleController.dispose();
    notesController.dispose();
  }
}

class _CycleEditorScreenState extends State<CycleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final List<_DayItemDraft> _dayDrafts = [];
  bool _autoAdvance = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CycleProvider>();
    final currentCycle = provider.cycle;

    if (currentCycle != null && currentCycle.days.isNotEmpty) {
      _nameController = TextEditingController(text: currentCycle.name);
      _autoAdvance = currentCycle.autoAdvance;
      for (final day in currentCycle.days) {
        _dayDrafts.add(_DayItemDraft(
          id: day.id,
          title: day.title,
          notes: day.notes,
          isRest: day.isRest,
        ));
      }
    } else {
      _nameController = TextEditingController(text: '我的训练循环');
      _autoAdvance = true;
      // 默认给用户提供初始可填写的两天空项，由用户自己定义
      _dayDrafts.add(_DayItemDraft(id: '1', title: '', isRest: false));
      _dayDrafts.add(_DayItemDraft(id: '2', title: '', isRest: false));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _dayDrafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    setState(() {
      _dayDrafts.add(_DayItemDraft(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        isRest: false,
      ));
    });
  }

  void _removeDay(int index) {
    if (_dayDrafts.length <= 1) {
      AppToast.warning(context, '至少需要保留 1 天计划哦');
      return;
    }
    setState(() {
      final removed = _dayDrafts.removeAt(index);
      removed.dispose();
    });
  }

  void _applyTemplate(String name, List<Map<String, dynamic>> items) {
    setState(() {
      _nameController.text = name;
      for (final d in _dayDrafts) {
        d.dispose();
      }
      _dayDrafts.clear();
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        _dayDrafts.add(_DayItemDraft(
          id: '$i',
          title: item['title'] as String,
          notes: item['notes'] as String? ?? '',
          isRest: item['isRest'] as bool? ?? false,
        ));
      }
    });
    AppToast.success(context, '已导入模版「$name」，可自由修改');
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _dayDrafts.length; i++) {
      if (_dayDrafts[i].titleController.text.trim().isEmpty) {
        AppToast.warning(context, '第 ${i + 1} 天的内容还没有填写');
        return;
      }
    }

    final cycleDays = _dayDrafts.map((d) {
      return CycleDay(
        id: d.id,
        title: d.titleController.text.trim(),
        notes: d.notesController.text.trim(),
        isRest: d.isRest,
      );
    }).toList();

    final provider = context.read<CycleProvider>();
    final existingCycle = provider.cycle;

    final newCycle = WorkoutCycle(
      name: _nameController.text.trim().isEmpty
          ? '我的训练循环'
          : _nameController.text.trim(),
      days: cycleDays,
      currentIndex: (existingCycle != null && existingCycle.currentIndex < cycleDays.length)
          ? existingCycle.currentIndex
          : 0,
      lastCompletedDate: existingCycle?.lastCompletedDate,
      history: existingCycle?.history ?? [],
      autoAdvance: _autoAdvance,
      lastActiveDate: existingCycle?.lastActiveDate,
    );

    provider.saveCycle(newCycle);

    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? '创建训练循环' : '编辑训练循环'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, color: Color(0xFF10B981)),
            label: const Text(
              '保存',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Plan Name Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计划名称',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: '例如：我的四分化 / 力量提升循环',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Auto-advance switch card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.update_rounded, color: Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '次日 0 点自动轮转',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _autoAdvance
                              ? '开启：即使忘点打卡，第二天也会自动推进'
                              : '关闭：必须手动打卡才会推进到下一天',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoAdvance,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setState(() {
                        _autoAdvance = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Reference Templates (optional helper)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Color(0xFF38BDF8)),
                      SizedBox(width: 6),
                      Text(
                        '快速参考模版（可选填入并自行修改）：',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('4天循环 (背二/肩腿/胸三/休)'),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                        onPressed: () => _applyTemplate('经典四分化', [
                          {'title': '背部 + 二头', 'notes': '引体向上、高位下拉、划船、弯举', 'isRest': false},
                          {'title': '肩部 + 腿部', 'notes': '推举、侧平举、深蹲、腿弯举', 'isRest': false},
                          {'title': '胸部 + 三头', 'notes': '卧推、上斜哑铃推、下压', 'isRest': false},
                          {'title': '全面休息恢复', 'notes': '充足睡眠、营养补充', 'isRest': true},
                        ]),
                      ),
                      ActionChip(
                        label: const Text('3天循环 (推/拉/腿)'),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                        onPressed: () => _applyTemplate('PPL 三分化', [
                          {'title': '推 (胸/肩/三头)', 'notes': '卧推、推举、臂屈伸', 'isRest': false},
                          {'title': '拉 (背/二头)', 'notes': '引体、划船、二头弯举', 'isRest': false},
                          {'title': '腿 (下肢/腹肌)', 'notes': '深蹲、硬拉、卷腹', 'isRest': false},
                        ]),
                      ),
                      ActionChip(
                        label: const Text('5天循环 (胸/背/肩/腿/手/休)'),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                        onPressed: () => _applyTemplate('经典五分化', [
                          {'title': '胸部特化', 'notes': '平板卧推、上斜哑铃飞鸟', 'isRest': false},
                          {'title': '背部特化', 'notes': '引体向上、杠铃划船', 'isRest': false},
                          {'title': '肩部特化', 'notes': '坐姿哑铃推举、侧平举', 'isRest': false},
                          {'title': '腿部特化', 'notes': '深蹲、腿举、直腿硬拉', 'isRest': false},
                          {'title': '手臂特化', 'notes': '杠铃弯举、绳索下压', 'isRest': false},
                          {'title': '休息恢复日', 'notes': '散步拉伸、充分休息', 'isRest': true},
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '循环天数序列 (${_dayDrafts.length} 天)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8), size: 18),
                  label: const Text(
                    '添加一天',
                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // List of Days
            ...List.generate(_dayDrafts.length, (index) {
              final draft = _dayDrafts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: draft.isRest ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: draft.isRest
                        ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: draft.isRest
                                ? const Color(0xFF4338CA)
                                : const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '第 ${index + 1} 天',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            draft.isRest ? '恢复休息日' : '训练日',
                            style: TextStyle(
                              fontSize: 13,
                              color: draft.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Rest switch
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '休息日',
                              style: TextStyle(
                                fontSize: 12,
                                color: draft.isRest ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                            Switch(
                              value: draft.isRest,
                              activeThumbColor: const Color(0xFF818CF8),
                              onChanged: (val) {
                                setState(() {
                                  draft.isRest = val;
                                  if (val && draft.titleController.text.trim().isEmpty) {
                                    draft.titleController.text = '休息恢复日';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                          onPressed: () => _removeDay(index),
                          tooltip: '删除此天',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: draft.titleController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: '训练内容 / 部位名称',
                        hintText: draft.isRest ? '例如：休息恢复、主动拉伸' : '例如：背部 + 二头肌',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: draft.notesController,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0)),
                      decoration: InputDecoration(
                        labelText: '动作备忘 / 备注（选填）',
                        hintText: draft.isRest ? '例如：散步30分钟、补充睡眠' : '例如：高位下拉、划船、杠铃弯举',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
              label: const Text('添加下一天训练', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isInitialSetup ? '完成设置 · 开启循环' : '保存修改计划',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
