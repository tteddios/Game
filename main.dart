import 'dart:io';
import 'dart:math';

class Game {
  late Character character;
  List<Monster> monsters = [];
  int defeatedMonsters = 0;
  final int totalMonsters;

  Game(this.totalMonsters);

  Future<void> startGame() async {
    await loadCharacterStats();
    await loadMonsterStats();
    print('게임을 시작합니다!');
    character.showStatus();

    while (character.health > 0 && defeatedMonsters < totalMonsters) {
      Monster currentMonster = getRandomMonster();
      print('\n새로운 몬스터가 나타났습니다!');
      currentMonster.showStatus();

      battle(currentMonster);

      if (character.health <= 0) {
        print('게임 오버! ${character.name}이(가) 패배했습니다.');
        saveResult(false);
        return;
      }

      if (defeatedMonsters < totalMonsters) {
        if (!continueGame()) {
          print('게임을 종료합니다.');
          saveResult(false);
          return;
        }
      }
    }

    if (defeatedMonsters == totalMonsters) {
      print('축하합니다! 모든 몬스터를 물리쳤습니다.');
      saveResult(true);
    }
  }

  void battle(Monster monster) {
    while (character.health > 0 && monster.health > 0) {
      print('\n${character.name}의 턴');
      int action = getPlayerAction();

      if (action == 1) {
        character.attackMonster(monster);
      } else if (action == 2) {
        character.defend();
      }

      if (monster.health > 0) {
        print('\n${monster.name}의 턴');
        monster.attackCharacter(character);
      }

      character.showStatus();
      monster.showStatus();
    }

    if (monster.health <= 0) {
      print('${monster.name}을(를) 물리쳤습니다!');
      defeatedMonsters++;
      monsters.remove(monster);
    }
  }

  Monster getRandomMonster() {
    return monsters[Random().nextInt(monsters.length)];
  }

  Future<void> loadCharacterStats() async {
    try {
      final file = File('characters.txt');
      final contents = await file.readAsString();
      final stats = contents.trim().split(',');
      if (stats.length != 3) throw FormatException('Invalid character data');

      int health = int.parse(stats[0]);
      int attack = int.parse(stats[1]);
      int defense = int.parse(stats[2]);

      String name = getCharacterName();
      character = Character(name, health, attack, defense);
    } catch (e) {
      print('캐릭터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  Future<void> loadMonsterStats() async {
    try {
      final file = File('monsters.txt');
      final lines = await file.readAsLines();
      for (var line in lines) {
        final stats = line.split(',');
        if (stats.length != 3) throw FormatException('Invalid monster data');

        String name = stats[0];
        int health = int.parse(stats[1]);
        int maxAttack = int.parse(stats[2]);

        monsters.add(Monster(name, health, maxAttack));
      }
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  String getCharacterName() {
    while (true) {
      print('캐릭터의 이름을 입력하세요 (한글 또는 영문 대소문자만 허용):');
      String? name = stdin.readLineSync();
      if (name != null && name.isNotEmpty && RegExp(r'^[\p{L}]+$', unicode: true).hasMatch(name)) {
        return name;
      }
      print('잘못된 이름입니다. 다시 입력해주세요.');
    }
  }

  int getPlayerAction() {
    while (true) {
      print('행동을 선택하세요 (1: 공격, 2: 방어):');
      String? input = stdin.readLineSync();
      if (input == '1' || input == '2') {
        return int.parse(input!);
      }
      print('잘못된 입력입니다. 1 또는 2를 입력해주세요.');
    }
  }

  bool continueGame() {
    while (true) {
      print('다음 몬스터와 싸우시겠습니까? (y/n):');
      String? input = stdin.readLineSync()?.toLowerCase();
      if (input == 'y') return true;
      if (input == 'n') return false;
      print('잘못된 입력입니다. y 또는 n을 입력해주세요.');
    }
  }

  void saveResult(bool isVictory) {
    int attempts = 0;
    const int maxAttempts = 3;

    while (attempts < maxAttempts) {
      print('결과를 저장하시겠습니까? (y/n):');
      String? input = stdin.readLineSync()?.toLowerCase();
      
      if (input == 'y') {
        try {
          String result = isVictory ? '승리' : '패배';
          String content = '${character.name},${character.health},$result';
          File('result.txt').writeAsStringSync(content);
          print('결과가 result.txt 파일에 저장되었습니다.');
          return;
        } catch (e) {
          print('결과 저장 중 오류가 발생했습니다: $e');
          print('다시 시도해주세요.');
        }
      } else if (input == 'n') {
        print('결과를 저장하지 않았습니다.');
        return;
      } else {
        attempts++;
        if (attempts < maxAttempts) {
          print('잘못된 입력입니다. y 또는 n을 입력해주세요. (남은 시도: ${maxAttempts - attempts})');
        } else {
          print('여러 번의 잘못된 입력으로 결과를 저장하지 않고 종료합니다.');
        }
      }
    }
  }
}

class Character {
  String name;
  int health;
  int attack;
  int defense;

  Character(this.name, this.health, this.attack, this.defense);

  void attackMonster(Monster monster) {
    int damage = attack;
    monster.health -= max(damage, 0);
    print('${name}이(가) ${monster.name}에게 $damage의 데미지를 입혔습니다.');
  }

  void defend() {
    int heal = 7;
    health += heal;
    print('${name}이(가) 방어 태세를 취하여 $heal 만큼 체력을 얻었습니다.');
  }

  void showStatus() {
    print('$name - 체력: $health, 공격력: $attack, 방어력: $defense');
  }
}

class Monster {
  String name;
  int health;
  late int attack;
  int defense = 0;

  Monster(this.name, this.health, int maxAttack) {
    attack = max(Random().nextInt(maxAttack) + 1, 5);  // 최소 공격력 5로 설정
  }

  void attackCharacter(Character character) {
    int damage = max(attack - character.defense, 0);
    character.health -= damage;
    print('${name}이(가) ${character.name}에게 $damage의 데미지를 입혔습니다.');
  }

  void showStatus() {
    print('$name - 체력: $health, 공격력: $attack');
  }
}

void main() async {
  Game game = Game(2);  // 총 2마리의 몬스터와 대결
  await game.startGame();
}