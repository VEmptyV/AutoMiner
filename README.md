# AutoMiner (VotV 0.9.0n)

Мод для автоматизации и улучшения майнинг-ферм в **Voices of the Void (0.9.0n)**.

A mod for automating and upgrading crypto mining rigs in **Voices of the Void (0.9.0n)**.

## Русский 
The same thing is below, only in English.
## Возможности
- **Снятие лимита 512 поинтов** (`maxPoints = 999999`) и полная защита от перегрева и взрыва стоек (`overheat = 0.0`).
- **Автосбор поинтов** на баланс игрока с мгновенным обновлением HUD.
- **Отключение расхода электричества** от майнинг-ферм (настраивается).
- **Множитель скорости майнинга** (настраивается).
- **Игровые уведомления** при каждом сборе поинтов с отображением суммы и текущего баланса.
- **Настройка на лету через ModMenu** (файл `AutoMiner.ini` во вкладке `Files`).

## Параметры конфига (`shimloader/cfg/AutoMiner.ini`)
- `CollectThreshold` — порог поинтов для автосбора (по умолчанию `10`).
- `CheckIntervalMs` — интервал проверки в миллисекундах (по умолчанию `2000`).
- `DisablePowerUsage` — отключение расхода энергии стойками (`true` / `false`).
- `MiningSpeedMultiplier` — множитель скорости работы ферм (`1.0` = стандартная скорость).
- `ShowNotifications` — показ экранных уведомлений при сборе (`true` / `false`).

## English

## Features
- **Removes the 512-point cap** (`maxPoints = 999999`) and prevents rigs from overheating or exploding (`overheat = 0.0`).
- **Automatic point collection** directly to the player's balance with instant HUD updates.
- **Zero power consumption** option for mining rigs (configurable).
- **Adjustable mining speed multiplier** (configurable).
- **In-game notifications** showing collected points and the updated balance on each collection cycle.
- **Live configuration via ModMenu** (`AutoMiner.ini` under the `Files` tab).

## Configuration (`shimloader/cfg/AutoMiner.ini`)
- `CollectThreshold` — Point threshold required to trigger auto-collection (default: `10`).
- `CheckIntervalMs` — Update check interval in milliseconds (default: `2000`).
- `DisablePowerUsage` — Disables power drain from mining rigs (`true` / `false`).
- `MiningSpeedMultiplier` — Multiplier for mining rig generation speed (`1.0` = vanilla speed).
- `ShowNotifications` — Toggles on-screen notifications upon collecting points (`true` / `false`).
