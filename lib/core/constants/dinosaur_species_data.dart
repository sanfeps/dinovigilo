import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_rarity.dart';
import 'package:dinovigilo/features/dinosaurs/domain/entities/dinosaur_species.dart';

class DinosaurSpeciesData {
  DinosaurSpeciesData._();

  static List<DinosaurSpecies> get allSpecies => [
        ...commonSpecies,
        ...uncommonSpecies,
        ...rareSpecies,
        ...epicSpecies,
        ...legendarySpecies,
      ];

  static List<DinosaurSpecies> get commonSpecies => const [
        DinosaurSpecies(
          id: 'common_trex_baby',
          name: 'Baby T-Rex',
          emoji: '\u{1F996}',
          rarity: DinosaurRarity.common,
          description: 'A tiny tyrant lizard, just starting its journey',
        ),
        DinosaurSpecies(
          id: 'common_brontosaurus',
          name: 'Baby Brontosaurus',
          emoji: '\u{1F995}',
          rarity: DinosaurRarity.common,
          description: 'Long-necked gentle giant in the making',
        ),
        DinosaurSpecies(
          id: 'common_stegosaurus',
          name: 'Baby Stegosaurus',
          emoji: '\u{1F98E}',
          rarity: DinosaurRarity.common,
          description: 'Tiny plates growing on its back',
        ),
        DinosaurSpecies(
          id: 'common_triceratops',
          name: 'Baby Triceratops',
          emoji: '\u{1F98F}',
          rarity: DinosaurRarity.common,
          description: 'Three little horns and big dreams',
        ),
        DinosaurSpecies(
          id: 'common_pachycephalosaurus',
          name: 'Baby Pachy',
          emoji: '\u{1F43A}',
          rarity: DinosaurRarity.common,
          description: 'Hard-headed from day one',
        ),
      ];

  static List<DinosaurSpecies> get uncommonSpecies => const [
        DinosaurSpecies(
          id: 'uncommon_velociraptor',
          name: 'Velociraptor',
          emoji: '\u{1F996}',
          rarity: DinosaurRarity.uncommon,
          description: 'Swift and clever hunter',
        ),
        DinosaurSpecies(
          id: 'uncommon_spinosaurus',
          name: 'Spinosaurus',
          emoji: '\u{1F40A}',
          rarity: DinosaurRarity.uncommon,
          description: 'Sail-backed aquatic predator',
        ),
        DinosaurSpecies(
          id: 'uncommon_parasaurolophus',
          name: 'Parasaurolophus',
          emoji: '\u{1F995}',
          rarity: DinosaurRarity.uncommon,
          description: 'Musical crest for communication',
        ),
        DinosaurSpecies(
          id: 'uncommon_dilophosaurus',
          name: 'Dilophosaurus',
          emoji: '\u{1F98E}',
          rarity: DinosaurRarity.uncommon,
          description: 'Double-crested speedster',
        ),
      ];

  static List<DinosaurSpecies> get rareSpecies => const [
        DinosaurSpecies(
          id: 'rare_pteranodon',
          name: 'Pteranodon',
          emoji: '\u{1F985}',
          rarity: DinosaurRarity.rare,
          description: 'Master of the skies',
        ),
        DinosaurSpecies(
          id: 'rare_ankylosaurus',
          name: 'Ankylosaurus',
          emoji: '\u{1F422}',
          rarity: DinosaurRarity.rare,
          description: 'Living tank with a club tail',
        ),
        DinosaurSpecies(
          id: 'rare_iguanodon',
          name: 'Iguanodon',
          emoji: '\u{1F995}',
          rarity: DinosaurRarity.rare,
          description: 'Thumb spike specialist',
        ),
        DinosaurSpecies(
          id: 'rare_allosaurus',
          name: 'Allosaurus',
          emoji: '\u{1F996}',
          rarity: DinosaurRarity.rare,
          description: 'Apex predator of the Jurassic',
        ),
        DinosaurSpecies(
          id: 'rare_brachiosaurus',
          name: 'Brachiosaurus',
          emoji: '\u{1F995}',
          rarity: DinosaurRarity.rare,
          description: 'Gentle giant reaching the treetops',
        ),
        DinosaurSpecies(
          id: 'rare_quetzalcoatlus',
          name: 'Quetzalcoatlus',
          emoji: '\u{1F985}',
          rarity: DinosaurRarity.rare,
          description: 'Largest flying creature ever',
        ),
      ];

