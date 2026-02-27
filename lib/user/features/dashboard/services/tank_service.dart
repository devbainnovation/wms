class TankData {
  const TankData({
    required this.id,
    required this.name,
    required this.capacityLabel,
    required this.levelPercent,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String capacityLabel;
  final double levelPercent;
  final DateTime updatedAt;
}

abstract class TankService {
  Future<List<TankData>> getTanks();
}

class MockTankService implements TankService {
  @override
  Future<List<TankData>> getTanks() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    // Replace with real API response mapping later.
    return <TankData>[
      TankData(
        id: '1',
        name: 'Jangar OHT',
        capacityLabel: '5000 L',
        levelPercent: 0.65,
        updatedAt: DateTime(2026, 2, 26, 15, 27, 52),
      ),
      TankData(
        id: '2',
        name: 'Jangar SMT',
        capacityLabel: '3000 L',
        levelPercent: 0.18,
        updatedAt: DateTime(2026, 2, 26, 15, 28, 15),
      ),
      TankData(
        id: '3',
        name: 'Highschool Tank',
        capacityLabel: '8000 L',
        levelPercent: 0.82,
        updatedAt: DateTime(2026, 2, 26, 15, 29, 44),
      ),
    ];
  }
}