  static List<DinosaurSpecies> get epicSpecies => const [
        DinosaurSpecies(
          id: 'epic_carnotaurus',
          name: 'Carnotaurus',
          emoji: '\u{1F996}',
          rarity: DinosaurRarity.epic,
          description: 'Bull-horned speed demon',
        ),
        DinosaurSpecies(
          id: 'epic_giganotosaurus',
          name: 'Giganotosaurus',
          emoji: '\u{1F996}',
          rarity: DinosaurRarity.epic,
          description: 'Rival to T-Rex in size',
        ),
        DinosaurSpecies(
          id: 'epic_therizinosaurus',
          name: 'Therizinosaurus',
          emoji: '\u{1F995}',
          rarity: DinosaurRarity.epic,
          description: 'Giant claws of mystery',
        ),
        DinosaurSpecies(
          id: 'epic_mosasaurus',
          name: 'Mosasaurus',
          emoji: '\u{1F40B}',
          rarity: DinosaurRarity.epic,
          description: 'Terror of ancient seas',
        ),
        DinosaurSpecies(
          id: 'epic_argentavis',
          name: 'Argentavis',
          emoji: '\u{1F985}',
          rarity: DinosaurRarity.epic,
          description: 'Prehistoric giant bird',
        ),
        DinosaurSpecies(
          id: 'epic_deinosuchus',
          name: 'Deinosuchus',
          emoji: '\u{1F40A}',
          rarity: DinosaurRarity.epic,
          description: 'Prehistoric super crocodile',
        ),
        DinosaurSpecies(
          id: 'epic_sarcosuchus',
          name: 'Sarcosuchus',
          emoji: '\u{1F40A}',
          rarity: DinosaurRarity.epic,
          description: 'SuperCroc of the Cretaceous',
        ),
        DinosaurSpecies(
          id: 'epic_titanoboa',
          name: 'Titanoboa',
          emoji: '\u{1F40D}',
          rarity: DinosaurRarity.epic,
          description: 'Massive serpent of legends',
        ),
      ];

  static List<DinosaurSpecies> get legendarySpecies => const [
        DinosaurSpecies(
          id: 'legendary_trex_king',
          name: 'T-Rex Monarch',
          emoji: '\u{1F451}',
          rarity: DinosaurRarity.legendary,
          description: 'The undisputed ruler of all dinosaurs',
        ),
        DinosaurSpecies(
          id: 'legendary_dracorex',
          name: 'Dracorex',
          emoji: '\u{1F409}',
          rarity: DinosaurRarity.legendary,
          description: 'Ancient dragon-dinosaur hybrid of myth',
        ),
        DinosaurSpecies(
          id: 'legendary_indominus',
          name: 'Indominus Rex',
          emoji: '\u{2620}\u{FE0F}',
          rarity: DinosaurRarity.legendary,
          description: 'Ultimate hybrid predator',
        ),
        DinosaurSpecies(
          id: 'legendary_ultrasaurus',
          name: 'Ultrasaurus',
          emoji: '\u{1F30B}',
          rarity: DinosaurRarity.legendary,
          description: 'The largest land creature to ever exist',
        ),
        DinosaurSpecies(
          id: 'legendary_phoenix_raptor',
          name: 'Phoenix Raptor',
          emoji: '\u{1F525}',
          rarity: DinosaurRarity.legendary,
          description: 'Reborn from ancient flames',
        ),
        DinosaurSpecies(
          id: 'legendary_leviathan',
          name: 'Leviathan',
          emoji: '\u{1F30A}',
          rarity: DinosaurRarity.legendary,
          description: 'Ancient sea monster of the deep',
        ),
        DinosaurSpecies(
          id: 'legendary_omega_spino',
          name: 'Omega Spinosaurus',
          emoji: '\u{26A1}',
          rarity: DinosaurRarity.legendary,
          description: 'Perfect evolution of the sail-back',
        ),
        DinosaurSpecies(
          id: 'legendary_crystal_trike',
          name: 'Crystal Triceratops',
          emoji: '\u{1F48E}',
          rarity: DinosaurRarity.legendary,
          description: 'Armored with ancient crystals',
        ),
        DinosaurSpecies(
          id: 'legendary_void_rex',
          name: 'Void Rex',
          emoji: '\u{1F31F}',
          rarity: DinosaurRarity.legendary,
          description: 'Emerged from the space between time',
        ),
        DinosaurSpecies(
          id: 'legendary_alpha_raptor',
          name: 'Alpha Raptor',
          emoji: '\u{1F4A0}',
          rarity: DinosaurRarity.legendary,
          description: 'Leader of the pack, unmatched in speed',
        ),
      ];
}
